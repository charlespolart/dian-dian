#!/usr/bin/env bash
# Installs the latest released backend version on production:
#
#   ./ops/scripts/deploy-prod.sh
#   make deploy
#
# Production only ever runs versions cut by ./ops/scripts/release.sh. The
# script finds the newest tag backend-vX.Y.Z, refuses it unless its Release
# workflow succeeded (typecheck + smoke green, image backend-vX.Y.Z pushed)
# and production is not already on it, shows "vA → vB" and asks twice, the
# second time by having the version typed back.
#
# Then, over SSH:
#   1. syncs ops/ exactly as it is at the tag (compose files, pgBackRest
#      build context, host scripts; the Caddyfile through `cat >` so the
#      bind-mounted file keeps its inode),
#   2. pins the tag in /srv/dian-dian/.env (IMAGE_TAG), keeping the one that
#      was running in PREVIOUS_IMAGE_TAG for ./ops/scripts/rollback-prod.sh,
#   3. pulls the image, brings postgres up, runs the migrations (3 attempts),
#      brings the whole stack up, validates + reloads Caddy,
# and ends by checking that https://diandian.overridedev.com/api/health
# reports the new version.
#
# Needs the GitHub CLI logged in and SSH access as root to the VPS
# (DIAN_DIAN_PROD_HOST, default root@45.76.44.34).
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
  echo "deploy-prod: $*" >&2
  exit 1
}

command -v gh >/dev/null 2>&1 || fail "the GitHub CLI (gh) is missing: brew install gh"
command -v rsync >/dev/null 2>&1 || fail "rsync is missing"

repo="$(gh repo view --json nameWithOwner -q .nameWithOwner)"

git fetch -q --tags origin

tag="$(git tag -l "${prefix}*" | sort -V | tail -1)"

[ -n "$tag" ] || fail "no backend version tag yet: run ./ops/scripts/release.sh first"

