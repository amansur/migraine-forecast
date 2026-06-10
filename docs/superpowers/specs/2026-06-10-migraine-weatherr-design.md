# Migraine Weatherr — v1 Design

**Status:** Draft for review
**Date:** 2026-06-10

## Overview

Migraine Weatherr is a Flutter app for migraine sufferers that predicts daily migraine risk using a rules-based scoring engine derived from published research. v1 is a public consumer app shipping on iOS, Android, and Web, with a local-first architecture (no backend, no accounts). The headline value proposition is a daily risk forecast paired with a personalized trigger journal that surfaces which triggers correlate for that user over time.

### v1 Goals

- Produce an explainable daily migraine-risk score (0–100, low/medium/high band) from automatically-gathered data on the user's device.
- Let users log migraines and self-reported triggers (alcohol, caffeine, stress, hydration) for retrospective correlation.
- Notify the user in the morning when today's risk is high, and in the evening when tomorrow's risk is high.
- Keep all health data on-device.

### Out of scope for v1

- User accounts / login
- Cross-device sync
- Doctor sharing / PDF export
- Medication tracking

Push notifications and risk alerts ARE in v1.

## Branding and Aesthetics

- **Name:** Migraine Weatherr
- **Tone:** Calm / wellness — soft, soothing, non-clinical. Medical-adjacent without feeling like a medical device.
- **Palette:** Sage greens and warm ivory base; risk-band accents (calm green → soft amber → muted red) reserved for the risk display itself.
- **Typography:** Rounded, readable, generous line height. System fonts (SF / Roboto) styled for warmth.
- **Risk display:** User-configurable in Settings — choose between **gauge / arc**, **numeric score**, or **weather-inspired icon** (sunny → cloudy → stormy → severe). Same underlying score, three visualizations.
- **Motion:** Subtle. No alarmist transitions. A high-risk day reads as informative, not panicked.

## Triggers and Evidence

Trigger short-list derived from a research review of peer-reviewed literature and credible clinical sources (AMF, NHS, Mayo).

### Auto-measured (six modules)

| Trigger | Evidence | Signal | Data source | Lead time |
|---|---|---|---|---|
| Barometric pressure drop | Moderate–strong (Okuma 2015, PMC4521004) | 24h Δ pressure ≥ 5 hPa in next 48h | Open-Meteo `pressure_msl` hourly | 6–48h |
| Humidity + temp swing | Moderate (Hoffmann 2015, PubMed 25754774) | RH >60% AND 24h temp Δ ≥ 5°C | Open-Meteo `relative_humidity_2m`, `temperature_2m` | 24h |
| Air quality (PM2.5) | Moderate (Chiu 2015, PubMed 25492974) | PM2.5 > 35 µg/m³ | Open-Meteo Air Quality API | 24h |
| Sleep deficit | Strong (Bertisch 2020, PMC6624145) | <6h total, efficiency <85%, or schedule shift >2h vs 7d median | Apple Health / Health Connect sleep records | 24h |
| HRV let-down | Moderate–strong (Koenig 2016 meta) | RMSSD drop >20% from 14d baseline | Apple Health / Health Connect HRV | same-day to 18h |
| Menstrual phase | Strong (MacGregor 2004) | Cycle day -2 to +3 around menses onset | Apple Health / Health Connect menstrual flow | 2–5 days |
| Days since last attack | Moderate (post-attack refractory pattern observed in diary studies) | Risk dips for 24–72h after a logged attack, rebounds after | Derived from `attacks` table | same-day |

### Self-logged (four modules)

| Trigger | Evidence | Signal | Source |
|---|---|---|---|
| Alcohol | Strong (Onderwater 2019) | Any alcohol in prior 24h, type tag | Journal entry |
| Caffeine | Moderate (Lipton, withdrawal effect) | Δ vs personal baseline >100 mg | Journal entry |
| Stress / let-down | Strong (Lipton 2014, PMC4035680) | 1–5 self rating; let-down detection on rapid drop | Journal entry |
| Hydration | Moderate (Blau 2004, PubMed 15546261) | <1.5 L logged; weighted higher in hot weather | Journal entry |

Triggers considered and deferred to later versions for weak/contested evidence: tyramine foods, MSG, nitrates, blue light / screen time.

## Architecture

Three layers, with the domain core kept pure and testable.

### 1. Data sources (adapters)

Thin, single-purpose wrappers over external dependencies. Each adapter has a typed Dart interface in the domain layer and a concrete implementation in the app layer.

