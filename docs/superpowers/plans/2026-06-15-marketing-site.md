# Marketing Site Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship a four-page hand-written marketing site at `site/` plus the Flutter web build at `site/public/app/`, deployable to Cloudflare Pages with one script.

**Architecture:** Plain HTML+CSS, no build step. Shared `styles.css` and `theme.js` across four pages; theme state in `data-theme` on `<html>`, set inline pre-paint to avoid FOUC. Deploy via `scripts/deploy-site.sh` which runs `flutter build web --base-href /app/`, copies output into `site/public/app/`, then `wrangler pages deploy`.

**Tech Stack:** HTML, CSS, vanilla JS, Wrangler (Cloudflare CLI), Flutter (already in repo).

**Spec:** `docs/superpowers/specs/2026-06-15-marketing-site-design.md`

---

## File Structure

```
site/
├── public/
│   ├── index.html              # landing page
│   ├── how-it-works/index.html
│   ├── privacy/index.html
│   ├── faq/index.html
│   ├── styles.css              # shared, theme-aware
│   ├── theme.js                # toggle handler
│   ├── favicon.svg
│   └── app/                    # Flutter web build, populated by deploy script
├── _headers                    # cache headers
├── README.md                   # how to preview + deploy locally
scripts/
└── deploy-site.sh              # build flutter web + wrangler pages deploy
```

Each HTML page is self-contained — `<head>` includes the inline first-paint theme script (duplicated, ~15 lines), `<header>`/`<footer>` markup is duplicated (no templating).

---

## Task 1: Scaffold directory + shared CSS

**Files:**
- Create: `site/public/styles.css`
- Create: `site/README.md`

- [ ] **Step 1: Create `site/` directory structure**

```bash
mkdir -p site/public/how-it-works site/public/privacy site/public/faq
```

- [ ] **Step 2: Write `site/public/styles.css`**

