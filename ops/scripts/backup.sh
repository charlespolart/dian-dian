#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# dian-dian production backup — pgBackRest to encrypted off-site R2.
#
# Cron entry point (see /etc/cron.d/dian-dian-backup):
#   ./ops/scripts/backup.sh            # differential (fast, hourly)
#   ./ops/scripts/backup.sh --full     # full (nightly)
#
# pgBackRest runs INSIDE the postgres container: it needs direct filesystem
# access to PGDATA, and that container carries the client + the rendered
# config. Scheduling from a host cron rather than a sidecar keeps
# /var/run/docker.sock out of every container.
#
# `set -euo pipefail`: without pipefail a pg-side failure would exit 0 through
# a pipeline and we'd report success with no backup.
# ---------------------------------------------------------------------------

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
OPS_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="${ENV_FILE:-/srv/dian-dian/.env}"
# The pgBackRest secrets live OUTSIDE .env on purpose: .env is injected whole
# into the backend container via env_file, so keeping the repo passphrase and
# R2 keys there would hand the backup repo to any backend RCE.
PGB_ENV_FILE="${PGB_ENV_FILE:-/srv/dian-dian/.env.pgbackrest}"
ENV_FILES=(--env-file "$ENV_FILE" --env-file "$PGB_ENV_FILE")
COMPOSE_FILES=(
  -f "$OPS_DIR/docker-compose.yml"
  -f "$OPS_DIR/docker-compose.prod.yml"
  -f "$OPS_DIR/docker-compose.prod-backup.yml"
)

TYPE="diff"
if [[ "${1:-}" == "--full" ]]; then
  TYPE="full"
fi

if [[ ! -f "$ENV_FILE" ]]; then
  echo "FATAL: $ENV_FILE not found" >&2
  exit 1
fi

echo "==> pgbackrest --type=$TYPE backup (stanza=dian-dian)"
docker compose "${COMPOSE_FILES[@]}" "${ENV_FILES[@]}" exec -T postgres \
  pgbackrest --stanza=dian-dian --type="$TYPE" backup

# `check` asserts WAL archiving still reaches the repo. A backup that succeeds
# while archive-push is silently broken is not point-in-time restorable, so we
# verify every run.
echo "==> pgbackrest check"
docker compose "${COMPOSE_FILES[@]}" "${ENV_FILES[@]}" exec -T postgres \
  pgbackrest --stanza=dian-dian check

echo "OK backup ($TYPE) $(date -Is)"
