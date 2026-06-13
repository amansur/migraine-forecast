# Migraine Forecast - Project Instructions

A local-first Flutter application designed to predict daily migraine risk by analyzing evidence-backed triggers such as barometric pressure, sleep quality, HRV, and lifestyle factors.

## Project Overview

- **Core Purpose:** Decision-support tool for migraineurs to anticipate high-risk days using a rules-based scoring engine.
- **Architecture:** Three-layer Clean Architecture with strict separation.
    - `packages/domain/`: Pure Dart engine. `RiskEngine`, `TriggerModule`s, `BaselineStore`, `RulesConfig`, `CorrelationAnalyzer`. **Strictly no Flutter, no `dart:io`.**
    - `lib/data/`: Adapters (Open-Meteo, Health Connect/Apple Health, Geolocator) and Persistence (Drift). Normalizes external data for the domain.
    - `lib/ui/` + `lib/state/`: Riverpod providers and Flutter screens (Onboarding, Today, Log, Insights, Settings).
- **Tech Stack:** Flutter, Riverpod, GoRouter, Drift (SQLite/WASM), `flutter_local_notifications`, Workmanager.

## Building and Running

### Prerequisites
- Flutter SDK (latest stable)
- macOS: CocoaPods (`brew install cocoapods`) and Xcode.
- Android: Android Studio and SDK.

### Key Commands
- **Run Application:** `flutter run` (macOS desktop is the fastest test path).
- **Run All Tests:** `flutter test`
- **Run Domain Tests:** `cd packages/domain && dart test`
- **Code Generation:** `dart run build_runner build --delete-conflicting-outputs`
- **Score CLI:** `cd packages/domain && dart run bin/score_cli.dart ../../assets/rules_config_v1.json /path/to/context.json`

## Development Conventions

### Architecture & Integrity
- **TDD Mandate:** Every task should be test-first. Maintain high coverage (currently ~144 tests).
- **Domain Purity:** Never import Flutter or `dart:io` into `packages/domain`. Use `EvaluationContext` to pass data in.
- **Drift Row Collisions:** To avoid collisions between Drift-generated classes and domain models, use:
  ```dart
  import 'package:domain/domain.dart' hide Attack, JournalEntry, WeatherSnapshot, RiskAssessment;
  ```
- **Local-First:** All health and trigger data must stay on-device.

### Data Management
- **Drift Migrations:** When modifying `lib/data/database.dart`, increment `schemaVersion` and implement `onUpgrade` in `MigrationStrategy`.
- **Repository Pattern:** Abstract storage in `lib/data/repos/`. Avoid using `dynamic` where possible (unless working around generated class collisions in repo mappers).
- **Settings:** Access persistence settings via `SettingsRepo`.

### UI & Styling
- **Navigation:** Use `context.push()` if you need to return (e.g., to Settings), or `context.go()` for top-level swaps.
- **Unit Formatting:** Use `lib/ui/shared/unit_formatter.dart` for temperature and pressure display logic. Note: Temperature *deltas* (e.g., temp swing) use `°ΔC` and convert with 9/5 only.
- **Design:** Follow the "Calm/Wellness" tone. Use Sage greens and warm ivory. Risk bands (low/moderate/high) use green/amber/red accents.

### Rigorous Logic & Verification
- **Never bypass logic to satisfy tests:** If a test fails due to a complex dependency (e.g., a background backfill), fix the **test setup** (stubs/mocks) rather than making the **app logic** less robust (e.g., fire-and-forget) to pass the test.
- **Audit Caching Math:** When implementing or extending caching logic, always check for "negative duration" masks. Use `.abs()` when comparing `DateTime` differences to ensure current data doesn't shadow historical or future requests.
- **Prevent Race Conditions in Save Paths:** Ensure that data linking (e.g., attaching a `riskAssessmentId` to an `Attack`) is always `awaited` if the data is available or can be computed. Avoid "fire-and-forget" for data that needs to be cross-referenced immediately.
- **Time-Travel Awareness:** When implementing historical data features (backfilling), verify that **every** data source (Weather, Health, Journal, etc.) is actually querying the requested past window rather than defaulting to the current 24 hours.
- **Audit Implementation Before Assumption:** Before stating a bug is fixed, perform a surgical read of the implementation (not just the interface) to verify that the logic actually supports the fix (e.g., check that HealthSource actually uses the 'now' parameter).

## Key Files & Directories
- `docs/superpowers/specs/`: Architectural source of truth and research citations.
- `docs/handoff/`: Session-by-session history and current branch state.
- `assets/rules_config_v1.json`: Central configuration for the risk engine.
- `lib/services/`: Cross-cutting concerns like notifications, background scheduling, and suggestion engine.
- `packages/domain/lib/src/modules/`: Individual trigger logic implementations.

## Future Roadmap: Retrospective Correlation Plan
To support backfilling missing risk data when a migraine is logged for a past date:

1.  **Historical Weather Support:**
    - Extend `WeatherSource.fetch` to support a `targetDate`.
    - Implement a historical adapter using Open-Meteo's Archive API (`archive-api.open-meteo.com`).
2.  **Date-Anchored Context:**
    - Refactor `ContextBuilder` to fetch all triggers (Health, Weather, Journal) relative to a provided `targetDate` instead of `DateTime.now()`.
3.  **Backfill Orchestrator:**
    - Create `lib/services/backfill_orchestrator.dart` to identify gaps in `riskAssessments` over the last 90 days.
    - Trigger this service whenever a past-dated attack is logged.
    - Orchestrate: Fetch Historical Context -> Run `RiskEngine` -> Save `RiskAssessment` snapshot.
4.  **Verification:**
    - Add integration tests verifying that logging a past attack results in a reconstructed `RiskAssessment` and updated `CorrelationResults`.
