# Plan: Historical Location Override and Date-Anchored Context

## Objective
Let the user attach a specific location to a past day from the heatmap's `DayDetailSheet` so the app can re-fetch weather for the correct place (typically because they were travelling) and recompute that day's `RiskAssessment` and the global correlation insights.

## Current State
- `ContextBuilder.build(now, target)` at `lib/data/context_builder.dart:34` calls `location.current()` and then `weather.fetch(now: now)`, so `target` is only used to scope the eventual `EvaluationContext` — both location and weather are anchored to wall-clock "now".
- `OpenMeteoUrlBuilder.forecast` clamps `past_days` to `[1, 90]` (`lib/data/sources/open_meteo/open_meteo_url_builder.dart`). Anything older needs the Archive API.
- `WeatherSnapshots` (`lib/data/database.dart:25`) stores one row per fetch keyed by `(lat, lon, fetchedAt)` — not per day. Invalidation must operate at that granularity, not "the snapshot for day X".
- `_LocationSearchDialog` exists privately inside `lib/ui/settings/settings_screen.dart:280`; the heatmap sheet has no location concept today.
- Drift `schemaVersion = 4`. Bumping to 5 here must be coordinated with the bulk-backfill plan (which also wants to add a `(targetDate, horizon)` unique index on `RiskAssessments`) so we ship a single v5 migration.

## Architecture & Implementation

### 1. Drift schema (`schemaVersion: 5`)
Add to `lib/data/database.dart`:

```dart
class DayLocationOverrides extends Table {
  DateTimeColumn get day => dateTime()();          // UTC midnight
  RealColumn get lat => real()();
  RealColumn get lon => real()();
  TextColumn get displayName => text()();
  DateTimeColumn get setAt => dateTime()();        // for audit / future "revert"
  @override
  Set<Column> get primaryKey => {day};
}
```

Wire into `@DriftDatabase(tables: [...])`. In `MigrationStrategy.onUpgrade` add:

```dart
if (from < 5) {
  await m.createTable(dayLocationOverrides);
  // Co-located with bulk-backfill: add unique index on risk_assessments(target_date, horizon)
}
```

### 2. New repo: `LocationOverridesRepo`
`lib/data/repos/location_overrides_repo.dart`:

```dart
class LocationOverridesRepo {
  Future<UserLocation?> forDay(DateTime day);     // null if no override
  Future<void> set(DateTime day, UserLocation loc, String displayName);
  Future<void> clear(DateTime day);
  Stream<Map<DateTime, UserLocation>> watchAll();  // for heatmap badges
}
```

Day key is normalized to UTC midnight on both write and read.

### 3. Date-anchored `ContextBuilder`
Change `build` to use `target` for both location and weather fetch:

```dart
final loc = await overrides.forDay(target) ?? await location.current();
weatherSnap = await weather.fetch(lat: loc.lat, lon: loc.lon, now: target);
```

`OpenMeteoWeatherSource.fetch` already computes `pastDays` from `(nowUtc - target).inDays`, so passing `target` as `now` routes the request to the right historical slice. Two adjustments:

- **Coverage check.** When the computed `pastDays > 90`, fall back to the Archive API rather than silently clamping. Either inject an `ArchiveWeatherSource` and dispatch in `OpenMeteoWeatherSource.fetch` based on `diffDays`, or expose a separate `WeatherSource` and let `ContextBuilder` pick. Recommend in-source dispatch so callers stay simple.
- **Cache key correctness.** The cache currently keys on `(lat, lon, fetchedAt)` and picks the most recent row whose `fetchedAt` falls in the requested span. After this change the relevant "span" is around `target`, not "now". Update the cache lookup to: "most recent row for `(lat, lon)` whose forecast series covers `target`." Practically: query rows by `(lat, lon)` and pick one whose `pastDays`-derived window includes `target`. If none, fetch.

Inject `LocationOverridesRepo` into `ContextBuilder`'s constructor and the provider that wires it.

### 4. `DayDetailSheet` UI
- Show a "📍 {displayName}" row under the date title, defaulting to "Auto (GPS)" when no override exists.
- Tap → existing geocoder-backed search. Extract `_LocationSearchDialog` from `lib/ui/settings/settings_screen.dart` into a shared widget at `lib/ui/common/location_search_dialog.dart` and import from both call sites.
- On pick: write override, then trigger §5.
- Add a small "Use auto" link when an override exists, which calls `LocationOverridesRepo.clear(day)` and triggers §5.

### 5. Recompute pipeline
Add `RiskEngineOrchestrator.recalculateForDay(DateTime day)` (or extend the existing `RiskAssessmentNotifier.backfill`):
1. Persist the override via `LocationOverridesRepo`.
2. Force a fresh weather fetch by invoking the source with `forceRefresh: true` (the param added in the bulk-backfill plan) for the new `(lat, lon)`. Do NOT delete the old row — other days may still be using it.
3. `ctx = await contextBuilder.build(target: day, now: endOfDay(day))`.
4. `engine.evaluate(ctx, cfg, horizon: today)` → upsert into `RiskAssessments` (relies on the v5 unique index; see bulk-backfill plan).
5. Invalidate: `dayAssessmentProvider(day)`, `correlationResultsProvider`, `recentAttacksProvider`.

### 6. Heatmap affordance
On the heatmap itself, render a tiny ✈️/📍 badge on cells whose `day` appears in `LocationOverridesRepo.watchAll()`. Cheap signal that "this day used a different location."

## Edge Cases
- **Date >90 days old.** Route to Archive API per §3. If Archive returns nothing, show "Weather unavailable for this date" in the sheet and skip the recompute (but still persist the override — the user may later use it for other purposes).
- **Same-location override.** If the user picks a place within ~5 km of `location.current()` for today, no-op the recompute.
- **Removing an override.** Same recompute path with `loc = location.current()`.
- **Provider invalidation cascade.** A single override mutates one `RiskAssessment`, but it shifts every downstream correlation stat. Make sure the orchestrator awaits the save before invalidating, otherwise `correlationResultsProvider` reads stale data.
- **Concurrent edits.** Guard `recalculateForDay` with a per-day mutex so rapid taps don't race.

## Verification
- Unit: `LocationOverridesRepo` round-trip; `ContextBuilder` resolves to override over `location.current()`; `OpenMeteoWeatherSource` chooses Archive when `diffDays > 90`.
- Widget: `DayDetailSheet` shows override location and edit affordance; picking a new location triggers recompute via a fake orchestrator.
- Manual: log a past attack, then change its location to somewhere with very different weather (e.g., desert vs. coast). Verify the day's contributors change and the correlation card numbers shift.
