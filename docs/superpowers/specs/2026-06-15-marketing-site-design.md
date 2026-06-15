# Marketing site design

**Date:** 2026-06-15
**Status:** Draft for review

## Goal

A static credibility-and-trial site for Migraine Forecast, hosted on Cloudflare Pages alongside the Flutter web build. Promotes the web build as a real way to use the product (native apps aren't shipping yet) while serving as the canonical link target for OAuth screens, App Store metadata, GitHub, and the privacy policy.

Not a conversion-optimized funnel. Goal is "looks legitimate, explains the product, lets you try it."

## Scope

In scope:

- Four content pages: `/`, `/how-it-works`, `/privacy`, `/faq`
- The Flutter web build served at `/app/*` (same Cloudflare Pages project)
- Two themes — calm dark (default) and warm light — with a header toggle that respects `prefers-color-scheme` on first visit and `localStorage` after
- Hand-written HTML + CSS, no build step, no Node toolchain

Out of scope for v1:

- Blog, changelog, testimonials, screenshots gallery
- Analytics (add later if needed)
- A real custom domain (defer until brand/domain decided — Pages preview subdomain is fine for v1)
- Newsletter signup, contact form
- Sitemap / robots / OG images (cheap to add but not v1-blocking)

## Visual identity

**Two themes, both ship.** The user picks via header toggle; `prefers-color-scheme` is the default on first load.

**Theme C — calm dark (default):**
- Background `#14181f`, surfaces `#1a1f28`, borders `#232932`
- Body text `#e8ecf2`, secondary `#b6bdc8`, muted `#8b94a3`
- Accent `#a3e4cb` (soft mint), used sparingly — links, primary CTA, current-section highlight

**Theme B — warm light:**
- Background gradient `#fef3e7 → #fde4d3 → #f9c9b0` (top-left to bottom-right)
- Body text `#3d2817`, secondary `#7a5a45`
- Accent `#c2410c` (burnt orange) for links and primary CTA

**Typography:** system stack only. `-apple-system, BlinkMacSystemFont, "Segoe UI", system-ui, sans-serif`. No web fonts — keeps the page fast, no FOUT, no external requests on a privacy-positioning site.

**Type scale:**
- Hero h1: 48px desktop / 32px mobile, weight 700, line-height 1.15
- h2: 28px / 24px, weight 600
- h3: 18px, weight 600
- Body: 16px, line-height 1.55
- Small / footer: 13px

**Theme toggle behavior:**
1. On first paint, an inline `<script>` in `<head>` reads `localStorage.theme`; if absent, reads `matchMedia('(prefers-color-scheme: dark)')`; sets `data-theme="dark|light"` on `<html>` *before* the body renders. Prevents flash-of-wrong-theme.
2. A header button toggles the attribute and writes to `localStorage`.
3. All theme-dependent CSS uses `[data-theme="dark"]` and `[data-theme="light"]` selectors against shared layout rules.

## Site map

```
/                  Landing page — hero, what it does, triggers, how-it-works teaser, secondary CTA, footer
/how-it-works/     Long-form explainer — the evidence base, the 11 triggers in depth, the correlation engine
/privacy/          The existing docs/privacy-policy.md, rendered as HTML
/faq/              Common questions — what data is collected, how Oura integration works, native plans, open source
/app/              Flutter web build (index.html + assets) — separate Cloudflare Pages deployment context, see "Hosting"
```

Header nav is the same on all four content pages: brand link → `/`, then `How it works`, `FAQ`, `Privacy`, then the theme toggle.

## Page content

### `/` (homepage)

Six sections in order:

1. **Hero** — h1 "Know your migraine risk before it hits.", one-sentence tagline ("Daily forecasts from barometric pressure, sleep, HRV, and the triggers that matter to you."), three CTA buttons: **Try in browser →** (primary, links `/app/`), **iOS · coming soon** (disabled style), **Android · coming soon** (disabled style).
2. **What it does** — three short pillars in a grid: "Daily risk score" (0–100 with top drivers explained), "Learns from you" (logs sharpen the model — your triggers, not generic ones), "Local-first" (all data stays on device, no account required).
3. **Triggers tracked** — the 11 trigger module names as pills: Barometric pressure, Sleep, HRV, Hormones, Hydration, Alcohol, Stress, Caffeine, Meals, Light/screens, Activity. Visual proof of breadth.
4. **How it works (teaser)** — 2–3 sentences on the evidence base and correlation engine, with a "Read more →" link to `/how-it-works/`.
5. **Secondary CTA** — "Ready to try it?" + the same three buttons as the hero. So the reader doesn't have to scroll back up.
6. **Footer** — three columns: brand blurb + tagline; product links (How it works, FAQ, Try in browser); legal/social (Privacy, GitHub, Contact email).

No testimonials. No screenshots gallery in v1 (add later when native ships and we have App Store screenshots).

### `/how-it-works/`

Long-form, ~600–900 words. Sections:

- **The evidence base** — one paragraph on where the trigger list comes from (cite `docs/superpowers/specs/2026-06-14-migraine-forecast-evidence-design.md` and the references doc at a high level — no inline citations).
- **The 11 triggers** — each one a sub-heading with a paragraph: what it is, why it matters, what data the app uses to measure it. Group as: environmental (pressure, light), physiological (sleep, HRV, hormones, hydration), behavioral (alcohol, caffeine, meals, stress, activity).
- **Personalization** — how the correlation engine sharpens the model from logged headaches.
- **What it isn't** — explicit "not a medical device, not a diagnosis, see a doctor" paragraph.

### `/privacy/`

Render `docs/privacy-policy.md` as HTML. Two paths:

- **Manual:** copy the markdown content into a static HTML file, format the headings/lists. One-time cost; updates require re-rendering manually.
- **Build step (rejected for v1):** add a markdown→HTML converter. Adds a Node toolchain that we explicitly said we don't want.

Decision: **manual** for v1. If we update the privacy policy more than once a quarter we'll revisit.

### `/faq/`

Q&A list, ~10 questions. Starter set:

- What does Migraine Forecast actually do?
- What data does it collect? Where does it live?
- How does Oura Ring integration work? Is it required?
- Do I need an account?
- Is it a medical device / can I rely on it for treatment decisions?
- When will the iOS and Android apps be available?
- Is the code open source?
- Why does the web build need location / health permissions?
- Can I export my data?
- How do I get in touch?

Same dark/light theme, same nav.

## Hosting & deploy

Single Cloudflare Pages project. Repo layout:

```
site/
├── public/
│   ├── index.html              # landing
│   ├── how-it-works/index.html
│   ├── privacy/index.html
│   ├── faq/index.html
│   ├── styles.css              # shared, theme-aware
│   ├── theme.js                # toggle handler + first-paint inline duplicate
│   ├── favicon.svg
│   └── og-image.png            # optional, defer
├── _headers                    # cache rules, CSP if we want
├── _redirects                  # optional — e.g. /app → /app/
└── README.md                   # how to preview locally
```

The Flutter web build (`build/web/` after `flutter build web`) gets copied into `site/public/app/` as part of deploy. Two options for how:

- **A — manual copy step in a deploy script.** `scripts/deploy-site.sh` runs `flutter build web --base-href /app/`, copies `build/web/*` into `site/public/app/`, runs `wrangler pages deploy site/public`. One command, no Pages build pipeline. **Recommended for v1.**
- **B — Pages build pipeline.** Push to a branch, Pages runs `flutter build web && cp -r build/web site/public/app` server-side. Requires a Flutter Docker image and longer build times on Pages.

Decision: **A**. The Flutter build is heavy (Dart SDK, sqlite3.wasm); doing it locally and shipping prebuilt is cheaper and faster than re-installing the toolchain on every Pages build. The deploy script is one file.

**`--base-href /app/`** is critical — without it the Flutter web build assumes it's at `/` and asset URLs break.

**Cloudflare Pages config:**
- Output directory: `site/public`
- Build command: empty (we ship prebuilt)
- Production branch: TBD — pick when wiring up
- Preview URL: the auto-generated `*.pages.dev` subdomain is fine for v1
- Custom domain: not v1; revisit when domain is registered

## File-level rules

- One `styles.css` shared across all pages. Theme rules with `[data-theme="dark"]` / `[data-theme="light"]` selectors against layout rules.
- One `theme.js` for the toggle. The first-paint script (the one that sets `data-theme` before body renders) lives inline in each `<head>` — duplicated, but tiny, and the only way to avoid flash.
- All four content pages share the same `<header>`, `<footer>`, and `<meta>` block. We accept the duplication — no templating engine. If pages grow past ~6, revisit.
- No JavaScript framework. No bundler. Plain `<script defer>`.

## Accessibility

- Color contrast verified for both themes against WCAG AA on body text and primary CTA.
- Theme toggle: `<button>` with `aria-label="Switch to light theme" / "Switch to dark theme"`, updates dynamically.
- All CTAs are real `<a>` elements (not buttons) since they navigate.
- Hero h1 is unique per page; h2 for section headings; semantic `<nav>`, `<main>`, `<footer>`.
- `prefers-reduced-motion` respected — the warm theme's gradient stays static; no animations on the page anyway in v1.

## What we're explicitly not doing

- No analytics, tag manager, or third-party scripts.
- No web fonts.
- No newsletter, contact form, chat widget.
- No screenshots until native ships (the web build itself is the demo).
- No SEO meta beyond basic `<title>` + `<meta name="description">` — revisit when domain lands.
- No custom 404 — Pages default is fine for v1.

## Open follow-ups

- **Domain.** Site goes to `<slug>.pages.dev` for v1. Pick a domain when ready; Pages custom-domain wiring is ~5 minutes.
- **OG image / social cards.** Defer.
- **Sitemap / robots.txt.** Defer until domain decided.
- **Cookie / consent banner.** Not needed — no cookies, no analytics, no tracking.
- **Contact email.** Need a real address before publishing. Placeholder until decided.

## Implementation handoff

Next step: invoke `superpowers:writing-plans` to break this into an implementation plan. Execution will be dispatched to a sonnet subagent (per user request).
