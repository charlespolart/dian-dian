# VPS migration: legacy `/root/dian-dian/` → playbook layout `/srv/dian-dian/`

One-time migration. Run on the VPS, **not** locally. Estimated downtime: ~5 minutes.

The new deploy workflow (`.github/workflows/deploy.yml`):
- Builds a Docker image on the GH Actions runner and pushes to **GHCR**
- Ships compose files + Caddyfile to `/srv/dian-dian/ops/`
- Reads secrets from `/srv/dian-dian/.env`
- Mounts postgres data at `/srv/dian-dian/postgres/`
- No longer SSH-syncs the backend source (build happens in CI)

So we move postgres data + .env into the new layout, set up GHCR auth, then run the new deploy.

---

## 1. Pre-flight — back up the DB (locally to your laptop or to the VPS)

```bash
# On the VPS
docker compose -f /root/dian-dian/compose.yaml exec -T postgres \
  pg_dump -U postgres dian_dian > /root/diandian-pre-migration-$(date +%Y%m%d).sql
ls -lh /root/diandian-pre-migration-*.sql   # confirm size > a few KB
```

Keep this dump until the new deploy is up and verified.

---

## 2. GHCR pull credentials on the VPS

GH Actions builds and pushes to `ghcr.io/charlespolart/dian-dian-backend`. The VPS needs to be able to **pull** it.

### a. Create a classic PAT (NOT fine-grained — GHCR doesn't accept those)
1. https://github.com/settings/tokens → **Generate new token (classic)**
2. Name: `dian-dian-ghcr-pull`
3. Expiration: 1 year (forces rotation)
4. Scope: **only `read:packages`** — nothing else
5. Copy the token (`ghp_...`)

### b. Login on the VPS
```bash
echo '<paste-the-ghp_token>' | docker login ghcr.io -u charlespolart --password-stdin
```

Credential lands in `/root/.docker/config.json` (base64). With `read:packages` scope only, the blast radius if the VPS leaks is "can read your private images" — bounded.

### c. Set GitHub secrets (from your laptop, in the repo)
The workflow already uses `VPS_HOST`, `VPS_USER`, `VPS_SSH_KEY`. Verify they're set:
```bash
gh secret list
```
If missing:
```bash
gh secret set VPS_HOST   --body '<vps-ip-or-hostname>'
gh secret set VPS_USER   --body 'root'
gh secret set VPS_SSH_KEY < ~/.ssh/<deploy-key-private>
```
Note the `<` is a redirect (file contents), not a string arg.

---

## 3. Stop the legacy stack

```bash
cd /root/dian-dian
docker compose down       # stops caddy, backend, postgres
```

The postgres named volume `dian-dian_postgres_data` survives `down` (only `down -v` deletes volumes). Don't run that.

---

## 4. Create the new `/srv/dian-dian/` layout

```bash
mkdir -p /srv/dian-dian/{postgres,caddy/data,caddy/config,ops/scripts}

# Postgres in the playbook image runs as UID 999 (the postgres user in the
# alpine image). Chown so the container can write to the bind mount.
chown -R 999:999 /srv/dian-dian/postgres
chmod 700 /srv/dian-dian/postgres
```

---

## 5. Copy postgres data from the named volume to the bind mount

```bash
# Find the on-disk location of the legacy named volume.
src=$(docker volume inspect dian-dian_postgres_data --format '{{ .Mountpoint }}')
echo "Source: $src"
ls "$src" | head    # should show pgdata/ or PG_VERSION etc.

# Copy preserving owner, mtime, etc. The trailing /. copies contents,
# not the directory itself, into the bind mount.
cp -a "$src/." /srv/dian-dian/postgres/

# Re-chown after copy (cp -a preserves the original 999:999, but be safe).
chown -R 999:999 /srv/dian-dian/postgres
```

Verify:
```bash
ls /srv/dian-dian/postgres/   # expect pgdata/ (matches PGDATA in base compose)
```

If you don't see `pgdata/` — the legacy compose used the postgres default location (`/var/lib/postgresql/data` directly). In that case do:
```bash
mkdir -p /srv/dian-dian/postgres/pgdata
shopt -s dotglob
mv /srv/dian-dian/postgres/* /srv/dian-dian/postgres/pgdata/ 2>/dev/null || true
chown -R 999:999 /srv/dian-dian/postgres
```