```css
/* ============ Reset + base ============ */
*, *::before, *::after { box-sizing: border-box; }
html { font-size: 16px; }
body {
  margin: 0;
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", system-ui, sans-serif;
  font-size: 1rem;
  line-height: 1.55;
  min-height: 100vh;
  transition: background 0.25s, color 0.25s;
}
a { color: inherit; }
img { max-width: 100%; height: auto; display: block; }

/* ============ Theme: dark (default) ============ */
[data-theme="dark"] body {
  background: #14181f;
  color: #e8ecf2;
}
[data-theme="dark"] .surface { background: #1a1f28; border-color: #232932; }
[data-theme="dark"] .muted   { color: #b6bdc8; }
[data-theme="dark"] .dim     { color: #8b94a3; }
[data-theme="dark"] .accent  { color: #a3e4cb; }
[data-theme="dark"] .cta-primary {
  background: #a3e4cb; color: #14181f; border-color: #a3e4cb;
}
[data-theme="dark"] .cta-secondary {
  background: transparent; color: #e8ecf2; border-color: #2d3540;
}
[data-theme="dark"] .cta-disabled {
  background: transparent; color: #8b94a3; border-color: #2d3540; cursor: not-allowed;
}
[data-theme="dark"] hr { border: 0; border-top: 1px solid #1d232c; }
[data-theme="dark"] a:hover { color: #a3e4cb; }

/* ============ Theme: light (warm) ============ */
[data-theme="light"] body {
  background: linear-gradient(135deg, #fef3e7 0%, #fde4d3 60%, #f9c9b0 100%);
  background-attachment: fixed;
  color: #3d2817;
}
[data-theme="light"] .surface { background: rgba(255,255,255,0.55); border-color: rgba(61,40,23,0.12); }
[data-theme="light"] .muted   { color: #7a5a45; }
[data-theme="light"] .dim     { color: #9a7a65; }
[data-theme="light"] .accent  { color: #c2410c; }
[data-theme="light"] .cta-primary {
  background: #c2410c; color: white; border-color: #c2410c;
}
[data-theme="light"] .cta-secondary {
  background: rgba(255,255,255,0.7); color: #3d2817; border-color: rgba(61,40,23,0.18);
}
[data-theme="light"] .cta-disabled {
  background: transparent; color: #9a7a65; border-color: rgba(61,40,23,0.18); cursor: not-allowed;
}
[data-theme="light"] hr { border: 0; border-top: 1px solid rgba(61,40,23,0.12); }
[data-theme="light"] a:hover { color: #c2410c; }

/* ============ Layout ============ */
.wrap { max-width: 880px; margin: 0 auto; padding: 0 24px; }
header.site-header {
  display: flex; justify-content: space-between; align-items: center;
  padding: 20px 0;
}
header.site-header .brand { font-weight: 700; font-size: 1.05rem; text-decoration: none; }
header.site-header nav { display: flex; gap: 22px; align-items: center; font-size: 0.9rem; }
header.site-header nav a { text-decoration: none; }
button.theme-toggle {
  background: transparent; border: 1px solid currentColor; opacity: 0.55;
  width: 32px; height: 32px; border-radius: 50%; cursor: pointer;
  display: inline-flex; align-items: center; justify-content: center;
  color: inherit; font-size: 14px; padding: 0;
}
button.theme-toggle:hover { opacity: 1; }

main { padding: 32px 0 80px; }
section.block { padding: 32px 0; }
section.block + section.block { border-top: 1px solid; border-color: inherit; }

/* ============ Typography ============ */
h1.hero { font-size: 3rem; line-height: 1.1; margin: 0 0 16px; font-weight: 700; letter-spacing: -0.02em; }
h2 { font-size: 1.75rem; line-height: 1.2; margin: 0 0 14px; font-weight: 600; }
h3 { font-size: 1.125rem; margin: 0 0 8px; font-weight: 600; }
p  { margin: 0 0 14px; }
p.lead { font-size: 1.15rem; }
.label { font-size: 0.72rem; letter-spacing: 0.08em; text-transform: uppercase; font-weight: 600; }

@media (max-width: 640px) {
  h1.hero { font-size: 2rem; }
  h2 { font-size: 1.5rem; }
  .wrap { padding: 0 18px; }
}

/* ============ CTAs ============ */
.ctas { display: flex; flex-wrap: wrap; gap: 10px; margin-top: 20px; }
.cta {
  display: inline-block; padding: 11px 18px; border-radius: 8px;
  font-weight: 600; font-size: 0.95rem; text-decoration: none;
  border: 1px solid transparent; transition: transform 0.1s;
}
.cta:hover { transform: translateY(-1px); }
.cta-disabled:hover { transform: none; }

/* ============ Feature grid ============ */
.feature-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 16px; margin-top: 18px; }
.feature { padding: 18px; border-radius: 10px; border: 1px solid; }
.feature h3 { margin-bottom: 6px; }
.feature p  { margin: 0; font-size: 0.92rem; }
@media (max-width: 720px) {
  .feature-grid { grid-template-columns: 1fr; }
}

/* ============ Trigger pills ============ */
.pills { display: flex; flex-wrap: wrap; gap: 8px; margin-top: 16px; }
.pill {
  padding: 6px 13px; border-radius: 999px; font-size: 0.85rem;
  border: 1px solid; background: inherit;
}

/* ============ Footer ============ */
footer.site-footer {
  padding: 40px 0 32px; border-top: 1px solid;
  font-size: 0.88rem;
}
footer.site-footer .cols {
  display: grid; grid-template-columns: 2fr 1fr 1fr; gap: 36px;
}
footer.site-footer .cols strong { display: block; margin-bottom: 8px; font-size: 0.92rem; }
footer.site-footer a { display: block; text-decoration: none; padding: 2px 0; }
footer.site-footer a:hover { text-decoration: underline; }
@media (max-width: 720px) {
  footer.site-footer .cols { grid-template-columns: 1fr; gap: 24px; }
}

/* ============ Prose (for /privacy, /how-it-works, /faq long text) ============ */
.prose h2 { margin-top: 36px; }
.prose h3 { margin-top: 22px; }
.prose ul, .prose ol { padding-left: 22px; }
.prose li { margin-bottom: 6px; }
.prose code { font-family: ui-monospace, SFMono-Regular, Menlo, monospace; font-size: 0.92em; padding: 1px 5px; border-radius: 4px; }
[data-theme="dark"] .prose code { background: #1a1f28; }
[data-theme="light"] .prose code { background: rgba(61,40,23,0.08); }

/* ============ FAQ ============ */
details.faq-item {
  padding: 16px 18px; border: 1px solid; border-radius: 10px; margin-bottom: 10px;
}
details.faq-item summary {
  cursor: pointer; font-weight: 600; font-size: 1rem; list-style: none;
}
details.faq-item summary::-webkit-details-marker { display: none; }
details.faq-item[open] { padding-bottom: 20px; }
details.faq-item summary::after { content: " +"; opacity: 0.5; }
details.faq-item[open] summary::after { content: " –"; }
details.faq-item p { margin-top: 12px; margin-bottom: 0; }

/* ============ Reduced motion ============ */
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after { transition: none !important; animation: none !important; }
}
```