- `WeatherSource` → Open-Meteo (weather forecast + air quality). Free, unlimited non-commercial, no API key. Endpoint examples: `https://api.open-meteo.com/v1/forecast`, `https://air-quality-api.open-meteo.com/v1/air-quality`.
- `HealthSource` → `health` package (pub.dev/packages/health). Unifies Apple Health (HealthKit) and Android Health Connect. Reads: sleep stages, HRV RMSSD, resting HR, menstrual flow, steps, hydration.
- `JournalSource` → local Drift / SQLite for user-logged migraines and trigger entries.
- `LocationSource` → device location for weather lat/lon, with manual city fallback.
- `NotificationSource` → `flutter_local_notifications` + platform background scheduling (`workmanager` on Android, `BGTaskScheduler` on iOS).

Adapters fetch and normalize. They contain no prediction logic.

### 2. Domain core (pure Dart)

Pure Dart package with no Flutter or `dart:io` imports — could be reused server-side if a backend is added later.

- `TriggerModule` interface (see below).
- `RiskEngine` — collects signals from enabled modules, applies weights from `rules_config.json`, returns a `RiskAssessment { score, band, contributors, computedAt, configVersion }`.
- `BaselineStore` — rolling per-user baselines (sleep median, HRV RMSSD baseline, pressure baseline). Pure functions over historical data.

The domain core never touches APIs or storage directly — adapters pass data in via `EvaluationContext`, the engine returns assessments out.

### 3. App layer

- `RiskController` (Riverpod) — orchestrates adapters → engine → UI; runs morning + evening refresh; schedules notifications.
- `JournalController` — migraine logging, trigger journal entry.
- Screens:
  - **Onboarding** (first-launch only): trigger-flag multi-select (stress, sleep, weather, hormones, light, smell, caffeine, alcohol, dehydration), menstrual-tracking opt-in, permission requests, risk-display preference, disclaimer.
  - **Today**: hero risk display (gauge / numeric / weather icon — user choice) showing **today and tomorrow side-by-side**, active contributing-factor chips (only modules currently elevating risk), inline quick check-in (sleep hours if no Health data, stress 1–5 tap, journal trigger flags), prominent **Log Attack** button.
  - **Log Attack**: start/end time, severity 1–10, free-text notes. Stamps with the active `RiskAssessment.id` for retrospective correlation.
  - **Insights** (unlocked after 3 logged attacks): calendar heatmap of attacks, per-trigger correlation cards ("Pressure drops preceded 7 of your last 9 attacks"), model-personalization progress.
  - **Settings**: permissions, enabled trigger modules, **per-trigger user weight overrides** (-2…+2 multiplier), notification preferences, risk-display mode, manage flagged triggers.

### Storage schema (Drift / SQLite, local-only)

Sketch — refined during implementation:

- `attacks` — id, started_at, ended_at, severity (1–10), notes, risk_assessment_id (FK).
- `risk_assessments` — id, target_date, horizon (today / tomorrow), score (0–100), band, computed_at, config_version, contributors_json.
- `journal_entries` — id, timestamp, kind (alcohol / caffeine / stress / hydration), payload_json.
- `daily_logs` — date, sleep_hours, sleep_quality, stress, menstrual_phase, custom_trigger_flags (used when Health permissions aren't granted).
- `weather_snapshots` — timestamp, lat, lon, pressure_msl, pressure_delta_24h, temperature_2m, relative_humidity_2m, pm2_5, raw_json.
- `baselines` — metric (sleep_median_7d / hrv_rmssd_14d / pressure_baseline), value, updated_at.
- `user_trigger_flags` — module_id, flagged (bool from onboarding), weight_override (signed multiplier, default 0).

## Trigger Modules and Rules Config

### Module interface

```dart
abstract class TriggerModule {
  String get id;
  Set<DataRequirement> get requires;
  Duration get leadTime;
  TriggerSignal evaluate(EvaluationContext ctx, TriggerParams params);
}

class TriggerSignal {
  final double weight;        // contribution to the score
  final double confidence;    // 0–1, reflects data quality
  final String explanation;   // one-line human string for the UI
}
```

### Rules config

Tunable parameters live in `assets/rules_config_v1.json`, versioned and shipped with each release. Module *logic* lives in Dart (each trigger has its own shape — pressure delta vs forecast lookahead, sleep vs personal median, HRV vs rolling baseline, etc.); JSON holds only thresholds, weights, and lookback windows.

```json
{
  "version": 1,
  "modules": {
    "pressure_drop":       { "enabled": true, "weight_max": 18, "threshold_hpa": 5, "lookahead_hours": 48 },
    "humidity_temp_swing": { "enabled": true, "weight_max": 10, "humidity_pct": 60, "temp_delta_c": 5 },
    "air_quality":         { "enabled": true, "weight_max": 10, "pm25_threshold": 35 },
    "sleep_deficit":       { "enabled": true, "weight_max": 20, "hours_threshold": 6, "efficiency_threshold": 0.85, "baseline_days": 7 },
    "hrv_letdown":         { "enabled": true, "weight_max": 12, "drop_pct": 20, "baseline_days": 14 },
    "menstrual_phase":     { "enabled": false, "weight_max": 20, "window_days": [-2, 3] },
    "alcohol":             { "enabled": true, "weight_max": 12, "lookback_hours": 24 },
    "caffeine":            { "enabled": true, "weight_max": 8,  "delta_mg_threshold": 100 },
    "stress":              { "enabled": true, "weight_max": 12 },
    "hydration":           { "enabled": true, "weight_max": 8,  "min_liters": 1.5 },
    "refractory":          { "enabled": true, "weight_max": 6,  "suppression_hours": 48 }
  },
  "score_bands": { "low": [0, 25], "moderate": [25, 50], "high": [50, 75], "very_high": [75, 100] },
  "unflagged_trigger_confidence_multiplier": 0.6
}
```

Each `RiskAssessment` is stamped with the `configVersion` that produced it so historical scores remain reconstructible across config updates. Menstrual phase is opt-in (default disabled).

### Day-1 personalization via onboarding trigger flags

During onboarding, the user multi-selects their **suspected** triggers from the list above. The result is stored in `user_trigger_flags`. At evaluation time:

- A **flagged** trigger's signal passes through at full confidence.
- An **unflagged** trigger's signal is multiplied by `unflagged_trigger_confidence_multiplier` (default 0.6) — it still contributes (users don't know all their triggers yet) but with less authority.

