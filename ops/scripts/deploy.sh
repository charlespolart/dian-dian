#!/usr/bin/env bash
# Trigger a production deploy via GitHub Actions.
#   ./ops/scripts/deploy.sh          → build + deploy HEAD
#   ./ops/scripts/deploy.sh abc1234  → roll back to an existing GHCR tag
set -euo pipefail

tag="${1:-latest}"

if ! command -v gh >/dev/null 2>&1; then
  echo "gh CLI missing — brew install gh" >&2
  exit 1
fi

echo "==> Trigger deploy (tag=$tag)..."
gh workflow run deploy.yml -f tag="$tag"
sleep 3
echo "==> Tailing run..."
gh run watch