- [ ] **Step 3: Write `site/README.md`**

```markdown
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
```

- [ ] **Step 4: Commit**

```bash
git add site/
git commit -m "chore(site): scaffold marketing site directory + shared styles"
```

---

## Task 2: Theme toggle script

**Files:**
- Create: `site/public/theme.js`

- [ ] **Step 1: Write `site/public/theme.js`**

```js
// Wires up the header theme toggle button.
// The first-paint <script> in each <head> is inlined separately so it runs
// before <body> renders and prevents flash-of-wrong-theme.
(function () {
  const button = document.querySelector('button.theme-toggle');
  if (!button) return;

  function currentTheme() {
    return document.documentElement.getAttribute('data-theme') || 'dark';
  }

  function syncLabel() {
    const t = currentTheme();
    const next = t === 'dark' ? 'light' : 'dark';
    button.setAttribute('aria-label', `Switch to ${next} theme`);
    button.textContent = t === 'dark' ? '☀' : '☾';
  }

  button.addEventListener('click', () => {
    const next = currentTheme() === 'dark' ? 'light' : 'dark';
    document.documentElement.setAttribute('data-theme', next);
    try { localStorage.setItem('theme', next); } catch (_) {}
    syncLabel();
  });

  syncLabel();
})();
```

- [ ] **Step 2: Commit**

```bash
git add site/public/theme.js
git commit -m "feat(site): add theme toggle script"
```

---

## Task 3: Reusable head/header/footer snippets — `/` landing page

**Files:**
- Create: `site/public/index.html`

This task also establishes the boilerplate (head meta, inline first-paint script, header, footer) that Tasks 4-6 will duplicate verbatim.

