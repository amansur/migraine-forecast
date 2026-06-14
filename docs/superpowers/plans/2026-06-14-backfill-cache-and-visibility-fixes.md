# Plan: Backfill Cache Coverage and Progress Visibility

## Objective
Make the bulk historical backfill honor its stated invariant — **one network round trip primes the entire window** — and ensure the user actually sees progress while it runs. Fixes correctness-vs-spec issues found in the post-merge review of `2026-06-13-bulk-historical-backfill.md`.

## Current State

### Problem 1 — Prime fetch is mis-sized
`BulkBackfillOrchestrator._run` (`lib/data/bulk_backfill_orchestrator.dart:118-124`) calls:
```dart
await weatherSource.fetch(lat: ..., lon: ..., now: now, forceRefresh: true);
```
where `now = DateTime.now().toUtc()`. `OpenMeteoWeatherSource.fetch` (`lib/data/sources/open_meteo/open_meteo_weather_source.dart:46-49`) derives `pastDays` from `now`:
```dart
final diffDays = todayStart.difference(requestedDay).inDays.abs();
final pastDays = (diffDays + 2).clamp(1, 90);
```
With `requestedDay ≈ today`, `diffDays = 0` → `pastDays = 2`. The "prime" fetches today + yesterday only.

### Problem 2 — Cache lookup defeats the prime even if sized correctly
`_cachedForDay(lat, lon, day)` (`open_meteo_weather_source.dart:77-90`) keys on `fetchedAt BETWEEN day AND day+1` — when the snapshot was fetched, not which days its series *covers*. A row fetched today (whose `WeatherSeries.samples` span 90 days back) is invisible when the per-day loop asks for `day = 85 days ago`.

Compounding, line 35:
```dart
final isBackfill = requestedDay.isBefore(yesterdayStart);
...
if (cached != null && !isBackfill && !forceRefresh) { return ...; }
```
Even if the lookup found the row, `isBackfill = true` for any per-day call older than yesterday skips the cache entirely.

**Combined impact:** A 90-day backfill makes ~91 Open-Meteo calls (1 prime + 90 per-day), not 1. Free-tier rate limit (10k/day) absorbs this but: first run is slow, `weather_snapshots` table bloats, and the orchestrator's "pure in-memory slice" claim is false.

### Problem 3 — Progress strip invisible to new users
`InsightsScreen.build` (`lib/ui/insights/insights_screen.dart:38-43`) gates `_Body` (which contains `_BackfillProgressStrip`) behind `insightsEligibleProvider`. That provider (`lib/state/insights_eligibility_provider.dart:17-22`) is true only after the first logged attack. A user fresh out of onboarding sees `_NotEligible` ("Calibrating") and never sees the "Building history… N/90 days" strip — exactly when backfill matters most.

### Problem 4 — Orchestrator-internal `_running` guard is now dead code
`BulkBackfillOrchestrator._running` (`bulk_backfill_orchestrator.dart:43, 58-72`). The real concurrency guard lives at module scope in `lib/state/backfill_provider.dart:14-16`. Each `launchBackfill` constructs a fresh orchestrator, so the inner flag never sees a re-entry. Cosmetic but misleading.

### Problem 5 — Tests can't catch any of this
`test/data/bulk_backfill_orchestrator_test.dart` uses `_FakeWeatherSource` with no cache. It asserts `forceRefreshCount == 1` (intent) but cannot assert "exactly one network call across the full backfill" (outcome). All four current tests would pass even if the orchestrator made 1000 fetches.

## Architecture & Implementation

### 1. Add `pastDays` to `WeatherSource.fetch`
`lib/data/sources/weather_source.dart`:
```dart
Future<WeatherSnapshot> fetch({
  required double lat,
  required double lon,
  required DateTime now,
  bool forceRefresh = false,
  int? pastDays,  // null → existing diffDays-derived calc (today/tomorrow flows unchanged)
});
```
`OpenMeteoWeatherSource.fetch` (`open_meteo_weather_source.dart:45-65`): when `pastDays != null`, use it directly (still clamped to `[1, 90]`); otherwise keep current `(diffDays + 2).clamp(1, 90)`. No existing caller passes the new param, so today/tomorrow flows are bit-for-bit identical.

### 2. Make cache coverage-aware
Rework `_cachedForDay(lat, lon, day)` to return the most recent snapshot whose forecast series *covers* `day`, not the one fetched on `day`. Two ways:

- **(a) Compute coverage at lookup time.** Read recent rows for `(lat, lon)`, parse each `forecastJson` enough to find first/last sample timestamps, pick the most recent that covers `day`. Cheap (cache rows are sparse), no schema change.
- **(b) Store coverage window in the row.** Add `coverageStart` and `coverageEnd` columns to `WeatherSnapshots`. Drift schema bump to v6. Query becomes a clean `WHERE coverageStart <= day AND coverageEnd >= day`.

