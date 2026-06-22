# Marketing Site Consolidation into Flutter Web Build

**Date:** 2026-06-22  
**Status:** Approved

## Goal

Eliminate the `site/` directory and consolidate all web-served content — both the Flutter app and the marketing static pages — under `web/`. Deploy by publishing `build/web/` directly to Cloudflare Pages, removing the multi-step assembly in `scripts/deploy-site.sh`.

## URL Structure

| Path | Content |
|------|---------|
| `/` | Flutter app (unchanged) |
| `/home/` | Marketing homepage (was `/`) |
| `/how-it-works/` | Marketing page (unchanged) |
| `/faq/` | Marketing page (unchanged) |
| `/privacy/` | Marketing page (unchanged) |
| `/terms/` | Marketing page (unchanged) |

Visitors to the bare domain land in the Flutter app. The marketing homepage moves to `/home/` and is linked from a "learn more" CTA on the Flutter onboarding screen (separate Flutter UI task, out of scope here).

## File Structure

`site/` is deleted. All marketing files move into `web/` alongside the existing Flutter web assets:

```
web/
  index.html            # Flutter shell — unchanged
  auth.html             # unchanged
  manifest.json         # unchanged
  drift_worker.js       # unchanged
  sqlite3.wasm          # unchanged
  favicon.png           # unchanged
  icons/                # unchanged
  _headers              # moved from site/_headers, rules updated (see below)
  favicon.svg           # moved from site/public/
  styles.css            # moved from site/public/
  theme.js              # moved from site/public/
  home/
    index.html          # was site/public/index.html
  how-it-works/
    index.html          # moved from site/public/
  faq/
    index.html          # moved from site/public/
  privacy/
    index.html          # moved from site/public/
  terms/
    index.html          # moved from site/public/
```

Flutter's build copies everything in `web/` verbatim into `build/web/` — the static marketing pages require no special build handling.

## `_headers` Changes

The `/app/*` cache rule (previously targeting the Flutter bundle path) is removed. Flutter's JS artifacts now live at the root of the deployment, so they are covered by the general `/*` security headers. Marketing static asset cache rules (`/styles.css`, `/theme.js`, `/favicon.svg`) are unchanged.

Updated `web/_headers`:

```
/styles.css
  Cache-Control: public, max-age=86400

/theme.js
  Cache-Control: public, max-age=86400

/favicon.svg
  Cache-Control: public, max-age=604800

/*
  Cache-Control: public, max-age=3600
  X-Content-Type-Options: nosniff
  Referrer-Policy: strict-origin-when-cross-origin
  Permissions-Policy: geolocation=(self), camera=(), microphone=(), payment=()
```

## Deploy Script

`scripts/deploy-site.sh` simplifies to:

```bash
#!/usr/bin/env bash
set -euo pipefail

PROJECT_NAME="migraine-forecast"
LOCAL=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --local) LOCAL=true; shift ;;
    --project-name) PROJECT_NAME="$2"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

flutter build web --release

if $LOCAL; then
  echo "Preview with: cd build/web && python3 -m http.server 8000"
  exit 0
fi

wrangler pages deploy build/web --project-name="$PROJECT_NAME"
```

No `--base-href /app/`, no `site/public/app/` assembly, no `rm -rf` / `cp -R`.

## What Is Not Changing

- Marketing page URLs `/how-it-works/`, `/faq/`, `/privacy/`, `/terms/` are identical
- Marketing asset references (`/styles.css`, `/favicon.svg`, etc.) already use root-relative paths and continue to work
- Cloudflare Pages project name stays `migraine-forecast`
- `web/index.html` (Flutter shell) is untouched

## Required Content Changes

All marketing pages (`home/`, `how-it-works/`, `faq/`, `privacy/`, `terms/`) currently use `href="/"` for their logo/nav home link. Since `/` is now the Flutter app, those links must be updated to `href="/home/"` during the move.

## Deploy Script

The script must `cd` to repo root before running `flutter build web`, so it works correctly regardless of where it is invoked from. The simplified script above includes this.

## Out of Scope

- Flutter onboarding "learn more" CTA implementation (separate Flutter UI task)
- SPA deep-link fallback (`_redirects`) — pre-existing gap, not introduced by this change