- [ ] **Step 1: Write `site/public/index.html`**

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Migraine Forecast — daily risk from evidence-backed triggers</title>
  <meta name="description" content="Daily migraine risk forecasts from barometric pressure, sleep, HRV, and the triggers that matter to you. Local-first. No account.">
  <link rel="icon" type="image/svg+xml" href="/favicon.svg">
  <link rel="stylesheet" href="/styles.css">
  <script>
    // Inline, runs pre-paint to avoid flash-of-wrong-theme.
    (function () {
      try {
        var stored = localStorage.getItem('theme');
        var preferred = stored || (window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light');
        document.documentElement.setAttribute('data-theme', preferred);
      } catch (e) {
        document.documentElement.setAttribute('data-theme', 'dark');
      }
    })();
  </script>
</head>
<body>
  <div class="wrap">
    <header class="site-header">
      <a class="brand" href="/">Migraine Forecast</a>
      <nav>
        <a href="/how-it-works/">How it works</a>
        <a href="/faq/">FAQ</a>
        <a href="/privacy/">Privacy</a>
        <button class="theme-toggle" type="button" aria-label="Switch theme">☾</button>
      </nav>
    </header>

    <main>
      <section class="block">
        <h1 class="hero">Know your <span class="accent">migraine risk</span> before it hits.</h1>
        <p class="lead muted">Daily forecasts from barometric pressure, sleep, HRV, and the triggers that matter to you.</p>
        <div class="ctas">
          <a class="cta cta-primary" href="/app/">Try in browser →</a>
          <span class="cta cta-disabled" aria-disabled="true">iOS · coming soon</span>
          <span class="cta cta-disabled" aria-disabled="true">Android · coming soon</span>
        </div>
      </section>

      <section class="block">
        <span class="label accent">What it does</span>
        <h2>Three things, in plain English.</h2>
        <div class="feature-grid">
          <div class="feature surface">
            <h3>Daily risk score</h3>
            <p class="muted">A 0–100 score with the top drivers explained — no black box.</p>
          </div>
          <div class="feature surface">
            <h3>Learns from you</h3>
            <p class="muted">Logging headaches sharpens the model around <em>your</em> triggers, not generic ones.</p>
          </div>
          <div class="feature surface">
            <h3>Local-first</h3>
            <p class="muted">All data stays on the device. No account required.</p>
          </div>
        </div>
      </section>

      <section class="block">
        <span class="label accent">Triggers tracked</span>
        <h2>Eleven evidence-backed factors.</h2>
        <p class="muted">The score blends environmental, physiological, and behavioral signals.</p>
        <div class="pills">
          <span class="pill surface">Barometric pressure</span>
          <span class="pill surface">Sleep</span>
          <span class="pill surface">HRV</span>
          <span class="pill surface">Hormones</span>
          <span class="pill surface">Hydration</span>
          <span class="pill surface">Alcohol</span>
          <span class="pill surface">Stress</span>
          <span class="pill surface">Caffeine</span>
          <span class="pill surface">Meals</span>
          <span class="pill surface">Light / screens</span>
          <span class="pill surface">Activity</span>
        </div>
      </section>

      <section class="block">
        <span class="label accent">How it works</span>
        <h2>Evidence in, personalization out.</h2>
        <p class="muted">Each trigger module is built from peer-reviewed evidence and contributes to the daily score with a confidence weight. As you log headaches, a correlation engine learns which triggers fire for <em>you</em> and reweights accordingly.</p>
        <p><a class="accent" href="/how-it-works/">Read the full explainer →</a></p>
      </section>

      <section class="block">
        <h2>Ready to try it?</h2>
        <div class="ctas">
          <a class="cta cta-primary" href="/app/">Try in browser →</a>
          <span class="cta cta-disabled" aria-disabled="true">iOS · coming soon</span>
          <span class="cta cta-disabled" aria-disabled="true">Android · coming soon</span>
        </div>
      </section>
    </main>

    <footer class="site-footer surface">
      <div class="cols">
        <div>
          <strong>Migraine Forecast</strong>
          <p class="dim">Daily risk forecasts from evidence-backed triggers. Local-first. Open source.</p>
        </div>
        <div>
          <strong>Product</strong>
          <a href="/how-it-works/">How it works</a>
          <a href="/faq/">FAQ</a>
          <a href="/app/">Try in browser</a>
        </div>
        <div>
          <strong>Legal</strong>
          <a href="/privacy/">Privacy</a>
          <a href="https://github.com/" rel="noopener">GitHub</a>
          <a href="mailto:hello@example.com">Contact</a>
        </div>
      </div>
    </footer>
  </div>
  <script src="/theme.js" defer></script>
</body>
</html>
```

- [ ] **Step 2: Preview**

```bash
cd site/public && python3 -m http.server 8000
# open http://localhost:8000
```

Expected: hero renders in dark theme by default; clicking the ☾ button switches to warm light; nav links 404 (other pages not built yet — expected).

- [ ] **Step 3: Commit**

```bash
git add site/public/index.html
git commit -m "feat(site): landing page"
```

---

## Task 4: `/how-it-works/` page

**Files:**
- Create: `site/public/how-it-works/index.html`

- [ ] **Step 1: Write `site/public/how-it-works/index.html`**

Use the same `<head>` (including inline first-paint script), same header, same footer, same `<script src="/theme.js" defer>` as Task 3. Replace `<main>` with this:

```html
<main class="prose">
  <section class="block">
    <span class="label accent">How it works</span>
    <h1 class="hero">From evidence to your daily score.</h1>
    <p class="lead muted">Each trigger is a module built from the migraine-research literature. The score blends them with confidence weights, then sharpens around your personal patterns as you log.</p>
  </section>

  <section class="block">
    <h2>The evidence base</h2>
    <p>Eleven triggers, each backed by published research on migraine prevalence and prodromal physiology. We don't claim to predict the unknown — we surface signals that have shown reproducible association with headache onset across multiple studies.</p>
    <p>Each module contributes a 0–100 contribution and a confidence weight (how reliable the underlying data is for <em>you</em>). The daily score is a weighted blend; the UI shows the top drivers, never just a number.</p>
  </section>

  <section class="block">
    <h2>Environmental triggers</h2>
    <h3>Barometric pressure</h3>
    <p>Rapid changes in atmospheric pressure are one of the most-cited migraine triggers. The app pulls hourly pressure forecasts from Open-Meteo for your location and looks for the rate-of-change windows that have historically preceded headaches.</p>
    <h3>Light and screen exposure</h3>
    <p>Photophobia is a defining feature of migraine. The light module accepts logged screen-time or device sensor data when available and treats sustained bright exposure as an elevating signal.</p>

    <h2>Physiological triggers</h2>
    <h3>Sleep</h3>
    <p>Both deprivation and oversleep raise risk. The sleep module ingests total duration, sleep efficiency, and bedtime variability from Apple Health, Health Connect, or Oura Ring.</p>
    <h3>Heart rate variability (HRV)</h3>
    <p>Reduced HRV correlates with autonomic stress, a known prodromal signal. Pulled from the same health source as sleep.</p>
    <h3>Hormones</h3>
    <p>Cycle-related migraine has its own evidence base. The hormone module is optional and uses the on-device cycle tracker; nothing leaves the device.</p>
    <h3>Hydration</h3>
    <p>Logged water intake compared against personal baselines.</p>

    <h2>Behavioral triggers</h2>
    <h3>Alcohol</h3>
    <p>Quantity and time-since-last-drink. Even modest intake near a sensitive window matters.</p>
    <h3>Caffeine</h3>
    <p>Both intake spikes and withdrawal show up as triggers. Tracked from logs.</p>
    <h3>Meals</h3>
    <p>Time-since-last-meal as a proxy for blood sugar — skipped meals are a common trigger.</p>
    <h3>Stress</h3>
    <p>A subjective daily log (1–5) plus any HRV signal as a corroborating biometric.</p>
    <h3>Activity</h3>
    <p>Heavy exertion outside your normal pattern can precipitate; absolute sedentary stretches show up too.</p>
  </section>

  <section class="block">
    <h2>Personalization</h2>
    <p>Generic triggers are a starting point, not the model. Each time you log a headache, the correlation engine looks back at the trigger contributions in the 24–48 hours before onset and updates the per-trigger weights that drive <em>your</em> future scores. After ~10 logs, the score is meaningfully tuned; after ~30 it's stable.</p>
    <p>The model lives entirely on the device. No data leaves unless you explicitly export it.</p>
  </section>

  <section class="block">
    <h2>What it isn't</h2>
    <p class="muted">Migraine Forecast is not a medical device. It does not diagnose, treat, or replace clinical care. If your headaches are severe, frequent, or changing in character, see a doctor — the app's job is to help you spot patterns, not to substitute for evaluation.</p>
  </section>

  <section class="block">
    <h2>Ready to try it?</h2>
    <div class="ctas">
      <a class="cta cta-primary" href="/app/">Try in browser →</a>
      <span class="cta cta-disabled" aria-disabled="true">iOS · coming soon</span>
      <span class="cta cta-disabled" aria-disabled="true">Android · coming soon</span>
    </div>
  </section>
</main>
```

Page `<title>` is `Migraine Forecast — how it works`, `<meta name="description">` is `The evidence base, the eleven triggers tracked, and how personalization sharpens your daily score.`.

- [ ] **Step 2: Preview**

Open `http://localhost:8000/how-it-works/`. Expected: prose page renders cleanly, theme toggle works, nav back to `/` works.

- [ ] **Step 3: Commit**

```bash
git add site/public/how-it-works/
git commit -m "feat(site): /how-it-works/ explainer"
```

---

## Task 5: `/privacy/` page

**Files:**
- Create: `site/public/privacy/index.html`
- Read: `docs/privacy-policy.md` (source of truth — copy and render)

- [ ] **Step 1: Read source**

```bash
cat docs/privacy-policy.md
```

- [ ] **Step 2: Write `site/public/privacy/index.html`**

Use the same boilerplate (head/header/footer/theme.js) as Task 3. Replace `<main>` with the privacy content rendered as HTML.

Translate the markdown directly: each `# Heading` becomes `<h1>` (use `class="hero"` on the very first one only), `## H2` → `<h2>`, `### H3` → `<h3>`, paragraphs become `<p class="muted">` (except short standalone definitional lines), lists become `<ul>` / `<ol>`. Use `<main class="prose">` for spacing.

Page `<title>`: `Migraine Forecast — privacy`. Meta description: `What data the app stores, where it lives, and what we never collect.`.

Do NOT alter the substance — only translate formatting. If the markdown contains links or code spans, preserve them as `<a>` and `<code>`.

- [ ] **Step 3: Preview**

Open `http://localhost:8000/privacy/`. Expected: full privacy policy text renders in prose style, theme toggle works.

- [ ] **Step 4: Commit**

```bash
git add site/public/privacy/
git commit -m "feat(site): /privacy/ page (rendered from docs/privacy-policy.md)"
```

---

## Task 6: `/faq/` page

**Files:**
- Create: `site/public/faq/index.html`

- [ ] **Step 1: Write `site/public/faq/index.html`**

Use the same boilerplate as Task 3. Replace `<main>` with this:

```html
<main class="prose">
  <section class="block">
    <span class="label accent">FAQ</span>
    <h1 class="hero">Common questions.</h1>
    <p class="lead muted">If you don't see your question, the contact link in the footer is real.</p>
  </section>

  <section class="block">
    <details class="faq-item surface" open>
      <summary>What does Migraine Forecast actually do?</summary>
      <p class="muted">It gives you a daily 0–100 migraine risk score based on eleven evidence-backed triggers — barometric pressure, sleep, HRV, hormones, hydration, alcohol, caffeine, meals, stress, light, activity. You see the top contributing factors next to the score. As you log headaches, the model learns which triggers matter for <em>you</em> and reweights accordingly.</p>
    </details>

    <details class="faq-item surface">
      <summary>What data does it collect? Where does it live?</summary>
      <p class="muted">All data stays on your device, in an encrypted local SQLite database. The app doesn't have a backend, doesn't require an account, and doesn't transmit your logs or biometric data anywhere. The only network traffic is to fetch weather forecasts (Open-Meteo) and — if you connect Oura — to fetch your Oura data using your own OAuth tokens. See the <a href="/privacy/">privacy policy</a> for the long version.</p>
    </details>

    <details class="faq-item surface">
      <summary>How does Oura Ring integration work? Is it required?</summary>
      <p class="muted">It's optional. By default the app reads from Apple Health (iOS) or Health Connect (Android). If you'd rather use Oura, connect it from Settings → Health Data Sources. Authentication happens through Oura's OAuth flow in a browser tab; tokens are stored in the device's secure keychain and never leave the device. You can disconnect at any time.</p>
    </details>

    <details class="faq-item surface">
      <summary>Do I need an account?</summary>
      <p class="muted">No. There is no signup, no email, no user ID. Open the app, answer a brief onboarding questionnaire, start using it.</p>
    </details>

    <details class="faq-item surface">
      <summary>Is it a medical device? Can I rely on it for treatment decisions?</summary>
      <p class="muted">No. Migraine Forecast is not a medical device. It does not diagnose, treat, prevent, or cure migraines. The score is a pattern-recognition aid — useful for spotting triggers and timing preventive actions you've already discussed with a clinician. If your headaches are severe, frequent, or changing, see a doctor.</p>
    </details>

    <details class="faq-item surface">
      <summary>When will the iOS and Android apps be available?</summary>
      <p class="muted">The web version works today — try it at <a href="/app/">/app/</a>. Native iOS and Android builds are in progress; they'll ship to the App Store and Play Store once they're ready. Until then, the web build is the canonical experience.</p>
    </details>

    <details class="faq-item surface">
      <summary>Is the code open source?</summary>
      <p class="muted">Yes, the source is on <a href="https://github.com/" rel="noopener">GitHub</a>. The Flutter app, the Pure-Dart domain core, and this marketing site are all in the same repository.</p>
    </details>

    <details class="faq-item surface">
      <summary>Why does the web build ask for location or health permissions?</summary>
      <p class="muted">Location is used to fetch local weather forecasts (barometric pressure, in particular). Health permissions are needed to read sleep and HRV from your device. Both prompts come from the browser, not from a server — the data goes from the browser API straight to the on-device store. Denying either is fine; the corresponding trigger modules just sit out and the score is built from the remaining signals.</p>
    </details>

    <details class="faq-item surface">
      <summary>Can I export my data?</summary>
      <p class="muted">Yes. Settings → Export produces a JSON file with your logs, scores, and configuration. You can re-import on a new device.</p>
    </details>

    <details class="faq-item surface">
      <summary>How do I get in touch?</summary>
      <p class="muted">Email is in the footer. For bug reports and feature requests, the GitHub issues tracker is the fastest path.</p>
    </details>
  </section>

  <section class="block">
    <h2>Still curious?</h2>
    <div class="ctas">
      <a class="cta cta-primary" href="/app/">Try in browser →</a>
      <a class="cta cta-secondary" href="/how-it-works/">Read how it works</a>
    </div>
  </section>
</main>
```

Page `<title>`: `Migraine Forecast — FAQ`. Meta description: `Common questions about data, accounts, Oura integration, and native apps.`.

- [ ] **Step 2: Preview**

Open `http://localhost:8000/faq/`. Expected: ten collapsible Q&A items, the first one open by default, theme toggle works.

- [ ] **Step 3: Commit**

```bash
git add site/public/faq/
git commit -m "feat(site): /faq/ page"
```

---

## Task 7: Favicon + `_headers`

**Files:**
- Create: `site/public/favicon.svg`
- Create: `site/_headers`

- [ ] **Step 1: Write `site/public/favicon.svg`**

A simple monogram — a mint dot on dark, recognizable at 16×16:

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32">
  <rect width="32" height="32" rx="6" fill="#14181f"/>
  <path d="M8 22 L14 10 L18 18 L24 8" fill="none" stroke="#a3e4cb" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
```

- [ ] **Step 2: Write `site/_headers`**

```
/styles.css
  Cache-Control: public, max-age=86400

/theme.js
  Cache-Control: public, max-age=86400

/favicon.svg
  Cache-Control: public, max-age=604800

/app/*
  Cache-Control: public, max-age=3600

/*
  X-Content-Type-Options: nosniff
  Referrer-Policy: strict-origin-when-cross-origin
  Permissions-Policy: geolocation=(self), camera=(), microphone=(), payment=()
```

- [ ] **Step 3: Commit**

```bash
git add site/public/favicon.svg site/_headers
git commit -m "feat(site): favicon + cache/security headers"
```

---

## Task 8: Deploy script

**Files:**
- Create: `scripts/deploy-site.sh`

- [ ] **Step 1: Write `scripts/deploy-site.sh`**

```bash
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
```

- [ ] **Step 2: Make it executable**

```bash
chmod +x scripts/deploy-site.sh
```

- [ ] **Step 3: Add `site/public/app/` to .gitignore**

Append to `.gitignore`:

```
# Flutter web build copied here by scripts/deploy-site.sh
site/public/app/
```

- [ ] **Step 4: Commit**

```bash
git add scripts/deploy-site.sh .gitignore
git commit -m "feat(deploy): scripts/deploy-site.sh — flutter build web + wrangler pages deploy"
```

---

## Task 9: Local-build smoke check

**Files:**
- None created. This is a verification step.

- [ ] **Step 1: Build the Flutter web app locally**

```bash
./scripts/deploy-site.sh --local
```

Expected: completes without error, `site/public/app/index.html` exists, `site/public/app/main.dart.js` exists.

If Flutter is not available in the agent's environment, skip this step and flag to the user that they need to run it before deploying.

- [ ] **Step 2: Preview the integrated site**

```bash
cd site/public && python3 -m http.server 8000
# open http://localhost:8000
```

Expected:
- `/` renders, theme toggle works, nav links go to populated pages.
- `/how-it-works/`, `/privacy/`, `/faq/` all render.
- `/app/` loads the Flutter web build (note: it may need permissions and a network call for weather data).

- [ ] **Step 3: No commit — verification only**

If anything fails, fix in the responsible task and re-verify.

---

## Task 10: Hand off to user for Cloudflare Pages setup

**Files:**
- None.

This is a manual step the agent cannot complete autonomously — wrangler authentication and Pages project creation are out-of-band.

- [ ] **Step 1: Print instructions for the user**

```
The site is ready to deploy. Before running scripts/deploy-site.sh you need:

  1. Wrangler authenticated:
       npx wrangler login

  2. A Pages project to deploy into. Either:
     a) Create via dashboard at https://dash.cloudflare.com → Workers & Pages → Create →
        Pages → "Direct upload", name it "migraine-forecast"
     b) Or pass --project-name <name> to use an existing project.

  3. Run:
       ./scripts/deploy-site.sh

Once deployed you'll get a *.pages.dev URL. Wiring a custom domain is a dashboard step
when you've decided on one.
```

---

## Self-Review

**Spec coverage check:**

- Four pages (/, /how-it-works, /privacy, /faq) — Tasks 3, 4, 5, 6 ✓
- Flutter web build at /app/ — Tasks 8, 9 ✓
- Two themes with header toggle, prefers-color-scheme on first visit, localStorage persistence — Tasks 1 (CSS), 2 (toggle JS), 3 (inline first-paint script) ✓
- Plain HTML+CSS, no build step — confirmed across all tasks ✓
- Cloudflare Pages, single project, `--base-href /app/` — Task 8 ✓
- Cache headers, no analytics — Task 7 (_headers), no analytics tasks ✓
- Accessibility: contrast, aria-label on toggle, semantic nav/main/footer — Task 1 (CSS contrast), 2 (aria-label), 3-6 (semantic HTML) ✓
- Out of scope items not implemented: no blog, no analytics, no contact form, no OG image, no sitemap — confirmed ✓

**Placeholder scan:** No TBDs, no "implement later", no "similar to Task N". The privacy page (Task 5) intentionally instructs the agent to translate markdown faithfully rather than copy-pasting current text verbatim, because the markdown content may evolve — this is a directive, not a placeholder.

**Type consistency:** CSS class names used in Task 3+ (`.surface`, `.muted`, `.dim`, `.accent`, `.cta`, `.cta-primary`, `.cta-secondary`, `.cta-disabled`, `.pill`, `.pills`, `.feature`, `.feature-grid`, `.label`, `.lead`, `.hero`, `.wrap`, `.site-header`, `.site-footer`, `.cols`, `.block`, `.prose`, `.faq-item`, `.theme-toggle`, `.ctas`) all defined in Task 1's `styles.css`. ✓

The deploy script uses `flutter build web --base-href /app/` — the trailing slash matters and is consistent everywhere it appears.