This gives day-1 personalization without any ML — a stress-flagged user gets a meaningfully different score from a weather-flagged user even on identical conditions.

### User weight overrides

Power users can adjust a trigger's contribution in Settings via a -2…+2 slider stored in `user_trigger_flags.weight_override`. The engine treats it as an additive nudge to the module's `weight_max` (clamped). Always inspectable, always reversible.

When data for a module is missing (e.g., Health permission denied, no journal entries), the module returns `confidence: 0` and contributes nothing. The UI surfaces which modules are inactive.

## Data Flow

### Scheduled refreshes

- **Morning** (default 6am, configurable): pull last night's sleep + HRV, fetch today/tomorrow weather + AQ forecast, recompute today's risk, notify if today is high.
- **Evening** (default 8pm): pull updated tomorrow forecast + today's journal entries, recompute tomorrow's risk, notify if tomorrow is high.

Background execution via `workmanager` (Android) and `BGTaskScheduler` (iOS). iOS background fetch is best-effort; foreground open triggers a catch-up refresh if last successful refresh is >6h old. Every `RiskAssessment` carries `computedAt`; UI shows "updated 3h ago".

### Per-refresh sequence

1. `RiskController.refresh(target: today | tomorrow)`.
2. Gather inputs in parallel: `WeatherSource.forecast(lat,lon)`, `HealthSource.recentMetrics(window)`, `JournalSource.recentEntries(window)`, `BaselineStore.snapshot()`.
3. Build immutable `EvaluationContext`.
4. `RiskEngine.evaluate(context, rulesConfig)` → iterates enabled modules; each returns a `TriggerSignal`.
5. Combine: `score = clamp(Σ weight·confidence, 0, 100)`. Engine attaches top-N contributors for the UI.
6. Persist `RiskAssessment` to Drift (`risk_assessments` keyed by date + horizon).
7. Update baselines from new health data.
8. If score crosses notification threshold AND no notification fired for that date+horizon yet, schedule a local notification.

### User-initiated flows

- **Pull-to-refresh on Today**: same sequence, foreground only, no notification.
- **Log a migraine**: writes to `migraines` table with timestamp, severity, tags, and the active `RiskAssessment.id` at that moment. Enables retrospective correlation analysis.
- **Journal entry**: appended to `journal_entries`; next refresh picks it up.

### Caching and offline

