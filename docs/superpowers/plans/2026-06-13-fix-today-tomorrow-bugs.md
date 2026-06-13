# Plan: Fix two Today/Tomorrow bugs

## Context

Two user-visible bugs on the Today flow:

1. **Tomorrow detail screen shows today's date.** Title formats `targetDate.toLocal()`, where `targetDate` is built in `lib/state/risk_assessment_provider.dart:82` as `DateTime.utc(now.year, now.month, now.day).add(Duration(days: 1))`. `now` is local, so `(year, month, day)` is the *local* date — wrapping it in `DateTime.utc(...)` then back to local in negative-UTC timezones (Americas) shifts the displayed instant backwards across the local-midnight boundary, so `DateFormat('EEE, MMM d')` prints today, not tomorrow. The tile copy is just "Tomorrow:" so the bug only surfaces on the detail screen.

2. **Android: Today screen still shows the "Set up your personal risk profile" onboarding card after granting location during onboarding.** The card renders when `RiskAssessment.isOnboarding` is true, which means every contributor has `confidence == 0` (`packages/domain/lib/src/types/risk_assessment.dart:49`). All weather-driven contributors collapse to zero confidence when `EvaluationContext.weather == null`, which happens when `location.current()` returns null. On Android, `GeolocatorLocationSource.current()` (`lib/data/sources/geolocator_location_source.dart`) calls `Geolocator.getCurrentPosition(LocationAccuracy.low)` with no `timeLimit` and no `getLastKnownPosition()` fast-path — if location services are off, the device has no recent fix, or the first fix is slow, it throws and the silent catch-all falls back to `ManualLocationSource`, which returns null on a fresh install. Result: weather is null, all contributors confidence-zero, `isOnboarding == true`, and the user sees the setup card. The `AsyncNotifierProvider` is computed once and cached, so nothing recovers automatically.

User-reported repro for Bug 2: granted location during onboarding, then Today still shows the setup card. Scope is intentionally narrow — fix the two symptoms with minimal, well-bounded changes.

## Changes

### Fix 1 — Tomorrow detail screen date

**File:** `lib/ui/today/tomorrow_detail_screen.dart`

Stop deriving the title date from `targetDate.toLocal()`. Compute the display date directly from local `DateTime.now()`:

```dart
final dateStr = DateFormat('EEE, MMM d')
    .format(DateTime.now().add(const Duration(days: 1)));
```

Remove the `ass.asData?.value.targetDate.toLocal()` line and the `if (dateStr.isNotEmpty)` guard — the date is always available now, so the title row is unconditional. This matches how `lib/ui/today/today_screen.dart:24` derives its date string (local `DateTime.now()`).

Rationale for not touching `risk_assessment_provider.dart`: `targetDate` is also persisted via `assessmentRepoProvider.save(ass)` and consumed elsewhere (CLI, tests). Changing the stored value is out of scope for a UI date-label fix.

### Fix 2 — Android Today onboarding card after permission grant

Two changes, both small:

**File: `lib/data/sources/geolocator_location_source.dart`**

Harden `current()` so a missing first fix does not cascade to null:

- Before `getCurrentPosition`, try `Geolocator.getLastKnownPosition()` and return it if non-null. This is essentially instant and covers most fresh-permission cases on Android.
- Pass a `timeLimit` (e.g. 10 seconds) to `getCurrentPosition` so a stalled GPS fix doesn't silently degrade to fallback after a long wait.
- Keep the existing silent fallback behavior on throw.

**File: `lib/ui/today/today_screen.dart`**

When the cached assessment is `isOnboarding == true` but location permission is now granted, recompute on resume. Convert `TodayScreen` to a `ConsumerStatefulWidget` (or wrap with a small lifecycle helper) that observes `AppLifecycleState.resumed`, and on resume:

- Read `permissionServiceProvider.locationGranted` (cheap, in-memory).
- If granted and the current `riskAssessmentProvider` value has `isOnboarding == true`, call `ref.read(riskAssessmentProvider.notifier).refresh()` and the same on `tomorrowRiskAssessmentProvider`.

This also handles the secondary path of the user toggling location in OS Settings and returning — even though the reported repro is in-onboarding, the resume hook is the right place to put the safety net (and is small).

Do **not** invalidate the providers from `OnboardingScreen._finish` — the provider is first watched by `TodayScreen` after navigation, so the in-onboarding repro is fixed by the `GeolocatorLocationSource` hardening alone; the lifecycle hook is belt-and-braces for resume-after-Settings.

### Reused / referenced code

- `lib/services/permission_service.dart` — already exposes `locationGranted`; no change.
- `lib/state/providers.dart:50–55` — provider wiring stays as-is.
- `lib/state/risk_assessment_provider.dart` — `refresh()` already exists on both notifiers; reuse it from the lifecycle hook.

## Verification

