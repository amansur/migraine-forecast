#!/usr/bin/env bash
# Build the Flutter web app, place it under site/public/app/, then deploy site/public to Cloudflare Pages.
#
# Usage:
#   scripts/deploy-site.sh                # full deploy
#   scripts/deploy-site.sh --local        # build only; skip wrangler (for local preview)
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

echo "==> Building Flutter web with --base-href /app/"
flutter build web --base-href /app/ --release

APP_OUT="site/public/app"
echo "==> Refreshing $APP_OUT"
rm -rf "$APP_OUT"
mkdir -p "$APP_OUT"
cp -R build/web/. "$APP_OUT/"

if $LOCAL; then
  echo "==> Local build complete. Preview with: cd site/public && python3 -m http.server 8000"
  exit 0
fi

echo "==> Deploying site/public to Cloudflare Pages project '$PROJECT_NAME'"
wrangler pages deploy site/public --project-name="$PROJECT_NAME"

echo "==> Done."
