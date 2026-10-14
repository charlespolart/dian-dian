#!/usr/bin/env bash
# Puts production back on the backend version that ran before the last deploy:
#
#   ./ops/scripts/rollback-prod.sh
#   make rollback
#
# One step back, never two: the previous version is the one
# ./ops/scripts/deploy-prod.sh recorded in /srv/dian-dian/.env, and a second
# rollback in a row is refused until a version has been deployed again.
#
# A rollback reinstalls the code only; the database keeps the newer version's
# migrations, which is why a version must never remove or rename what the
# previous one needs (see backend/CHANGELOG.md). The script asks twice, the
# second time by having the version typed back, and ends by checking that the
# API reports it.
#
# Needs SSH access as root to the VPS (DIAN_DIAN_PROD_HOST, default
# root@45.76.44.34).
set -euo pipefail

cd "$(dirname "$0")/../.."

host="${DIAN_DIAN_PROD_HOST:-root@45.76.44.34}"
stack="/srv/dian-dian"
health_url="https://diandian.overridedev.com/api/health"
tag_key="IMAGE_TAG"
previous_key="PREVIOUS_IMAGE_TAG"
action_key="LAST_ACTION"
prefix="backend-v"

fail() {
  echo "rollback-prod: $*" >&2
  exit 1
}

state="$(ssh "$host" "cat $stack/.env 2>/dev/null || true")"

read_key() {
  grep "^$1=" <<<"$state" | cut -d= -f2- || true
}

current="$(read_key "$tag_key")"
previous="$(read_key "$previous_key")"
last_action="$(read_key "$action_key")"

[ -n "$current" ] && [ "$current" != "none" ] || fail "nothing is deployed on production through deploy-prod.sh yet"
[ -n "$previous" ] && [ "$previous" != "none" ] || fail "no previous version recorded: nothing to go back to"
[ "$last_action" != "rollback" ] || fail "production was already rolled back to $current; deploy a version before rolling back again"
[ "$previous" != "$current" ] || fail "the previous version is the current one ($current)"

echo
echo "Production: $current → back to $previous"
echo
read -r -p "Continue? [y/N] " answer

if [ "$answer" != "y" ]; then
  echo "Aborted, nothing changed."
  exit 1
fi

read -r -p "Type $previous to confirm: " typed

[ "$typed" = "$previous" ] || fail "'$typed' is not $previous, nothing changed"

echo "Rolling back to ${previous}…"

# ssh joins its arguments into one command line that the remote shell splits
# again: quote them for it.
ssh "$host" bash -s -- "$(printf '%q ' "$stack" "$tag_key" "$previous_key" "$action_key" "$previous" "$current")" <<'REMOTE'
set -euo pipefail

stack=$1 tag_key=$2 previous_key=$3 action_key=$4 target=$5 current=$6

cd "$stack"

set_key() {
  sed -i "s|^$1=.*|$1=$2|" .env
}

set_key "$tag_key" "$target"
set_key "$previous_key" "$current"
set_key "$action_key" rollback

# Same three compose files as a deploy (the backup overlay is part of the
# standard stack); only the backend is touched — no migrations, no Caddy.
COMPOSE="docker compose --env-file $stack/.env --env-file $stack/.env.pgbackrest \
  -f ops/docker-compose.yml \
  -f ops/docker-compose.prod.yml \
  -f ops/docker-compose.prod-backup.yml"

$COMPOSE pull --quiet backend
$COMPOSE up -d --wait backend

echo "$(date -u +%FT%TZ) rollback $tag_key=$target (was $current)" >> deploy.log
REMOTE

version="${previous#"$prefix"}"

echo "Waiting for production to report ${version}…"

for _ in $(seq 1 36); do
  if curl -fsS --max-time 5 "$health_url" 2>/dev/null | grep -q "\"version\":\"$version\""; then
    echo "Production runs $previous."
    exit 0
  fi

  sleep 5
done

cat >&2 <<EOF

Production did not report $version after 3 minutes ($health_url).
Look at the containers on the VPS:
  ssh $host 'cd $stack && docker compose ps && docker compose logs --tail 50 backend'
EOF
exit 1