Recommend (b): cheap migration (two nullable `DateTime` columns; backfill from existing rows by parsing `forecastJson` once during the migration; new writes populate inline). Coordinate v6 with the historical-location-override plan's own v6 migration so we ship one bump.

Also drop the `!isBackfill` clause on line 38 — once the cache is coverage-aware, backfill lookups are first-class. Keep `!forceRefresh` so callers can still force a network hit when they want to.

### 3. Orchestrator uses the new contract
`BulkBackfillOrchestrator._run`:
```dart
await weatherSource.fetch(
  lat: loc.lat,
  lon: loc.lon,
  now: now,
  forceRefresh: true,
  pastDays: window.inDays.clamp(1, 90),
);
```
Per-day loop unchanged — `ContextBuilder.build` calls `weatherSource.fetch(now: endOfDay(day), ...)`. With §2 in place, those lookups hit the primed row (no network) and slice it. The "single network round trip" invariant becomes true.

### 4. Show progress strip on `_NotEligible` too
`lib/ui/insights/insights_screen.dart`. Two options:
- Lift `_BackfillProgressStrip` out of `_Body` and render it at `InsightsScreen.build` level above the `eligible.when(...)`. Simpler.
- Add the same strip to `_NotEligible`. Duplicated widget tree.

Recommend the first: one mount point, both eligibility paths benefit. The strip's own null-check still controls visibility.

### 5. Drop the dead `_running` guard
`bulk_backfill_orchestrator.dart`: remove the `_running` field and the wrapper `run` method. The module-level guard in `backfill_provider.dart` is now the single source of truth. Update the orchestrator's public entry to be `_run` renamed back to `run`.

### 6. Integration test for the round-trip count
New: `test/data/bulk_backfill_orchestrator_integration_test.dart` against a real `OpenMeteoWeatherSource` backed by a mocked `http.Client` that records every request. Assert: full 7-day backfill issues exactly one forecast + one air-quality request (the same `pastDays=7` prime). Use the same in-memory Drift DB pattern as the existing unit tests; pre-seed nothing.

The existing unit tests stay — they exercise orchestrator logic. The new integration test exercises the cache contract.

## Edge Cases

- **Existing v5 cache rows have no coverage columns.** Migration must parse `forecastJson` once and populate `coverageStart`/`coverageEnd`. If parsing fails (corrupt row), leave nulls and let the lookup query treat nulls as "doesn't cover" — that row gets re-fetched naturally.
- **`pastDays` mismatch between prime and per-day lookup.** If the orchestrator primes with `pastDays = 90` but a per-day call asks for `endOfDay(day)` 95 days ago, the lookup must return null and fall through to a fresh fetch. The coverage-keyed query handles this naturally — no special case.
- **Concurrent prime + Today refresh.** Today's normal `RiskAssessmentNotifier.refresh` calls `weatherSource.fetch` with no `pastDays`. With (b)'s schema, both writes coexist — the cache holds the most recently-fetched row per coverage; the lookup picks the freshest covering row. No collision.
- **Migration on installs with no `WeatherSnapshots` rows.** Trivial — backfill loop processes zero rows, columns added empty. No-op.

## Verification

- **Unit (existing):** all 4 `BulkBackfillOrchestrator` tests still pass; assertions unchanged. Add one new case: prime with `pastDays = window.inDays`, then run, assert `forceRefreshCount == 1` and `weather.fetchCount == 1` (the fake has no cache so this is meaningful only after wiring the orchestrator's lookup; but with the contract change the fake never sees per-day calls since they hit the cache — assert via a coverage-aware fake that holds the primed row).
- **Unit (new):** `OpenMeteoWeatherSource._cachedForDay` returns the right row for in-coverage, in-window, and out-of-coverage lookups. Migration v5→v6 backfills `coverageStart`/`coverageEnd` from a seeded row.
- **Integration (new):** mocked-HTTP test asserts ≤2 outbound requests (1 forecast + 1 air quality) for a full 7-day backfill.
- **Manual:** wipe `weather_snapshots`, finish onboarding, watch DevTools network panel — expect 2 calls during backfill, not ~180. Watch Insights — progress strip visible immediately even with zero attacks.

## Sequencing

Single PR. Order of edits:
1. Schema v6 + migration backfill.
2. `WeatherSource.fetch` new param + `OpenMeteoWeatherSource` coverage-aware lookup.
3. Orchestrator passes `pastDays`; drop inner `_running`.
4. Progress strip hoisted in `InsightsScreen`.
5. New integration test.

Tag the schema bump with a note that the location-override plan's v6 will need to merge with this one (or ship its own v7 if this lands first).
