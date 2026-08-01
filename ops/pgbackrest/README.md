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

## Restore

Drill (recommended, on a throwaway VPS/VM), or real disaster:

```bash
ENV_FILE=/srv/dian-dian/.env /srv/dian-dian/ops/scripts/restore.sh latest
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
