# Plan: Historical Location Override and Date-Anchored Context

## Objective
Allow users to change the location for a specific day in the past through the heatmap view. This allows accurate retrospective weather data gathering when a user travels. When the location is changed, the app must re-fetch weather for that location and day, recalculate the risk assessment, and update the correlation insights.

## Architecture & Implementation Steps

### 1. Database Schema Update (`DayLocationOverrides`)
Add a new table in the Drift database to persist day-specific location overrides.
- **Columns**:
  - `day`: `DateTimeColumn` (UTC midnight, primary key)
  - `lat`: `RealColumn`
  - `lon`: `RealColumn`
  - `displayName`: `TextColumn` (for UI presentation)
- Increment `schemaVersion` to 5 and handle the migration (`createTable`).
- Add a new `LocationOverridesRepo` to provide a clean interface for reading/writing these overrides.

### 2. Refactor `ContextBuilder` for Date-Anchored Context
Currently, `ContextBuilder.build()` passes `now` to the `WeatherSource` and ignores `targetDate` when fetching location.
- **Change**: Pass `targetDate` (instead of `now`) as the requested time for weather. 
- **Change**: Query `LocationOverridesRepo` for `targetDate`. If a record exists, use its `lat/lon`. If not, fall back to `location.current()`.
- **Note**: `OpenMeteoWeatherSource` already supports historical fetching via the `pastDays` parameter (up to 90 days), so modifying `ContextBuilder` to pass the `targetDate` will naturally route historical requests correctly.

### 3. Add Location UI to `DayDetailSheet`
Update the `DayDetailSheet` (opened from the Calendar Heatmap) to expose the location context.
- **UI Update**: Add a row below the date title showing the location used for that day (e.g., "📍 San Francisco, CA" or "📍 Auto (GPS)").
- **Interaction**: Add an edit pencil next to the location. Tapping it opens the existing `_LocationSearchDialog` from the Settings screen (we can refactor this dialog to a shared widget).
- **State**: Ensure the `DayDetailSheet` reacts to changes in location by watching a new provider for the day's overridden location.

### 4. Re-evaluating Risk and Triggering Backfill
When the user selects a new location for a specific day in the `DayDetailSheet`:
1. Save the new `DayLocationOverride` via the repository.
2. Clear any existing `WeatherSnapshot` for that specific day, `lat`, and `lon` to force a fresh network request.
3. Call a backfill function (e.g., `RiskEngineOrchestrator.recalculateForDay(day)`) which:
   - Invokes `ContextBuilder` for that `targetDate` (which will now fetch the new weather coordinates).
   - Runs the `RiskEngine` to produce a new `RiskAssessment`.
   - Overwrites the existing `RiskAssessment` in the database.
4. Invalidate the `correlationResultsProvider` so the insights engine recalculates trigger hits/misses based on the newly acquired historical weather data.

## Edge Cases & Considerations
- **Open-Meteo Limits**: The standard forecast API's `pastDays` goes up to 90 days. For overrides older than 90 days, we'd need to use the Archive API (`archive-api.open-meteo.com`). For this feature, clamping the override UI or falling back gracefully to the Archive API if the date is >90 days old is required.
- **Provider Invalidations**: Changing a past day's location will change its `RiskAssessment`, which will change the `dayAssessmentProvider` and the global `correlationResultsProvider`. We must ensure these are thoroughly invalidated.
