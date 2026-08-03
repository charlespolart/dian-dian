# pgBackRest — dian-dian production backups

Automated Postgres backups to Cloudflare R2 (S3-compatible), encrypted at rest,
with point-in-time recovery via continuous WAL archiving.

- **Schedule** (`/etc/cron.d/dian-dian-backup`):
  - Daily full backup at 03:17 UTC
  - Hourly differential at HH:17
  - Weekly `pgbackrest check` on Sunday at 04:00 UTC
- **Retention**: 7 full backups, 30 differentials.
- **Encryption**: aes-256-cbc with a repo-wide passphrase.

## Environment variables

All six must be in `/srv/dian-dian/.env` before deploying the backup overlay:

| Var                            | Purpose                                                  |
| ------------------------------ | -------------------------------------------------------- |
| `PGBACKREST_S3_BUCKET`         | Bucket name, e.g. `dian-dian-backups`                    |
| `PGBACKREST_S3_ENDPOINT`       | `<account-id>.r2.cloudflarestorage.com` (no `https://`)  |
| `PGBACKREST_S3_REGION`         | `auto` for R2                                            |
| `PGBACKREST_S3_KEY`            | R2 access key ID (token scoped to this bucket only)      |
| `PGBACKREST_S3_KEY_SECRET`     | R2 secret access key                                     |
| `PGBACKREST_REPO_CIPHER_PASS`  | 32+ byte random. **Never rotate without recreating.**   |

Generate the cipher passphrase with `openssl rand -base64 48` and store it in a
password manager. If lost, existing backups are unrecoverable.

## Creating the R2 bucket + token (Cloudflare dashboard)

1. R2 → Create bucket → name it `dian-dian-backups`.
2. R2 → Manage R2 API Tokens → Create API token → **Object Read & Write**,
   scoped to **only** the `dian-dian-backups` bucket.
3. Note the **Access Key ID**, **Secret Access Key**, and your **account ID**
   (the endpoint is `<account-id>.r2.cloudflarestorage.com`).

## First-time setup

After the postgres container is running on the pgbackrest image (a deploy with
the prod-backup overlay + the env vars above):

```bash
ENV_FILE=/srv/dian-dian/.env /srv/dian-dian/ops/scripts/backup-init.sh
```

Creates the stanza, runs the initial full backup, verifies archive-push. The
host cron handles backups from there.

### ⚠️ Order matters: stanza BEFORE archiving (hit in prod, 2026-08-03)

Turning on `archive_mode` while the stanza does not yet exist in the repo puts
Postgres in a **crash loop**, not a degraded state:

```
server process (PID NNN) exited with exit code 103   # pgbackrest: no archive.info
terminating any other active server processes
all server processes terminated; reinitializing      # every ~11s
```

pgBackRest's async archiver is a child of the postmaster; when it exits 103
(stanza missing) Postgres reads that as a crashed backend and restarts the
whole cluster. That is a catch-22 — `stanza-create` needs a stable primary,
and the primary can't stabilise until the stanza exists.

Breaking out (what worked): start postgres with archiving off, create the
stanza, then re-enable archiving.

```bash
cd /srv/dian-dian
printf 'services:\n  postgres:\n    command: ["postgres"]\n' > /tmp/no-archive.yml
docker compose --env-file .env -f ops/docker-compose.yml -f ops/docker-compose.prod.yml \
  -f ops/docker-compose.prod-backup.yml -f /tmp/no-archive.yml up -d --wait postgres

docker exec dian-dian-postgres-1 pgbackrest --stanza=dian-dian stanza-create

rm /tmp/no-archive.yml
docker compose --env-file .env -f ops/docker-compose.yml -f ops/docker-compose.prod.yml \
  -f ops/docker-compose.prod-backup.yml up -d --wait postgres
```

The same applies to any **fresh cluster** (new VPS, restore drill on empty
storage) and to a repo that has been emptied — create the stanza first.

## Restore

Real disaster (DESTRUCTIVE — wipes live pgdata):

```bash
ENV_FILE=/srv/dian-dian/.env /srv/dian-dian/ops/scripts/restore.sh latest
```

### Non-destructive drill (safe to run on the live VPS)

Restores into a throwaway directory and boots a temporary postgres on it, so
row counts can be compared against prod without touching live data. Validated
2026-08-03.

```bash
rm -rf /srv/dian-dian/restore-drill && mkdir -p /srv/dian-dian/restore-drill
chown 70:70 /srv/dian-dian/restore-drill

docker run --rm --user postgres --env-file /srv/dian-dian/.env \
  -v /srv/dian-dian/restore-drill:/restore \
  dian-dian/postgres:16-pgbackrest \
  pgbackrest --stanza=dian-dian --pg1-path=/restore restore

# MUST mount at /restore and set PGDATA=/restore: the restore bakes
# --pg1-path=/restore into restore_command in postgresql.auto.conf. Mounting
# elsewhere makes archive-get fail ("unable to chdir to /restore") and recovery
# aborts with "could not locate required checkpoint record".
docker run -d --name restore-drill --user postgres --env-file /srv/dian-dian/.env \
  -e PGDATA=/restore -v /srv/dian-dian/restore-drill:/restore \
  dian-dian/postgres:16-pgbackrest

docker exec restore-drill psql -U postgres -d dian_dian \
  -tAc "SELECT 'users='||count(*) FROM users UNION ALL SELECT 'cells='||count(*) FROM cells;"

docker rm -f restore-drill && rm -rf /srv/dian-dian/restore-drill
```

Point-in-time (undo an accidental corruption at a known time):

```bash
ENV_FILE=/srv/dian-dian/.env /srv/dian-dian/ops/scripts/restore.sh \
  pitr "2026-08-01 14:30:00+00"
```

## Monitoring

```bash
docker compose -f ops/docker-compose.yml -f ops/docker-compose.prod.yml \
  -f ops/docker-compose.prod-backup.yml --env-file /srv/dian-dian/.env \
  exec -T postgres pgbackrest --stanza=dian-dian info
```

`info` prints the timeline; alert if the last full backup is older than ~28 h.

## References

- Upstream docs: https://pgbackrest.org
- R2 S3-compatible reference: https://developers.cloudflare.com/r2/api/s3/api/