- Weather forecasts cached for 1h (matches Open-Meteo's effective resolution). If offline, last cached forecast is used and UI flags it stale. After 24h with no successful fetch, weather modules report `confidence: 0`.
- Health reads are best-effort; missing data → module sits out.
- All scoring is offline-capable once weather is cached.

### Onboarding and permissions ladder

Asked progressively, not up front:

0. **Onboarding** — first launch only. Trigger-flag multi-select, menstrual-tracking opt-in, risk-display preference, disclaimer. No permissions requested yet beyond what's needed to complete each step.
1. **Location** — first launch (after onboarding), required for weather. Manual city fallback if denied.
2. **Notifications** — when user enables the morning alert toggle.
3. **Health** — when user visits Settings → "Improve predictions with health data". Each Health category (sleep, HRV, menstrual) requested independently.

## Error Handling and Edge Cases

### Failure philosophy

A missing input degrades the score's confidence; it never blocks producing a score. The user always sees a score with explicit "stale" / "limited data" indicators rather than silent failure.

### Per-source failures

| Source | Failure | Behavior |
|---|---|---|
| Open-Meteo | network / 5xx | Last cached forecast, `stale: true`, retry next refresh. After 24h, modules report `confidence: 0`. |
| Open-Meteo | 4xx | Surface "Location not supported" in Settings; log. |
| Location | permission denied | Fallback to user-picked city. If none set, prompt on Today screen. |
| Location | GPS unavailable | Use last known location for up to 7 days, then re-prompt. |
| Health | permission denied per-type | Module sits out. Soft, dismissible CTA on Today to enable. |
| Health | empty result | `confidence: 0`. Not treated as error. |
| Health | platform exception | Log, skip module this refresh, don't crash engine. |
| Drift | write failure | Surface a banner, queue retry, hold migraine log in memory until write succeeds. |
| Background task | OS killed / skipped | Foreground catch-up if last refresh >6h old. |
| Notifications | permission denied | Toggle disables itself; no silent breakage. |

### Engine safeguards

- Each module's `evaluate()` is wrapped in try/catch — a single buggy module can't break a refresh.
- Score always clamped to 0–100 regardless of misconfigured weights.
- If *every* module reports `confidence: 0`, the UI shows an onboarding card instead of a meaningless "0 risk".

### Data-quality edges

- **Cold-start baselines**: HRV needs 14d, sleep needs 7d. Until then, literature-derived defaults with `confidence: 0.5`. UI: "personalizing — accuracy improves over [N] more days."
- **Travel / timezone change**: location delta >100 km suppresses sleep-schedule-shift signal for 3 days post-travel.
- **Irregular cycles**: if last 6 cycles' std-dev >5 days, menstrual module reports lower confidence with a wider window.
- **No menstrual data at all**: module disabled by default; opt-in in Settings.
- **Config corruption**: bundled fallback `rules_config_v1.json`; loader validates schema and falls back on invalid input.
- **Clock change / DST**: all timestamps stored UTC; "today" computed from device local time only at the UI layer.

### Disclaimers

No medical advice. Score is always framed as risk/likelihood with contributors visible. Onboarding includes a one-screen disclaimer: decision-support, not diagnosis; consult a clinician.

## Testing Strategy

Three tiers, weighted toward the domain core.

### 1. Domain unit tests

`package:test`, no Flutter, no IO.

- One test file per `TriggerModule`. Fixture-driven (context, params, expected signal) tables. Example for `pressure_drop`: hourly pressure dropping 7 hPa over 18h → expect proportional weight, confidence 1.0, explanation contains "7 hPa". Includes edge cases from above (cold start, missing data, all zeros).
- `RiskEngine` with mock modules: weight summing, 0–100 clamping, contributor ranking, "every module zero-confidence → onboarding signal".
- `BaselineStore` over synthetic time series: rolling median, percentile drift, jet-lag suppression.
- Rules config loader: schema validation, bundled-fallback on bad JSON, version stamping on assessments.

### 2. Adapter contract tests

Verify each adapter satisfies its interface against recorded / canned responses.

- `WeatherSource`: recorded Open-Meteo JSON fixtures (typical day, missing fields, pressure-drop event, AQ spike). No live network in CI.
- `HealthSource`: `health` package wrapped behind our own interface; tests use a fake. We test that our adapter maps the package's types to our domain types correctly.
- `JournalSource`: real Drift in-memory database; tests CRUD and engine query.
- Caching: stale forecasts returned with `stale: true` after the freshness window.

### 3. App-layer tests

Focused on orchestration, not pixels.

- Widget tests for Today: given a `RiskAssessment`, correct band color / score / contributors render. Riverpod overrides inject fake assessments.
- Golden tests for the three risk-band states (low/medium/high) and onboarding state.
- `RiskController` integration: wires fake adapters end-to-end, triggers refresh, asserts persisted assessment and notification scheduling for high-band scores.
- Permissions flow: tested at controller level via faked permission states.

### Not tested

- Third-party `health` package internals.
- Live Open-Meteo responses in CI (recorded fixtures only). Manual fixture-refresh script lives in `tool/`.
- Background-execution timing on real OS schedulers (verified manually before release).

### CI

GitHub Actions on push: full `flutter test` plus a faster pure-Dart job for `domain/`. Coverage target ≥85% for `domain/`. UI coverage is not a target.

## Open Questions / Future Work

- Per-user calibration (logistic regression / correlation analysis) once a user has ≥30 migraine logs — designed for, not built in v1.
- Doctor-shareable PDF export.
- Cross-device sync (likely iCloud + Google Drive backup of the encrypted Drift file rather than a custom backend).
- Population ML model — requires a backend, accounts, and a privacy review; deliberately deferred past v1.
- Apple Watch / Wear OS companion for ambient HRV and faster Health reads.
