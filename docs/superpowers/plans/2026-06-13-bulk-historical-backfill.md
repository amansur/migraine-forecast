# Plan: Bulk Historical Data Backfill

## Objective
After onboarding, populate `RiskAssessment` rows for every calendar day in the user's heatmap window (target: last 90 days) so the correlation engine has both "fired" and "not fired" days from day one. Today, only days with a logged attack get backfilled (`RiskAssessmentNotifier.backfill` at `lib/state/risk_assessment_provider.dart:22`), which leaves the Wilson-interval correlation analyzer starved of denominator data until the user has used the app for weeks.

## Current State
- `RiskAssessmentNotifier.backfill(target)` builds an `EvaluationContext` for `target` with `now = endOfDay(target)` and writes a single `RiskAssessment(backfilled: true)`.
- `RiskAssessments` has no uniqueness on `(targetDate, horizon)` (`lib/data/database.dart:52`) — repeat backfills append duplicate rows. Any orchestrator must dedupe or upsert.
- `OpenMeteoWeatherSource.fetch` (`lib/data/sources/open_meteo/open_meteo_weather_source.dart`) already requests `past_days` clamped to `[1, 90]` and caches the entire response as ONE row in the `WeatherSnapshots` table keyed by `(lat, lon, fetchedAt)`. The `WeatherSeries` produced from that row holds every hourly sample in the window, so a single network round trip can cover the whole 90-day backfill — there is no per-day row in the cache to "insert 90 of".
- `ContextBuilder.build` currently calls `location.current()` regardless of `target`, so backfilled days inherit *today's* location. This is fine for the v1 backfill if the user hasn't travelled, and is fixed properly by the sibling `historical-location-override` plan.

## Architecture & Implementation

### 1. New service: `BulkBackfillOrchestrator`
Add `lib/data/bulk_backfill_orchestrator.dart`. Single entry point:

```dart
Future<BackfillReport> run({
  Duration window = const Duration(days: 90),
  void Function(int done, int total)? onProgress,
});
```

Steps inside `run`:
1. Compute the target day set: every UTC midnight in `[now - window, now)`.
2. Read existing `RiskAssessments` where `horizon = 'today'` and `targetDate >= cutoff`. Subtract from target set → `missingDays`.
3. Prime the weather cache with **one** call: `weatherSource.fetch(lat, lon, now: DateTime.now())` with a `pastDays` value covering the window. Because `OpenMeteoWeatherSource` already issues `past_days = clamp(diffDays + 2, 1, 90)`, we just need to ensure its cache miss path is hit (e.g., pass `forceRefresh: true`, see §2). One cache row is sufficient — the orchestrator never touches `WeatherSnapshots` directly.
4. For each `day` in `missingDays`, in chronological order:
   - `ctx = await contextBuilder.build(target: day, now: endOfDay(day))`. With the cache primed, this is a pure in-memory slice of the `WeatherSeries`.
   - `raw = riskEngine.evaluate(ctx, cfg, horizon: RiskHorizon.today)`.
   - `assessmentRepo.save(raw.copyWith(backfilled: true))`.
   - Call `onProgress(++done, missingDays.length)`.
5. Return `BackfillReport(daysProcessed, daysSkipped, weatherFetchSucceeded, firstError?)`.

### 2. Make the weather cache primeable
`OpenMeteoWeatherSource.fetch` short-circuits to the most recent cached row when one exists within its TTL. For the orchestrator we want a single guaranteed fresh fetch, then *all* subsequent `ContextBuilder.build` calls in the loop should reuse that one row.

Add an optional `bool forceRefresh = false` param to `WeatherSource.fetch` (`lib/data/sources/weather_source.dart`) and plumb it through `OpenMeteoWeatherSource`. The orchestrator passes `true` on its prime call; the per-day loop relies on the now-warm cache via the normal `ContextBuilder` path. (Do not change the cache-key model — keep one row per fetch.)

### 3. Idempotency on `RiskAssessments`
Without a unique index, re-running backfill duplicates rows. Two options, pick (a):

- (a) **Upsert by (targetDate, horizon).** Add a unique index in a new schema migration (`schemaVersion: 4 → 5`, coordinate with the historical-location-override plan which also bumps to 5). Change `AssessmentRepo.save` to `INSERT ... ON CONFLICT(targetDate, horizon) DO UPDATE`.
- (b) Skip-if-present in the orchestrator only. Cheaper, but leaves the duplication footgun for other callers.

Recommend (a). Coordinate schema bump with the location-override plan so we ship exactly one v5 migration.

### 4. Trigger points
- **Post-onboarding.** In the onboarding completion handler, fire-and-forget `BulkBackfillOrchestrator.run()` after permissions are granted and `location.current()` has resolved at least once. Stash the running future on a Riverpod provider so the UI can subscribe.
- **Insights screen indicator.** Add a thin progress strip ("Building history… 42 / 90 days") above the heatmap while `backfillProgressProvider` is non-null. Hide when complete.
- **On completion** invalidate `correlationResultsProvider`, `recentAttacksProvider`, and `dayAssessmentProvider` so the heatmap and correlation cards redraw against the dense dataset.

### 5. Failure modes
- If the prime weather fetch fails (network, rate limit, location unknown), the orchestrator writes nothing and surfaces the error via the report; UI shows "History unavailable — will retry on next launch."
- If a single day's `ContextBuilder.build` throws, log and continue — partial backfill is still useful.
- Cap concurrent runs with a simple `bool _running` guard so a fast settings toggle can't double-launch.

## Edge Cases
- **Health data window.** Apple Health / Health Connect support 30-day queries; `HealthSource.recentMetrics(window: 30d)` is invoked per-day inside `ContextBuilder`, which means for days >30 ago, health-driven modules naturally degrade (no sleep deficit / HRV signal). That's correct behavior — call it out in the report metadata so we don't mistake it for a bug.
- **Open-Meteo limits.** `past_days` maxes at 90. For windows >90 days, fall back to the Archive API (`archive-api.open-meteo.com/v1/archive`) — out of scope for v1, leave a TODO in the orchestrator.
- **Location drift.** v1 uses today's location for every backfilled day. Document this limitation; the override feature is the proper fix.
- **Time zones.** All day boundaries computed as UTC midnight to match how the heatmap and `RiskAssessments.targetDate` already key data. Do not introduce local-tz day math here.

## Verification
- Unit: `BulkBackfillOrchestrator` against a fake `WeatherSource` + in-memory DB. Cases: empty DB → 90 rows; half-full DB → only gaps filled; weather fetch fails → no rows written, report flags error; repeat run on full DB → zero writes.
- Integration: run on a real device with seeded attacks; verify heatmap density and that Wilson intervals on the correlation cards tighten visibly.
