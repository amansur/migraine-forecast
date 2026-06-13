# Implementation Plan — Exports, Intraday Pressure Swings, and Comfort Mode

This plan details the design and implementation for three selected improvements:
1. **JSON Data Export:** Build a utility to serialize logged attacks, settings, and journal entries, allowing users to copy to their clipboard or save to their device's Documents folder.
2. **Intraday Pressure Swings:** Add a new trigger module (`intraday_pressure_swing`) that calculates hourly pressure volatility (accumulated absolute barometric movement) within a rolling window to detect rapid changes that net delta checks miss.
3. **Comfort Mode (Photophobia Theme):** Implement a restful, ultra-low-contrast warm dark theme. When a user has an active migraine in progress (or is on the Log Attack screen), the app will automatically shift into Comfort Mode to prevent eye strain.

---

## User Review Required

> [!IMPORTANT]
> **Comfort Mode Triggering:**
> - When an attack is marked "Still in progress" (where `attacks.inProgress == true` in the DB), the entire app will automatically shift into Comfort Mode.
> - While a user is on the [LogAttackScreen](file:///Users/amansur/.gemini/antigravity/worktrees/migraine-weatherr/app-improvement-feedback-analysis/lib/ui/log/log_attack_screen.dart) inputting a new attack, the screen will use the Comfort Mode styling by default to ensure they aren't blinded by white light when trying to log their pain.
> - We will add a toggle in Settings: "Auto Comfort Mode during attacks" (defaults to enabled).
>
> **Intraday Pressure Swing Metric:**
> - Measured as the sum of absolute changes between consecutive hourly pressure samples in the window:
>   $$\text{Volatility} = \sum_{t=1}^{N} |P_t - P_{t-1}|$$
> - This distinguishes a stable pressure day from a highly volatile day where the pressure drops, rebounds, and drops again (net drop = 0, but total swings are high).
> - We will add a config parameter `"threshold_volatility_hpa": 10.0` in the rules config.

---

## Proposed Changes

### Domain Package

#### [MODIFY] [weather.dart](file:///Users/amansur/.gemini/antigravity/worktrees/migraine-weatherr/app-improvement-feedback-analysis/packages/domain/lib/src/types/weather.dart)
- Add the volatility calculator to `WeatherSeries`:
  ```dart
  double? hourlyPressureVolatilityAround(
    DateTime anchor,
    Duration window, {
    required DateTime now,
  }) {
    final inWindow = _around(anchor, window, now).toList();
    if (inWindow.length < 2) return null;
    double totalDiff = 0;
    for (int i = 1; i < inWindow.length; i++) {
      totalDiff += (inWindow[i].pressureMsl - inWindow[i - 1].pressureMsl).abs();
    }
    return totalDiff;
  }
  ```

#### [NEW] [intraday_pressure_swing.dart](file:///Users/amansur/.gemini/antigravity/worktrees/migraine-weatherr/app-improvement-feedback-analysis/packages/domain/lib/src/modules/intraday_pressure_swing.dart)
- Implement `IntradayPressureSwingModule` evaluating weather data against `threshold_volatility_hpa` and `lookback_hours`. Returns explanation strings like: *"Pressure swung 12.4 hPa (accumulated) in last 24h"*.

#### [MODIFY] [domain.dart](file:///Users/amansur/.gemini/antigravity/worktrees/migraine-weatherr/app-improvement-feedback-analysis/packages/domain/lib/domain.dart)
- Export `src/modules/intraday_pressure_swing.dart`.

#### [MODIFY] [rules_config_v1.json](file:///Users/amansur/.gemini/antigravity/worktrees/migraine-weatherr/app-improvement-feedback-analysis/assets/rules_config_v1.json)
- Add rules configuration under `modules`:
  ```json
  "intraday_pressure_swing": { "enabled": true, "weight_max": 12, "params": { "threshold_volatility_hpa": 10.0, "lookback_hours": 24 } }
  ```

---

### App Layer (State & UI)

#### [MODIFY] [providers.dart](file:///Users/amansur/.gemini/antigravity/worktrees/migraine-weatherr/app-improvement-feedback-analysis/lib/state/providers.dart)
- Register `IntradayPressureSwingModule()` in the `riskEngineProvider`.
- Expose `activeAttackProvider` (StreamProvider returning `true` if any attack is in-progress):
  ```dart
  final activeAttackProvider = StreamProvider<bool>((ref) {
    final db = ref.watch(databaseProvider);
    final query = db.select(db.attacks)..where((t) => t.inProgress.equals(true));
    return query.watch().map((rows) => rows.isNotEmpty);
  });
  ```

#### [MODIFY] [correlation_provider.dart](file:///Users/amansur/.gemini/antigravity/worktrees/migraine-weatherr/app-improvement-feedback-analysis/lib/state/correlation_provider.dart)
- Add `'intraday_pressure_swing'` to the list of `_moduleIds` analyzed for correlation statistics.

#### [MODIFY] [theme.dart](file:///Users/amansur/.gemini/antigravity/worktrees/migraine-weatherr/app-improvement-feedback-analysis/lib/app/theme.dart)
- Define a restful dark palette `buildComfortTheme()`:
  - Background: Warm dark charcoal `Color(0xFF232120)`.
  - Surfaces: Low-contrast grey/brown `Color(0xFF2E2C2B)`.
  - Primary text: Soft cream/ivory `Color(0xFFDFD9D0)` (never high-contrast pure white).
  - Primary color: Restful olive-sage `Color(0xFF8B9D88)`.
  - Ink: `Color(0xFF1C1A19)`.

#### [MODIFY] [app.dart](file:///Users/amansur/.gemini/antigravity/worktrees/migraine-weatherr/app-improvement-feedback-analysis/lib/app/app.dart)
- Watch `activeAttackProvider` and settings for auto-comfort.
- If an attack is active, apply `buildComfortTheme()` for `theme` & `darkTheme`.

#### [MODIFY] [settings_screen.dart](file:///Users/amansur/.gemini/antigravity/worktrees/migraine-weatherr/app-improvement-feedback-analysis/lib/ui/settings/settings_screen.dart)
- Add labels and toggles for `intraday_pressure_swing`.
- Under "Display", add a switch for "Auto Comfort Mode during attacks" (persisted via settings key `auto_comfort_mode`).
- Add a "Manage Data" section at the bottom containing:
  - **"Export JSON Data"**: Opens dialog showing options to:
    - *Copy to Clipboard* (copies JSON dump of attacks + journal + settings).
    - *Save to Documents folder* (writes to `migraine_weatherr_export.json` in local documents path using `path_provider`).

---

## Verification Plan

### Automated Tests
- **Domain Tests:**
  - `cd packages/domain`
  - Add test in `packages/domain/test/types/weather_test.dart` for `hourlyPressureVolatilityAround`.
  - Add `packages/domain/test/modules/intraday_pressure_swing_test.dart` to test volatility thresholds, lead times, and evaluations.
  - Verify all domain tests pass: `dart test`.
- **App Tests:**
  - Add database export query test in `database_test.dart`.
  - Add widget test for the Settings Export dialog and Clipboard copying.
  - Verify all app tests pass: `flutter test`.

### Manual Verification
1. Run `flutter run -d macos`.
2. Tap "Log Attack" and toggle "Still in progress" to true. Save the attack.
3. Verify the entire app turns into the warm dark Comfort Mode theme.
4. Go to Settings, turn off the Comfort Mode toggle, and verify the app returns to Sage/Ivory.
5. In Settings, tap "Export JSON Data", choose "Copy to Clipboard", and paste the JSON into a text editor to verify formatting.
6. Trigger the "Save to Documents folder" option and verify the file exists on your system.
