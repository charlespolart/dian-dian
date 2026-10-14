#!/usr/bin/env bash
# Cuts a release of the backend:
#
#   ./ops/scripts/release.sh patch | minor | major | X.Y.Z
#   make release BUMP=minor
#
# It bumps the version in backend/package.json (and the lockfile, through
# `npm version`), dates the "Unreleased" section of backend/CHANGELOG.md,
# commits "Release backend-vX.Y.Z", creates the annotated tag backend-vX.Y.Z
# and pushes the commit and the tag together. The tag push starts the
# "Release (backend)" workflow, which checks the tag again, typechecks, runs
# the smoke suite against a throwaway Postgres, builds the image
# backend-vX.Y.Z and publishes the GitHub Release.
#
# NOTHING IS DEPLOYED BY THIS SCRIPT OR BY THE WORKFLOW: production changes
# only through ./ops/scripts/deploy-prod.sh, by hand.
#
# Every check runs before anything is written: master checked out, clean and
# identical to origin/master, a version not lower than the current one and
# not tagged yet, release notes under "Unreleased", typecheck passing.
#
# The mobile app has its own version (flutter_app/pubspec.yaml) and its own
# release path; this script never touches it.
set -euo pipefail

cd "$(dirname "$0")/../.."

branch="master"
version_file="backend/package.json"
changelog="backend/CHANGELOG.md"
prefix="backend-v"

fail() {
  echo "release: $*" >&2
  exit 1
}

read_version() {
  node -p "require('./$version_file').version"
}

# The lines of the changelog between "## [Unreleased]" and the next section.
unreleased_notes() {
  awk '/^## \[/ { inside = ($0 == "## [Unreleased]"); next } inside' "$changelog"
}

# True when version $1 is higher than version $2.
higher() {
  local a b i
  IFS=. read -r -a a <<<"$1"
  IFS=. read -r -a b <<<"$2"

  for i in 0 1 2; do
    if ((10#${a[i]} > 10#${b[i]})); then return 0; fi
    if ((10#${a[i]} < 10#${b[i]})); then return 1; fi
  done

  return 1
}

[ $# -eq 1 ] || fail "usage: ./ops/scripts/release.sh patch|minor|major|X.Y.Z"

command -v gh >/dev/null 2>&1 || fail "the GitHub CLI (gh) is missing: brew install gh"
command -v node >/dev/null 2>&1 || fail "node is missing"
[ -d backend/node_modules ] || fail "backend/node_modules is missing: run 'npm ci' in backend/ first"

current="$(read_version)"

[[ "$current" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || fail "cannot read the current version from $version_file (got '$current')"

IFS=. read -r major minor patch <<<"$current"

case "$1" in
  major) next="$((major + 1)).0.0" ;;
  minor) next="$major.$((minor + 1)).0" ;;
  patch) next="$major.$minor.$((patch + 1))" ;;
  *)
    [[ "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || fail "'$1' is neither patch, minor, major nor a version X.Y.Z"
    next="$1"
    ;;
esac

# An explicit version may equal the current one, for a version written before
# it was ever tagged; the tag check below refuses to release it twice.
if [ "$next" != "$current" ]; then
  higher "$next" "$current" || fail "$next is lower than the current version $current"
fi

tag="$prefix$next"

[ "$(git rev-parse --abbrev-ref HEAD)" = "$branch" ] || fail "releases are cut from $branch (on $(git rev-parse --abbrev-ref HEAD))"
[ -z "$(git status --porcelain)" ] || fail "the working tree is not clean: commit or stash first"

git fetch -q --tags origin "$branch"

[ "$(git rev-parse HEAD)" = "$(git rev-parse "origin/$branch")" ] || fail "$branch differs from origin/$branch: push or pull first"

if git rev-parse -q --verify "refs/tags/$tag" >/dev/null; then
  fail "the tag $tag already exists"
fi

grep -qx '## \[Unreleased\]' "$changelog" || fail "$changelog has no \"## [Unreleased]\" section"
notes="$(unreleased_notes)"

grep -q '^- ' <<<"$notes" || fail "nothing under \"Unreleased\" in $changelog: a release needs its notes"

echo "Typecheck…"
(cd backend && npx tsc --noEmit)

echo
echo "Release $tag (currently $current), from $(git rev-parse --short HEAD): $(git log -1 --format=%s)"
echo
sed 's/^/  /' <<<"$notes" | cut -c1-160
echo
read -r -p "Tag and push $tag? [y/N] " answer

if [ "$answer" != "y" ]; then
  echo "Aborted, nothing changed."
  exit 1
fi

today="$(date +%Y-%m-%d)"

# `npm version` keeps package.json and package-lock.json in step.
(cd backend && npm version --no-git-tag-version "$next" >/dev/null)

awk -v heading="## [$next] - $today" '
  $0 == "## [Unreleased]" { print; print ""; print heading; next }
  { print }
' "$changelog" >"$changelog.tmp"
mv "$changelog.tmp" "$changelog"

[ "$(read_version)" = "$next" ] || fail "$version_file was not updated to $next"

git commit -q -m "Release $tag" -- backend/package.json backend/package-lock.json "$changelog"
git tag -a "$tag" -m "$tag"

if ! git push --atomic origin "$branch" "$tag"; then
  cat >&2 <<EOF

release: the push failed; the release commit and the tag $tag exist locally only.
  Retry:  git push --atomic origin $branch $tag
  Undo:   git tag -d $tag && git reset --hard HEAD~1
EOF
  exit 1
fi

repo="$(gh repo view --json nameWithOwner -q .nameWithOwner)"

echo
echo "Released $tag. The Release workflow is running: https://github.com/$repo/actions"
echo "When it is green, deploy with: make deploy"