---

## 6. Move `.env` and update `DATABASE_URL`

The legacy backend used `network_mode: host`, so its `DATABASE_URL` was
`postgres://...@localhost:5433/dian_dian`. The new backend runs on the docker
network and reaches postgres via the service name on the **default** port.

```bash
# Copy the current secrets into the new location.
cp /root/dian-dian/backend/.env /srv/dian-dian/.env
chmod 600 /srv/dian-dian/.env

# Rewrite DATABASE_URL.
sed -i 's|localhost:5433/dian_dian|postgres:5432/dian_dian|' /srv/dian-dian/.env

# Confirm.
grep DATABASE_URL /srv/dian-dian/.env
# expected: DATABASE_URL=postgres://postgres@postgres:5432/dian_dian
```

Sanity-check the file has every var the backend needs:
- `DATABASE_URL`
- `JWT_SECRET`
- `RESEND_API_KEY`
- `REVENUECAT_WEBHOOK_SECRET`
- `APPLE_BUNDLE_IDS`
- `GOOGLE_CLIENT_IDS`
- `APP_URL`
- `CORS_ORIGIN`

---

## 7. Migrate Caddy data (certs survive → no Let's Encrypt re-issuance)

```bash
caddy_data_src=$(docker volume inspect dian-dian_caddy_data --format '{{ .Mountpoint }}')
caddy_cfg_src=$(docker volume inspect dian-dian_caddy_config --format '{{ .Mountpoint }}')

cp -a "$caddy_data_src/." /srv/dian-dian/caddy/data/
cp -a "$caddy_cfg_src/." /srv/dian-dian/caddy/config/
```

---

## 8. Trigger the first deploy under the new layout

From your laptop:
```bash
./ops/scripts/deploy.sh   # or: gh workflow run deploy.yml
gh run watch              # tail the run
```

The workflow will:
- Build the image and push to GHCR with the HEAD short SHA as tag
- Rsync compose files + Caddyfile into `/srv/dian-dian/ops/`
- `docker compose pull backend` (uses the GHCR PAT login from step 2)
- `up -d --wait postgres` (waits for healthcheck)
- Run migrations with 3× retry
- `up -d --wait` everything else
- Validate + reload Caddy

---

## 9. Verify

```bash
# On the VPS
cd /srv/dian-dian
docker compose --env-file .env -f ops/docker-compose.yml -f ops/docker-compose.prod.yml ps

# All three should be `running (healthy)`:
#   dian-dian-postgres
#   dian-dian-backend
#   dian-dian-caddy

# Backend health
curl -sS http://localhost:3001/api/health   # if you can reach the docker net
# Or from your laptop:
curl -sS https://diandian.overridedev.com/api/health   # should return {"ok":true}

# Backend logs
docker compose --env-file .env -f ops/docker-compose.yml -f ops/docker-compose.prod.yml \
  logs --tail=50 backend
```

Verify the legacy domain too:
```bash
curl -sSI https://mydiandian.app/api/health | head -3
```

---

## 10. Clean up the legacy stack

Only after verifying everything works:

```bash
cd /root/dian-dian
docker compose down                          # already done in step 3, no-op now
docker volume rm dian-dian_postgres_data \
                 dian-dian_caddy_data \
                 dian-dian_caddy_config

cd /root && rm -rf /root/dian-dian
```

You can also drop the local pg_dump after a few days of healthy prod.

---

## Rollback if the new deploy goes wrong

If something is broken after step 8 and you need to revert:

```bash
# Stop the new stack
cd /srv/dian-dian
docker compose --env-file .env -f ops/docker-compose.yml -f ops/docker-compose.prod.yml down

# Restart the legacy one (data still in the original named volume)
cd /root/dian-dian
docker compose up -d
```

This works as long as you haven't deleted `/root/dian-dian` or the named volumes.

For rolling back to a previous GHCR tag (after migration is stable):
```bash
./ops/scripts/deploy.sh abc1234   # 7-char short SHA of an earlier commit
```
The image for that SHA must still exist on GHCR. Browse old tags:
https://github.com/charlespolart/dian-dian/pkgs/container/dian-dian-backend
