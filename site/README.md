# Marketing site

Hand-written HTML+CSS for migraine-forecast.com (or wherever it lands). Deploys to Cloudflare Pages.

## Preview locally

```
cd site/public && python3 -m http.server 8000
# open http://localhost:8000
```

The Flutter web build at `/app/` is populated only by the deploy script — locally that path 404s unless you've run `scripts/deploy-site.sh --local`.

## Deploy

```
./scripts/deploy-site.sh
```

Builds the Flutter web app with `--base-href /app/`, copies it into `site/public/app/`, then runs `wrangler pages deploy site/public`.

Requires: `wrangler login` once, and a Pages project named `migraine-forecast` (or pass `--project-name`).
