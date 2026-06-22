#!/usr/bin/env bash
# Build the Flutter web app (which includes marketing pages from web/) and deploy to Cloudflare Pages.
#
# Usage:
#   scripts/deploy-site.sh                # full deploy
#   scripts/deploy-site.sh --local        # build only; preview with: cd build/web && python3 -m http.server 8000
#   scripts/deploy-site.sh --project-name NAME  # override Pages project name
set -euo pipefail

LOCAL=false
PROJECT_NAME="migraine-forecast"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --local) LOCAL=true; shift ;;
    --project-name) PROJECT_NAME="$2"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

echo "==> Building Flutter web"
flutter build web --release

if $LOCAL; then
  echo "==> Local build complete. Preview with: cd build/web && python3 -m http.server 8000"
  exit 0
fi

echo "==> Deploying build/web to Cloudflare Pages project '$PROJECT_NAME'"
wrangler pages deploy build/web --project-name="$PROJECT_NAME"

echo "==> Done."
