#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Render /etc/pgbackrest/pgbackrest.conf from env, then chain to the upstream
# postgres entrypoint so the DB boots normally.
# ---------------------------------------------------------------------------

set -euo pipefail

TEMPLATE=/etc/pgbackrest/pgbackrest.conf.template
CONF=/etc/pgbackrest/pgbackrest.conf

required_vars=(
  PGBACKREST_S3_BUCKET
  PGBACKREST_S3_ENDPOINT
  PGBACKREST_S3_REGION
  PGBACKREST_S3_KEY
  PGBACKREST_S3_KEY_SECRET
  PGBACKREST_REPO_CIPHER_PASS
)

# Skip if pgbackrest isn't configured (dev compose never sets these). NOTE:
# only safe because the prod-backup overlay — which turns archive_mode on — is
# never layered without these vars set. archive_mode=on with an unconfigured
# archive_command would pile up WAL until the disk fills.
if [[ -z "${PGBACKREST_S3_BUCKET:-}" ]]; then
  echo "pgbackrest: not configured, skipping archive setup."
  exec docker-entrypoint.sh "$@"
fi

for var in "${required_vars[@]}"; do
  if [[ -z "${!var:-}" ]]; then
    echo "FATAL: $var is unset (required in prod)." >&2
    exit 1
  fi
done

# /var/lib/pgbackrest and /var/log/pgbackrest are bind mounts from the host, so
# the image's mkdir/chown is masked at runtime — a fresh VPS gets root-owned
# dirs and archive_command (uid 70) fails with "Permission denied". Recreate
# and chown here, while we still are root.
if [[ "$(id -u)" == "0" ]]; then
  mkdir -p /var/lib/pgbackrest/lock /var/lib/pgbackrest/spool /var/log/pgbackrest
  chown -R postgres:postgres /var/lib/pgbackrest /var/log/pgbackrest
fi

cp "$TEMPLATE" "$CONF"
for var in "${required_vars[@]}"; do
  # `|` delimiter because S3 secrets may contain `/`.
  sed -i "s|{{$var}}|${!var}|g" "$CONF"
done
chmod 640 "$CONF"
# Only root can chown. Restores run this same entrypoint as `--user postgres`
# (so restored data files aren't owned by root); there the file is already
# postgres-owned and an unguarded chown would fail under `set -e`.
if [[ "$(id -u)" == "0" ]]; then
  chown postgres:postgres "$CONF"
fi

exec docker-entrypoint.sh "$@"
