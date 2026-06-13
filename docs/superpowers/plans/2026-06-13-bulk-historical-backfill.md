# Plan: Bulk Historical Data Backfill

## Objective
Automatically query and evaluate risk data (including weather) for all past days shown on the heatmap (e.g., the last 56-90 days), rather than only backfilling a single day when the user logs a past attack. This ensures the correlation engine has a complete dataset of "non-attack" days to accurately calculate baseline hit/miss ratios immediately after the app is installed.

## Current State
Currently, the app **only** backfills a past day if the user explicitly logs a migraine attack for that date (`RiskAssessmentNotifier.backfill`). Days without attacks are not backfilled, meaning the correlation engine lacks the "not fired" days necessary for robust statistical analysis until the user naturally uses the app for several weeks.

## Architecture & Implementation Steps

### 1. Identify Missing Days
Create a `BackfillOrchestrator` service that checks the local database for missing `RiskAssessment` records within the target historical window (e.g., `DateTime.now().subtract(const Duration(days: 90))`).
- Query the `RiskAssessments` table to get a set of all `targetDate`s that already exist.
- Generate a list of all calendar days in the 90-day window.
- The difference between the two lists represents the "gaps" that need backfilling.

### 2. Bulk Weather Fetching
`OpenMeteoWeatherSource` currently uses `OpenMeteoUrlBuilder.forecast(pastDays: N)`, which returns a single JSON payload containing the entire timeseries for the past `N` days.
- **Optimization**: We do *not* need to make 90 separate API calls. We can make a single API call with `pastDays: 90`.
- **Parsing**: Update `OpenMeteoWeatherSource` to slice the returned timeseries into 90 separate `WeatherSnapshot`s (one for each UTC midnight day) and insert all 90 into the `weather_snapshots` Drift table in a single batch transaction.

### 3. Orchestrate the Risk Engine
Once the historical weather data is cached locally, loop through the "gap" days identified in Step 1.
For each missing day:
- Call `ContextBuilder.build(target: day, now: endOfDay)`. Since the weather data is already cached, this will be instantaneous and won't hit the network.
- Run `RiskEngine.evaluate()` using the historical context.
- Save the resulting `RiskAssessment` to the database with `backfilled: true`.

### 4. Triggering the Backfill
- **Onboarding**: Trigger the orchestrator in the background immediately after the user completes the Onboarding flow and grants location/health permissions.
- **Background Task**: Ensure the backfill happens asynchronously so it doesn't block the UI. Show a subtle "Syncing historical data..." indicator on the Insights page if the backfill is still in progress.
- **Invalidation**: Once the bulk backfill completes, invalidate `correlationResultsProvider` and `recentAttacksProvider` to force the Insights screen to redraw the heatmap and correlation cards with the dense historical dataset.

## Edge Cases
- **Health Data**: Apple Health/Health Connect already support querying historical windows (e.g., a 30-day window). The `ContextBuilder` will naturally pull the correct historical window relative to each `targetDate` during the loop.
- **Rate Limits**: By leveraging Open-Meteo's bulk `past_days` payload, we avoid rate-limiting issues that would arise from making 90 separate requests.