1. **Bug 1 (manual):** Set device timezone to America/Los_Angeles, run `flutter run`, open Today → tap the Tomorrow tile. Title shows the next calendar day in local time. Repeat with Europe/Berlin (positive offset) to confirm no regression.
2. **Bug 1 (test):** In `test/ui/today/tomorrow_detail_screen_test.dart` (the existing widget test added in `0f2bbca`), add an assertion that the title contains a date string equal to `DateFormat('EEE, MMM d').format(DateTime.now().add(const Duration(days: 1)))`.
3. **Bug 2 (manual on Android):** Fresh install on an Android device (or emulator with location services *off* to reliably reproduce). Complete onboarding, grant location when prompted. Today screen shows the gauge, not the setup card. Repeat with location services *on* but no recent fix.
4. **Bug 2 (manual lifecycle):** Deny location during onboarding → onboarding card shows. Background app → grant location in OS Settings → return. Today reflows to the gauge within a frame.
5. **Run existing suites:**
   - `flutter test` (project root) — `test/ui/insights/insights_screen_test.dart`, `test/state/risk_assessment_provider_test.dart`, and any tomorrow-tile tests must still pass.
   - `cd packages/domain && dart test` — `isOnboarding` semantics unchanged.

## Out of scope

- Changing `RiskAssessment.targetDate`'s storage semantics or UTC contract.
- Reworking `PermissionService` into a reactive stream (overkill for this bug).
- Adding a separate health-permission onboarding step.

## Addendum (2026-06-13): related fixes folded into this branch

The original "narrow" scope (the two bugs above) grew once the team started running the app end-to-end on real devices and found adjacent issues in the same code paths. The work below was added to the same branch:

### Onboarding race condition
**File:** `lib/ui/onboarding/onboarding_screen.dart` (+ `test/ui/onboarding/onboarding_screen_test.dart`)

After `markOnboardingCompletedProvider()`, `_finish` now awaits `ref.read(onboardingCompletedProvider.future)` before navigating. Without this, the go_router redirect saw the stale `false` value and bounced the user back to `/onboarding`. The button is also gated by an `_isLoading` flag with an inline spinner so the user can't double-tap. `requestLocation()` is wrapped in `try/on Exception` — permission failures are non-fatal because the Today lifecycle hook re-fetches once a fix arrives.

### "No Data" card on Today
**File:** `lib/ui/today/today_screen.dart`

When `permissionServiceProvider.locationGranted == true` but the cached assessment is still `isOnboarding == true` (weather null, all contributors zero-confidence), we now render a `_NoDataCard` ("Data unavailable — open Settings") instead of the "Set up your risk profile" onboarding card. The original plan said the Geolocator hardening alone would fix this; in practice some users still end up without a fix (location services off device-wide), and the onboarding card is misleading in that state.

### Default units → Fahrenheit / mmHg
**File:** `lib/state/settings_provider.dart`

Defaults flipped to °F and mmHg because the initial user cohort is US-based. Existing users with a stored preference are unaffected; users with no stored preference will see their units change on next launch.

### Past-day weather cache bypass + lookback padding
**File:** `lib/data/sources/open_meteo/open_meteo_weather_source.dart`, `lib/data/sources/open_meteo/open_meteo_url_builder.dart`

Two changes to support reliable historical backfill (also a prerequisite for the bulk-historical-backfill plan dated the same day):
- Bypass the in-process cache for requested days older than yesterday so a previously-bad cache entry can self-heal on a re-fetch. The boundary is day-truncated UTC (`yesterdayStart`), not a wall-clock offset, so it doesn't drift across local noon.
- Pad `pastDays` by 2 days on both the forecast and air-quality calls because contributor lookback windows (pressure drop, temp swing) need up to 48 h before the target day.

### Auto-dispose for day providers
**File:** `lib/state/providers.dart`

`dayAssessmentProvider` and `dayAttacksProvider` are now `autoDispose` family providers. Without this, an old cached value lingered after a backfill ran and the heatmap kept showing stale data.

### "Clear all data" in Settings + reset-to-auto-location button
**Files:** `lib/ui/settings/settings_screen.dart`, `lib/data/database.dart`

- Added a "Danger Zone" → "Clear all data" entry that calls `AppDatabase.clearAllData()` (wipes journal, assessments, weather snapshots, settings), invalidates the relevant providers, awaits the new `onboardingCompletedProvider` future, and navigates to `/onboarding`. Colors use `colorScheme.error` (not hardcoded red) so the palette stays theme-aware.
- The manual-location row now exposes an explicit "Reset to auto location" button instead of an unlabelled `Icons.clear` chip.

### Settings icon on Insights
**File:** `lib/ui/insights/insights_screen.dart`

Adds an `IconButton(Icons.settings)` in the Insights AppBar so settings is reachable from more than just the Today screen.

### Verification (addendum)

Beyond the verification steps above, also:
- Fresh install → onboarding → grant location → verify the gauge appears (not the No Data card or the "Set up your risk profile" card).
- Fresh install → onboarding → **deny** location → verify Today shows the No Data card with an "Open Settings" affordance.
- Backfill a past day (log a migraine for 30 days ago) → verify the heatmap updates the same frame (autoDispose) and the weather row for that day populates (cache bypass).
- Settings → Danger Zone → Clear all data → confirm → verify the app navigates to onboarding with a fresh DB.
