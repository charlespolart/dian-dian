#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# pgBackRest restore procedure for dian-dian.
#
# Modes:
#   latest     — restore to the most recent good backup.
#   pitr TIME  — point-in-time restore to TIME (ISO 8601, e.g.
#                "2026-08-01 14:30:00+00").
#
# WARNING: restoring WIPES the live Postgres data directory. You lose
# everything after the target time. Run only where that is intended
# (recovery drill VM, disaster-recovery VPS).
#
# Usage:
#   ENV_FILE=/srv/dian-dian/.env ./ops/scripts/restore.sh latest
#   ENV_FILE=/srv/dian-dian/.env ./ops/scripts/restore.sh pitr "2026-08-01 14:30:00+00"
# ---------------------------------------------------------------------------

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
OPS_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="${ENV_FILE:-/srv/dian-dian/.env}"
COMPOSE_FILES=(
  -f "$OPS_DIR/docker-compose.yml"
  -f "$OPS_DIR/docker-compose.prod.yml"
  -f "$OPS_DIR/docker-compose.prod-backup.yml"
)

mode="${1:-}"
if [[ -z "$mode" ]]; then
  echo "Usage: $0 <latest|pitr TIME>" >&2
  exit 1
fi

echo "+---------------------------------------------+"
echo "|  DESTRUCTIVE operation — wipes live pgdata  |"
echo "+---------------------------------------------+"
read -r -p "Type 'YES-I-KNOW' to proceed: " confirm
if [[ "$confirm" != "YES-I-KNOW" ]]; then
  echo "Aborted."
  exit 2
fi

echo "==> Stopping postgres container..."
docker compose "${COMPOSE_FILES[@]}" --env-file "$ENV_FILE" stop postgres

echo "==> Wiping /srv/dian-dian/postgres (data directory)..."
sudo rm -rf /srv/dian-dian/postgres/*

# The restore runs in a one-off postgres container: pgBackRest writes the data
# files directly, so it must see the same /srv/dian-dian/postgres volume the
# live DB uses. `--user postgres` keeps restored files owned by the DB user
# (the image only drops privileges for the `postgres` command itself; an
# unqualified run would write them as root and postgres would refuse to start).
echo "==> Running pgbackrest restore (mode=$mode)..."
if [[ "$mode" == "latest" ]]; then
  docker compose "${COMPOSE_FILES[@]}" --env-file "$ENV_FILE" \
    run --rm --user postgres postgres \
    pgbackrest --stanza=dian-dian restore
elif [[ "$mode" == "pitr" ]]; then
  target="${2:?pitr mode requires a timestamp argument}"
  docker compose "${COMPOSE_FILES[@]}" --env-file "$ENV_FILE" \
    run --rm --user postgres postgres \
    pgbackrest --stanza=dian-dian --type=time --target="$target" \
    --target-action=promote restore
else
  echo "Unknown mode: $mode (expected 'latest' or 'pitr')" >&2
  exit 3
fi

echo "==> Starting postgres container..."
docker compose "${COMPOSE_FILES[@]}" --env-file "$ENV_FILE" start postgres

echo "OK Restore complete. Verify:"
echo "   docker compose ${COMPOSE_FILES[*]} --env-file $ENV_FILE exec -T postgres psql -U postgres -d dian_dian -c 'SELECT count(*) FROM users'"
