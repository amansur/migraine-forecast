# Maintenance Batch — UX polish, defaults, backfill correctness, CI hygiene

**Date:** 2026-06-14
**Status:** Draft, awaiting implementation

## Purpose

A batch of six independent corrective items, grouped because each one is small and low-risk on its own. Bundling avoids the overhead of six separate spec/plan cycles while keeping each item's intent and verification explicit.

The items, in implementation order:

1. Severity label readability in comfort mode (log attack screen).
2. Cycle tracking defaults OFF on fresh install.
3. Historical backfill — surface partial-failure counts and extend window via Open-Meteo archive API.
4. Clear three `dart analyze` warnings currently breaking CI.
5. Grant the release workflow `contents: write` so the GitHub release can be created.

Items are sequenced trivial → non-trivial. Items 1, 2, 4, 5 land first as a single PR; item 3 lands as its own PR because it carries a Drift migration and meaningful test surface.

## Item 1 — Comfort-mode severity label readability

**Symptom.** When comfort mode is active and the user opens the log-attack screen, the "Severity: N" label is unreadable against the dark surface.

**Root cause.** Two reinforcing bugs:

- `lib/ui/log/log_attack_screen.dart:47-49` wraps the screen in a second `Theme(data: buildComfortTheme())`. The app-level theme switch in `lib/app/app.dart:48` already does this when comfort mode is active, so the screen is double-wrapping. This wrapping was correct earlier when comfort mode was screen-local; it's now stale.
- `buildComfortTheme()` in `lib/app/theme.dart:52-95` applies its text colors via `textTheme.apply(bodyColor: onSurface, displayColor: onSurface)`. Material 3's `TextTheme.apply` covers most styles, but the rendered `titleMedium` in this screen ends up with insufficient contrast on the comfort surface.

**Fix.**

- Remove the `Theme` wrapper at `log_attack_screen.dart:47-49` and its closing `)` at line 113. The widget tree shrinks back to just `Scaffold`.
- In `lib/app/theme.dart`, leave `textTheme.apply(...)` in place but additionally set `colorScheme.onSurface` is already `0xFFDFD9D0` (acceptable contrast on `0xFF2E2C2B`). The actual remediation is the first bullet — the double wrap was producing a textTheme whose color resolved against the wrong scheme.

**Verification.**

- Widget test in `test/ui/log/log_attack_screen_test.dart`: pump the screen with `comfortModeProvider` overridden to `ComfortMode.always`, locate the severity `Text`, and assert its resolved color equals `Theme.of(tester.element(...)).colorScheme.onSurface`.
- Manual smoke: launch app, enable comfort mode in Settings, open log-attack screen, confirm label is readable.

## Item 2 — Cycle tracking defaults OFF

**Symptom.** Fresh installs have cycle tracking on. Onboarding should not assume the user wants this feature.

**Root cause.** `lib/state/settings_provider.dart:29-34` reads the stored string and returns `s != 'false'`, so an unset key resolves to `true`. The comment describes the feature as opt-out by design.

**Fix.**

- Change the body of `cycleTrackingEnabledProvider` to `return s == 'true';`.
- Update the doc comment: "Cycle tracking is opt-in — defaults to false on a fresh install. The 'on' state is stored explicitly as 'true' in settings."
- Audit onboarding (`lib/ui/onboarding/onboarding_screen.dart`) for any UI that assumes the toggle starts on; if onboarding has a cycle step, make the explicit "enable cycle tracking?" question opt-in.
- Audit settings (`lib/ui/settings/settings_screen.dart`) — no change needed, it reads the provider.

**Verification.**

- Update `test/state/...` cycle-tracking provider test (or add one) to assert: fresh install → false, set to true → true, set to false → false.
- Update `test/end_to_end/plan2_smoke_test.dart` if it implicitly relies on the prior default.

## Item 3 — Historical backfill: surface failures and extend window via archive API

**Symptom.** User initiated a backfill expecting ~90 days; only the last ~33 days (back to May 12) were populated. No error surfaced to the user.

**Root cause.** Two issues:

- **Silent failure.** `BulkBackfillOrchestrator._run` in `lib/data/bulk_backfill_orchestrator.dart:137-163` swallows per-day errors into `firstError` but `BackfillReport` only exposes `daysProcessed`, `daysSkipped`, `weatherFetchSucceeded`, and a single `firstError`. The Insights progress strip surfaces nothing about failed days.
- **Window cap.** The orchestrator primes the weather cache with `weatherSource.fetch(now: now, ...)` where `now` is today UTC, giving `pastDays = (0 + 2).clamp(1, 90) = 2`. Per-day fetches then issue their own calls, each with `past_days = diffDays + 2` clamped to 90. The Open-Meteo `forecast` endpoint accepts `past_days` up to 92 but historical reliability degrades past ~30 days; days older than that come back with no usable data, and `ContextBuilder` ends up producing an evaluation with no weather → the risk engine returns a "data not met" result that the orchestrator either fails on or stores as an empty assessment. Either way, ~30 days is the practical cap and the user sees a 33-day window. The code already carries a `TODO(v2): for windows > 90 days, fall back to Open-Meteo Archive API` comment acknowledging this.

