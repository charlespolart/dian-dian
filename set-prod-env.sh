#!/usr/bin/env bash
# Set (or change) one variable in the production backend's env file and
# recreate the backend container so it picks it up. No image change, no
# migration, no downtime beyond the container restart (a few seconds).
#
#   ./set-prod-env.sh APPLE_CAMPAIGN_PT=128687410
#   ./set-prod-env.sh --yes APPLE_CAMPAIGN_PT=128687410   # no prompt (e.g. from `!` in Claude Code)
#
# What it does on the VPS (/srv/dian-dian):
#   1. copies .env to .env.bak-<timestamp>,
#   2. replaces the KEY=… line, or appends it,
#   3. `docker compose up -d --no-deps backend` with the same files as
#      ./deploy-prod.sh, then prints the value as the container sees it.
#
# Secrets: the value goes through the SSH command line only; it is not
# written anywhere on this machine.
set -euo pipefail

host="${DIAN_DIAN_PROD_HOST:-root@45.76.44.34}"
stack="/srv/dian-dian"

fail() { echo "set-prod-env: $*" >&2; exit 1; }

yes=0
if [ "${1:-}" = "--yes" ]; then yes=1; shift; fi
[ $# -eq 1 ] || fail "usage: $0 [--yes] KEY=VALUE"
[[ "$1" =~ ^([A-Z][A-Z0-9_]*)=(.*)$ ]] || fail "expected KEY=VALUE with an upper-case KEY, got '$1'"
key="${BASH_REMATCH[1]}"
value="${BASH_REMATCH[2]}"
[[ "$value" =~ ^[A-Za-z0-9_./:@+=,-]*$ ]] || fail "value has characters this script does not quote; set it by hand"

echo "production ($host): $key=$value"
if [ "$yes" = 1 ]; then
  echo "(--yes: no confirmation)"
else
  [ -t 0 ] || fail "needs an interactive terminal: run it from a shell, or pass --yes"
  read -r -p "Proceed? [y/N] " answer
  [ "$answer" = "y" ] || { echo "aborted"; exit 1; }
fi

ssh "$host" bash -s -- "$stack" "$key" "$value" <<'REMOTE'
set -euo pipefail
stack=$1 key=$2 value=$3
cd "$stack"
cp -p .env ".env.bak-$(date +%Y%m%d-%H%M%S)"
if grep -q "^${key}=" .env; then
  sed -i "s|^${key}=.*|${key}=${value}|" .env
else
  printf '\n%s=%s\n' "$key" "$value" >> .env
fi
docker compose --env-file "$stack/.env" --env-file "$stack/.env.pgbackrest" \
  -f ops/docker-compose.yml -f ops/docker-compose.prod.yml -f ops/docker-compose.prod-backup.yml \
  up -d --no-deps backend
sleep 3
echo "in the container: $(docker exec dian-dian-backend-1 sh -c "echo ${key}=\$${key}")"
docker ps --filter name=dian-dian-backend --format '{{.Names}} {{.Status}}'
REMOTE
