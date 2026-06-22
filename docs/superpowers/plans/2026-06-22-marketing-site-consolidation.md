# Marketing Site Consolidation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Eliminate `site/` and move all marketing static pages into `web/` so a single `flutter build web` + `wrangler pages deploy build/web` command deploys everything.

**Architecture:** Flutter's build copies everything in `web/` verbatim into `build/web/`, making static HTML subdirectories (home/, how-it-works/, etc.) available alongside the Flutter app at their natural URL paths. The Flutter shell stays at `/`; the marketing homepage moves to `/home/`. No post-build assembly step is needed.

**Tech Stack:** Flutter web, Cloudflare Pages (`_headers`), Wrangler CLI, bash

## Global Constraints

- Flutter app lives at `/` — do not set `--base-href` in the build command
- Marketing homepage must be at `/home/` (not `/`)
- All marketing page logo links (`<a class="brand" href="...">`) must point to `/home/`
- `site/` directory must be fully deleted by end of plan
- Cloudflare Pages project name: `migraine-forecast`
- `scripts/deploy-site.sh` must still support `--local` and `--project-name` flags

---

### Task 1: Move marketing content into `web/`

**Files:**
- Create: `web/_headers`
- Create: `web/styles.css` (copy from `site/public/styles.css`)
- Create: `web/theme.js` (copy from `site/public/theme.js`)
- Create: `web/favicon.svg` (copy from `site/public/favicon.svg`)
- Create: `web/home/index.html` (from `site/public/index.html`, link updated)
- Create: `web/how-it-works/index.html` (from `site/public/how-it-works/index.html`, link updated)
- Create: `web/faq/index.html` (from `site/public/faq/index.html`, link updated)
- Create: `web/privacy/index.html` (from `site/public/privacy/index.html`, link updated)
- Create: `web/terms/index.html` (from `site/public/terms/index.html`, link updated)

**Interfaces:**
- Produces: all marketing pages available in `build/web/` after `flutter build web`

- [ ] **Step 1: Copy static assets**

```bash
cp site/public/styles.css web/styles.css
cp site/public/theme.js web/theme.js
cp site/public/favicon.svg web/favicon.svg
```

- [ ] **Step 2: Create `web/_headers`**

Write `web/_headers` with this exact content (replaces `site/_headers`; `/app/*` rule removed because Flutter artifacts now live at root):

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

- [ ] **Step 3: Copy and update marketing sub-pages**

Copy each marketing sub-page and change the logo link from `href="/"` to `href="/home/"`:

```bash
mkdir -p web/how-it-works web/faq web/privacy web/terms
```

For each of `how-it-works`, `faq`, `privacy`, `terms`:
1. Copy: `cp site/public/<name>/index.html web/<name>/index.html`
2. Edit `web/<name>/index.html` line 26 — change:
   ```html
   <a class="brand" href="/">Migraine Forecast</a>
   ```
   to:
   ```html
   <a class="brand" href="/home/">Migraine Forecast</a>
   ```

All four files have the brand link at line 26.

- [ ] **Step 4: Copy and update marketing homepage**

```bash
mkdir -p web/home
cp site/public/index.html web/home/index.html
```

Edit `web/home/index.html` line 26 — change:
```html
<a class="brand" href="/">Migraine Forecast</a>
```
to:
```html
<a class="brand" href="/home/">Migraine Forecast</a>
```

- [ ] **Step 5: Verify brand links**

```bash
grep -rn 'class="brand"' web/home web/how-it-works web/faq web/privacy web/terms
```

Expected output — all five files showing `/home/`:
```
web/faq/index.html:26:      <a class="brand" href="/home/">Migraine Forecast</a>
web/home/index.html:26:      <a class="brand" href="/home/">Migraine Forecast</a>
web/how-it-works/index.html:26:      <a class="brand" href="/home/">Migraine Forecast</a>
web/privacy/index.html:26:      <a class="brand" href="/home/">Migraine Forecast</a>
web/terms/index.html:26:      <a class="brand" href="/home/">Migraine Forecast</a>
```

- [ ] **Step 6: Commit**

```bash
git add web/_headers web/styles.css web/theme.js web/favicon.svg \
        web/home/ web/how-it-works/ web/faq/ web/privacy/ web/terms/
git commit -m "feat: move marketing pages into web/"
```

---

### Task 2: Rewrite deploy script

**Files:**
- Modify: `scripts/deploy-site.sh`

**Interfaces:**
- Consumes: `flutter build web --release` → `build/web/`
- Produces: same CLI flags as before (`--local`, `--project-name`)

- [ ] **Step 1: Overwrite `scripts/deploy-site.sh`**

Replace the entire file with:

```bash
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
```

- [ ] **Step 2: Verify script is executable**

```bash
ls -l scripts/deploy-site.sh
```

Expected: `-rwxr-xr-x` (or similar with execute bit). If not:

```bash
chmod +x scripts/deploy-site.sh
```

- [ ] **Step 3: Commit**

```bash
git add scripts/deploy-site.sh
git commit -m "feat: simplify deploy script — build/web directly to Pages"
```

---

### Task 3: Verify local build, delete `site/`, final commit

**Files:**
- Delete: `site/` (entire directory)

- [ ] **Step 1: Run local build**

```bash
scripts/deploy-site.sh --local
```

Expected output ending with:
```
==> Local build complete. Preview with: cd build/web && python3 -m http.server 8000
```

If `flutter build web --release` fails, check that no `--base-href` flag remains in the script.

- [ ] **Step 2: Spot-check build output**

```bash
ls build/web/home/ build/web/how-it-works/ build/web/faq/ build/web/privacy/ build/web/terms/
ls build/web/styles.css build/web/theme.js build/web/favicon.svg build/web/_headers
```

All paths should exist. If any are missing, the corresponding file was not placed in `web/` correctly in Task 1.

- [ ] **Step 3: Preview locally**

```bash
cd build/web && python3 -m http.server 8000
```

Open in browser and verify:
- `http://localhost:8000/` — Flutter app loads (spinner or app UI)
- `http://localhost:8000/home/` — Marketing homepage renders with correct styles and "Migraine Forecast" logo linking to `/home/`
- `http://localhost:8000/how-it-works/` — page renders, logo links to `/home/`
- `http://localhost:8000/faq/` — page renders, logo links to `/home/`

`Ctrl+C` to stop the server when done. Return to repo root: `cd -`

- [ ] **Step 4: Delete `site/`**

```bash
git rm -r site/
```

Expected: git stages the deletion of `site/_headers`, `site/public/**`, `site/README.md`.

- [ ] **Step 5: Final commit**

```bash
git commit -m "chore: delete site/ — marketing pages now live in web/"
```