**Fix.**

*Part A — surface partial failures.*

- Extend `BackfillReport` with `daysFailed: int` and `firstErrorByPhase: Map<String, Object>` (where phase ∈ `weatherPrime`, `perDay`). Populate from the existing loop.
- Update the Insights progress strip in `lib/ui/insights/insights_screen.dart` to render "filled 33 / 90 days (57 failed — weather unavailable)" when `daysFailed > 0`, with the reason text drawn from `firstErrorByPhase['perDay']` (truncated).

*Part B — archive API fallback.*

- Add `OpenMeteoUrlBuilder.archive({lat, lon, startDate, endDate})` targeting `https://archive-api.open-meteo.com/v1/archive` with the same hourly variables the forecast endpoint uses (pressure, temperature, humidity, dew point, wind, etc.) plus the air-quality archive endpoint at `https://air-quality-api.open-meteo.com/v1/air-quality` (which already accepts arbitrary historical windows).
- In `OpenMeteoWeatherSource.fetch`, when `requestedDay` is more than 30 days before today, route to the archive endpoint for that day instead of the forecast endpoint. Parse via the existing `OpenMeteoParser` paths — the field names match.
- Cache the archive response in `weatherSnapshots`. Add a `source` text column (`'forecast' | 'archive'`) via a new Drift migration, so reads can disambiguate. `_cachedForDay` continues to key by `fetchedAt` window; the new column is informational.
- In the orchestrator, drop the single prime fetch in favour of trusting per-day fetches now that archive supports arbitrary days. Or keep the prime but only for the recent ≤30-day window. Choose the simpler path: remove the prime, since the per-day cache logic already handles fan-out and the prime was only an optimisation for the forecast-endpoint case.

**Verification.**

- Unit test `OpenMeteoUrlBuilder.archive` URL shape.
- Parser test against a captured archive-endpoint response fixture.
- Orchestrator integration test with a fake `WeatherSource` that returns archive-shaped data for `diffDays > 30` and forecast-shaped data otherwise; assert all 90 days produce assessments.
- Migration test in `test/data/database_migration_test.dart` confirming the new `source` column is created and existing rows default to `'forecast'`.
- Manual smoke: trigger backfill from Insights, confirm the strip reports 90/90 and the heatmap fills back to the cutoff.

## Item 4 — Clear three `dart analyze` warnings

CI's `dart analyze` step in both `domain-tests` and `flutter-tests` jobs treats these warnings as failures.

- `packages/domain/test/modules/intraday_pressure_swing_test.dart:22` — `sampleAt` helper is unused. **Fix:** delete the helper (lines 22-27).
- `test/ui/insights/day_detail_cycle_row_test.dart:18` — `_FakeJournal` constructor's `overrides` parameter is never supplied by callers. **Fix:** verify by grep that no caller passes `overrides:`; if confirmed, drop the parameter. If a caller does set it implicitly through a default elsewhere, keep the field and instead annotate `// ignore: unused_element_parameter` with a one-line reason. Default action: remove.
- `test/ui/insights/insights_screen_test.dart:69` — local `day` is unused. **Fix:** delete the line, or replace with `_ = ...` if the right-hand side has side effects worth keeping (check first).

**Verification.** `dart analyze` clean in both `packages/domain` and the repo root; CI green on push.

## Item 5 — Release workflow: grant `contents: write`

**Symptom.** Release workflow `softprops/action-gh-release@v2` step fails with `403 Resource not accessible by integration` when posting the release for tag `v0.1.0`.

**Root cause.** The default `GITHUB_TOKEN` granted to workflows triggered by tag pushes has only `contents: read` unless the workflow explicitly opts up. Creating a release requires `contents: write`.

**Fix.** Add to `.github/workflows/release.yaml`:

```yaml
permissions:
  contents: write
```

At workflow root scope (top-level, above `jobs:`). No PAT is needed; the default `GITHUB_TOKEN` is sufficient once the permission is granted.

**Verification.** Push a throwaway tag (`v0.0.0-test`) to a personal branch, observe the workflow runs to completion and creates the release; delete the test release and tag after.

## Sequencing

- **PR 1:** items 1, 2, 4, 5 — trivial, no migration, no new endpoint.
- **PR 2:** item 3 — has a Drift migration, a new endpoint integration, and meaningful test surface.

## Out of scope

- Refactoring `OpenMeteoWeatherSource` to a strategy pattern (`ForecastFetcher` / `ArchiveFetcher`) — useful but the conditional branch by `diffDays` is fine for now.
- Showing per-day failure reasons in the heatmap (only the aggregate count surfaces in this batch).
- Reworking the comfort theme more broadly; only the immediate readability bug is in scope.
