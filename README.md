# Migraine Forecast

> Renamed from "Migraine Weatherr" on 2026-06-13.

A Flutter app that predicts daily migraine risk from evidence-backed triggers (barometric pressure, sleep, HRV, hormones, hydration, alcohol, stress, etc.). Local-first — all data stays on the device.

## Status

- **Plan 1** — Pure-Dart domain core (engine + 11 trigger modules) ✓
- **Plan 2** — Adapters + Drift storage (Open-Meteo, Health Connect / Apple Health, journal, location) ✓
- **Plan 3** — Flutter MVP (Onboarding, Today, Log, Settings) ✓
- **Plan 4** — Background scheduling + notifications (+ web sqlite3 fix) ✓
- **Plan 5** — Insights screen + correlation-driven personalization ✓

## Running locally

### macOS desktop (fastest)

The Dart/Flutter toolchain is installed; macOS desktop works out of the box. Drift's `sqlite3_flutter_libs` is native on macOS, geolocator uses Core Location. The `health` plugin has no macOS implementation — health-derived modules will sit out (`confidence: 0`).

```bash
flutter create --platforms=macos .
flutter run -d macos
```

### iOS simulator

Requires Xcode (App Store, ~15 GB) and CocoaPods.

```bash
sudo xcodebuild -runFirstLaunch
brew install cocoapods
flutter run -d ios
```

### Android (emulator or device)

Requires Android Studio for the SDK; a physical device with USB debugging is the fastest path.

```bash
flutter devices    # confirm device is listed
flutter run
```

### Web

`flutter build web` works and serves the app. SQLite runs via WASM (the `sqlite3.wasm` + drift worker are bundled in `web/`). Limitations: the `health` plugin has no web implementation; geolocator on web requires HTTPS + browser permission; background notifications go through the browser's Push API which we don't wire in v1.

## Testing

```bash
# Pure-Dart domain tests (fast, no Flutter SDK)
cd packages/domain && dart test

# Full app test suite (engine + adapters + UI + goldens)
flutter test

# CLI smoke (score arbitrary JSON contexts against the bundled config)
cd packages/domain && dart run bin/score_cli.dart \
  ../../assets/rules_config_v1.json \
  path/to/context.json
```

CI runs both jobs on every push: `.github/workflows/ci.yaml`.

## Architecture

Three layers, each independently testable:

- `packages/domain/` — pure-Dart engine, `TriggerModule`s, `RulesConfig`, `BaselineStore`. No Flutter, no IO. Tunable parameters live in `assets/rules_config_v1.json`; module logic stays in Dart.
- `lib/data/` — concrete adapters (Open-Meteo, `health`, `geolocator`, Drift schema + repos), `ContextBuilder` orchestrator.
- `lib/ui/` + `lib/state/` — Riverpod providers, screens (Onboarding, Today, Log, Settings), `RiskDisplay` widget with three variants.

See the design spec at `docs/superpowers/specs/2026-06-10-migraine-forecast-design.md` and the per-plan implementation docs under `docs/superpowers/plans/`.

## Personalization

After you've logged 3 migraines, the Insights tab unlocks:

- **Calendar heatmap** of the last 90 days, with attack days highlighted.
- **Trigger correlation cards** showing per-trigger attack rate when that trigger was active vs not, with classification (personal hit / personal miss / unclear).
- **Suggested weight adjustments** — when a trigger correlates strongly enough (90% Wilson CI excludes zero, ≥2× baseline rate, ≥3 attacks in the fired cohort), the app surfaces a one-tap card to bump that trigger's weight in your personal model. Every change is explicit, reversible, and based on a citeable cohort — no silent ML drift.

## Trigger research

The 11 trigger modules and their thresholds are derived from peer-reviewed literature (Bertisch 2020 sleep, Okuma 2015 pressure, MacGregor 2004 menstrual, Chiu 2015 air quality, Onderwater 2019 alcohol, etc.). See the "Triggers and Evidence" section of the design spec for citations.

## Disclaimer

Migraine Forecast is decision-support, not medical advice. The risk score is a probability estimate from rules-based scoring of measurable triggers — it is not a diagnosis, and the app cannot tell you whether you will or will not have a migraine.