# The tag's Release workflow is what typechecked, smoke-tested and built the image.
conclusion="$(gh api "repos/$repo/actions/workflows/release.yml/runs?event=push&per_page=50" \
  --jq "[.workflow_runs[] | select(.head_branch == \"$tag\")] | first | .conclusion // \"missing\"")"

[ "$conclusion" = "success" ] || fail "the Release workflow of $tag is '$conclusion', not 'success': https://github.com/$repo/actions"

gh release view "$tag" >/dev/null 2>&1 || fail "$tag has no GitHub Release yet: wait for the Release workflow"

current="$(ssh "$host" "grep '^$tag_key=' $stack/.env 2>/dev/null | cut -d= -f2- || true")"

[ "$current" = "none" ] && current=""
[ "$current" != "$tag" ] || fail "production is already on $tag, nothing to deploy"

ahead="$(git rev-list --count "$tag..origin/master")"

if [ "$ahead" -gt 0 ]; then
  echo "Note: $ahead commit(s) on master since $tag are not in any version and will not deploy."
fi

echo
echo "Production: ${current:-nothing yet (pre-release-script image)} → $tag"
echo
read -r -p "Continue? [y/N] " answer

if [ "$answer" != "y" ]; then
  echo "Aborted, nothing changed."
  exit 1
fi

read -r -p "Type $tag to confirm: " typed

[ "$typed" = "$tag" ] || fail "'$typed' is not $tag, nothing changed"

echo "Syncing ops/ as of ${tag}…"

# What reaches the VPS is the tag's ops/, never the working tree.
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
git archive "$tag" ops | tar -x -C "$tmp"

# No --delete: anything outside the repo on the VPS (postgres data dir, caddy
# volumes, .env files) must survive. -a keeps the exec bits of the scripts.
rsync -az \
  "$tmp/ops/docker-compose.yml" \
  "$tmp/ops/docker-compose.prod.yml" \
  "$tmp/ops/docker-compose.prod-backup.yml" \
  "$host:$stack/ops/"
rsync -az "$tmp/ops/pgbackrest" "$tmp/ops/scripts" "$host:$stack/ops/"

# The Caddy container holds the bind-mounted Caddyfile by inode; replacing the
# file (rsync would) leaves it serving the old config until a restart.
ssh "$host" "mkdir -p $stack/ops && cat > $stack/ops/Caddyfile" < "$tmp/ops/Caddyfile"

echo "Deploying ${tag}…"

# ssh joins its arguments into one command line that the remote shell splits
# again: quote them for it.
ssh "$host" bash -s -- "$(printf '%q ' "$stack" "$tag_key" "$previous_key" "$action_key" "$tag")" <<'REMOTE'
set -euo pipefail

stack=$1 tag_key=$2 previous_key=$3 action_key=$4 tag=$5

cd "$stack"
touch .env

set_key() {
  if grep -q "^$1=" .env; then
    sed -i "s|^$1=.*|$1=$2|" .env
  else
    echo "$1=$2" >> .env
  fi
}

current="$(grep "^$tag_key=" .env | cut -d= -f2- || true)"

if [ -n "$current" ] && [ "$current" != "none" ]; then
  set_key "$previous_key" "$current"
fi

set_key "$tag_key" "$tag"
set_key "$action_key" deploy

# The backup overlay is part of the STANDARD prod stack, not opt-in: leaving
# it out of any `up` would recreate postgres on the vanilla image and silently
# kill WAL archiving. All three files, always. Two env files: .env (injected
# into the backend via env_file, carries IMAGE_TAG) and .env.pgbackrest (root
# 0600, NOT injected anywhere) — so a backend RCE cannot read the backup repo
# passphrase or the R2 keys.
COMPOSE="docker compose --env-file $stack/.env --env-file $stack/.env.pgbackrest \
  -f ops/docker-compose.yml \
  -f ops/docker-compose.prod.yml \
  -f ops/docker-compose.prod-backup.yml"

$COMPOSE pull --quiet backend
# --build: postgres runs a locally-built image (base + pgbackrest client).
# Cached after the first deploy, rebuilt if the Dockerfile or conf changes.
$COMPOSE up -d --wait --build postgres

# Migrate with 3 attempts: pg_filenode.map races with concurrent DDL can fail
# the first attempt right after postgres starts. The old backend keeps
# serving until the `up` below, so a failed migration leaves production as
# it was (only .env already names the new tag).
for attempt in 1 2 3; do
  if $COMPOSE run --rm --no-deps -T backend npx drizzle-kit migrate </dev/null; then
    break
  fi
  if [ "$attempt" -eq 3 ]; then
    echo "migrate failed 3 times, aborting (backend still runs ${current:-the previous image})"
    exit 1
  fi
  sleep 5
done

$COMPOSE up -d --wait --build

# Reload Caddy in place — the Caddyfile may have changed.
$COMPOSE exec -T caddy caddy validate --config /etc/caddy/Caddyfile
$COMPOSE exec -T caddy caddy reload --config /etc/caddy/Caddyfile

docker image prune -f >/dev/null

echo "$(date -u +%FT%TZ) deploy $tag_key=$tag (was ${current:-none})" >> deploy.log
REMOTE

version="${tag#"$prefix"}"

echo "Waiting for production to report ${version}…"

for _ in $(seq 1 36); do
  if curl -fsS --max-time 5 "$health_url" 2>/dev/null | grep -q "\"version\":\"$version\""; then
    echo "Production runs $tag."
    exit 0
  fi

  sleep 5
done

cat >&2 <<EOF

Production did not report $version after 3 minutes ($health_url).
Look at the containers on the VPS:
  ssh $host 'cd $stack && docker compose ps && docker compose logs --tail 50 backend'
If the new version is broken, ./ops/scripts/rollback-prod.sh goes back to ${current:-the previous image}.
EOF
exit 1
