#!/usr/bin/env bash
# Cuts a release of the mobile app:
#
#   ./release-app.sh patch | minor | major | X.Y.Z
#
# It bumps the version in flutter_app/pubspec.yaml (the only place it is
# written; the build number is computed by the Makefile from the commit
# count), dates the "Unreleased" section of flutter_app/CHANGELOG.md, commits
# "Release app-vX.Y.Z", creates the annotated tag app-vX.Y.Z and pushes the
# commit and the tag together. The tag push starts the "Release (app)"
# workflow, which checks the tag again, runs the analyzer and the tests and
# publishes the GitHub Release. The store builds are then made from the tag
# (make prod-ios, make prod-android): signing stays on this machine.
#
# Every check runs before anything is written: master checked out, clean and
# identical to origin/master, a version not lower than the current one and
# not tagged yet, release notes under "Unreleased", the store notes of the
# version in flutter_app/docs/changelogs/ (four locales, 500 characters
# each at most), analyzer and tests passing.
#
# The backend has its own version and script (./release-backend.sh); this one
# never touches it.
set -euo pipefail

cd "$(dirname "$0")"

branch="master"
version_file="flutter_app/pubspec.yaml"
changelog="flutter_app/CHANGELOG.md"
prefix="app-v"

fail() {
  echo "release-app: $*" >&2
  exit 1
}

# The confirmation below reads from the terminal: without one (a CI runner,
# an editor's task runner, Claude Code's `!` prefix) `read` hits EOF and the
# script would stop silently.
[ -t 0 ] || fail "needs an interactive terminal: run it from a shell"

read_version() {
  sed -nE 's/^version: ([0-9]+\.[0-9]+\.[0-9]+)$/\1/p' "$version_file"
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

[ $# -eq 1 ] || fail "usage: ./release-app.sh patch|minor|major|X.Y.Z"

command -v flutter >/dev/null 2>&1 || fail "flutter is missing"
command -v gh >/dev/null 2>&1 || fail "the GitHub CLI (gh) is missing: brew install gh"

current="$(read_version)"

[[ "$current" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || fail "cannot read the current version from $version_file (expected 'version: X.Y.Z' with no +N, got '$current')"

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

# What the stores show, one file per version with a block per locale
# (README, "Changelogs"). Pasted as-is, so each block must fit the Play
# Console limit of 500 characters.
store_notes="flutter_app/docs/changelogs/$next.md"

[ -f "$store_notes" ] || fail "$store_notes is missing: write the store notes of this version first (see README, \"Changelogs\")"

for locale in en-US fr-FR zh-Hans zh-Hant; do
  block="$(awk -v h="## $locale" '/^## / { inside = ($0 == h); next } inside' "$store_notes")"
  grep -q '^- ' <<<"$block" || fail "$store_notes has no bullets under \"## $locale\""
  length="$(printf '%s' "$block" | sed '/^[[:space:]]*$/d' | wc -m | tr -d ' ')"
  [ "$length" -le 500 ] || fail "$store_notes: the $locale block is $length characters, the Play Console takes 500 at most"
done

echo "Analyzer and tests…"
(cd flutter_app && flutter analyze && flutter test)

build_number="$(git rev-list --count HEAD)"

echo
echo "Release $tag (currently $current), from $(git rev-parse --short HEAD): $(git log -1 --format=%s)"
echo "Store builds from this tag will carry build number $((build_number + 1)) (the release commit)."
echo
sed 's/^/  /' <<<"$notes" | cut -c1-160
echo
read -r -p "Tag and push $tag? [y/N] " answer

if [ "$answer" != "y" ]; then
  echo "Aborted, nothing changed."
  exit 1
fi

today="$(date +%Y-%m-%d)"

sed -E "s/^version: [0-9]+\.[0-9]+\.[0-9]+$/version: $next/" "$version_file" >"$version_file.tmp"
mv "$version_file.tmp" "$version_file"

awk -v heading="## [$next] - $today" '
  $0 == "## [Unreleased]" { print; print ""; print heading; next }
  { print }
' "$changelog" >"$changelog.tmp"
mv "$changelog.tmp" "$changelog"

[ "$(read_version)" = "$next" ] || fail "$version_file was not updated to $next"

git commit -q -m "Release $tag" -- "$version_file" "$changelog"
git tag -a "$tag" -m "$tag"

if ! git push --atomic origin "$branch" "$tag"; then
  cat >&2 <<EOF

release-app: the push failed; the release commit and the tag $tag exist locally only.
  Retry:  git push --atomic origin $branch $tag
  Undo:   git tag -d $tag && git reset --hard HEAD~1
EOF
  exit 1
fi

repo="$(gh repo view --json nameWithOwner -q .nameWithOwner)"

echo
echo "Released $tag. The Release (app) workflow is running: https://github.com/$repo/actions"
echo "Store builds, from this tag: make prod-ios, make prod-android"
