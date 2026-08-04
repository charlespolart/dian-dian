#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# One-shot bootstrap for pgBackRest on dian-dian.
#
# Run once after the postgres container is running on the pgbackrest image
# (i.e. after a deploy with the prod-backup overlay + PGBACKREST_* in .env):
#   1. Create the stanza in the R2 bucket (idempotent).
#   2. Perform the initial full backup.
#   3. Verify archive-push is working.
# ---------------------------------------------------------------------------

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
OPS_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="${ENV_FILE:-/srv/dian-dian/.env}"
# pgBackRest secrets live OUTSIDE .env: .env is injected whole into the
# backend container via env_file, so keeping the repo passphrase and R2 keys
# there would hand the backup repo to any backend RCE.
PGB_ENV_FILE="${PGB_ENV_FILE:-/srv/dian-dian/.env.pgbackrest}"
ENV_FILES=(--env-file "$ENV_FILE" --env-file "$PGB_ENV_FILE")
COMPOSE_FILES=(
  -f "$OPS_DIR/docker-compose.yml"
  -f "$OPS_DIR/docker-compose.prod.yml"
  -f "$OPS_DIR/docker-compose.prod-backup.yml"
)

if [[ ! -f "$ENV_FILE" ]]; then
  echo "FATAL: $ENV_FILE not found" >&2
  exit 1
fi

echo "==> Ensuring postgres is up on the pgbackrest image..."
# --wait blocks on the healthcheck. Without it, a container that was just
# recreated is still in crash recovery when stanza-create connects, and
# pgBackRest aborts with "unable to find primary cluster".
docker compose "${COMPOSE_FILES[@]}" "${ENV_FILES[@]}" up -d --wait --build postgres

echo "==> Creating stanza (idempotent)..."
docker compose "${COMPOSE_FILES[@]}" "${ENV_FILES[@]}" exec -T postgres \
  pgbackrest --stanza=dian-dian stanza-create

echo "==> Running initial full backup..."
docker compose "${COMPOSE_FILES[@]}" "${ENV_FILES[@]}" exec -T postgres \
  pgbackrest --stanza=dian-dian --type=full backup

echo "==> Verifying archive + backup integrity..."
docker compose "${COMPOSE_FILES[@]}" "${ENV_FILES[@]}" exec -T postgres \
  pgbackrest --stanza=dian-dian check

echo "OK pgBackRest initialised. The host cron (/etc/cron.d/dian-dian-backup)"
echo "   handles nightly full + hourly differential from here."
