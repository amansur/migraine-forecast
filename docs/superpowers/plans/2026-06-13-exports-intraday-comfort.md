# Implementation Plan — Exports, Intraday Pressure Swings, and Comfort Mode

Three independent improvements bundled because they touch the same review surface but ship separately:

1. **JSON Data Export** — serialize attacks, journal entries, settings, and user trigger flags; copy to clipboard or write to the device's Documents folder.
2. **Intraday Pressure Swing trigger module** — sum of absolute hourly pressure changes within a rolling window, to catch volatile days the net-delta `pressure_drop` module misses.
3. **Comfort Mode (photophobia theme)** — warm low-contrast dark palette, auto-applied while an attack is in progress or the user is on `LogAttackScreen`.

All paths below are relative to the repo root `/Users/amansur/projects/migraine-forecast/`. (Earlier draft of this plan referenced `~/.gemini/antigravity/worktrees/migraine-weatherr/...` — that worktree is gone and the repo has been renamed `migraine-weatherr` → `migraine-forecast`.)

---

## Decisions to confirm before coding

> **Comfort Mode triggering**
> - When `attacks.inProgress == true` for any row, the whole app shifts into Comfort Mode.
> - On `lib/ui/log/log_attack_screen.dart`, Comfort Mode is the default regardless of global state.
> - Settings toggle `auto_comfort_mode` (default: on) lets users opt out of the global behavior; the `LogAttackScreen` default stays on regardless.

> **Intraday Pressure Swing metric**
> Volatility = Σ |P_t − P_{t-1}| over consecutive hourly samples in the lookback window. Distinguishes "drop-rebound-drop" days (net ≈ 0, swing high) from genuinely flat days.
> Config: `"threshold_volatility_hpa": 10.0`, `"lookback_hours": 24`.

> **Export scope**
> Export user-generated inputs only: `attacks`, `journal_entries`, `settings`, `user_trigger_flags`. Skip derived data (`risk_assessments`, `weather_snapshots`, `baselines_kv`) — those can be recomputed from inputs. Include a top-level `schema_version` and `app_version` for future importers.

---

## Domain package

### [MODIFY] `packages/domain/lib/src/types/weather.dart`
Add to `WeatherSeries`:

```dart
double? hourlyPressureVolatilityAround(
  DateTime anchor,
  Duration window, {
  required DateTime now,
}) {
  final inWindow = _around(anchor, window, now).toList();
  if (inWindow.length < 2) return null;
  double total = 0;
  for (int i = 1; i < inWindow.length; i++) {
    total += (inWindow[i].pressureMsl - inWindow[i - 1].pressureMsl).abs();
  }
  return total;
}
```

(Uses the existing `_around` helper, matching `maxPressureDropAround`'s signature.)

### [NEW] `packages/domain/lib/src/modules/intraday_pressure_swing.dart`
`IntradayPressureSwingModule implements TriggerModule`. Reads `threshold_volatility_hpa` and `lookback_hours` from `params`. Score is linear between 0 and `weight_max` over `[threshold, 2 * threshold]`. Explanation: `"Pressure swung 12.4 hPa (accumulated) in last 24h"`.

### [MODIFY] `packages/domain/lib/domain.dart`
Add `export 'src/modules/intraday_pressure_swing.dart';` alongside the existing module exports.

### [MODIFY] `assets/rules_config_v1.json`
Under `modules`:

```json
"intraday_pressure_swing": {
  "enabled": true,
  "weight_max": 12,
  "params": { "threshold_volatility_hpa": 10.0, "lookback_hours": 24 }
}
```

Bump `config_version` so already-installed clients invalidate cached configs.

---

## App layer

### [MODIFY] `lib/state/providers.dart`
- Register `IntradayPressureSwingModule()` in the `riskEngineProvider` module list.
- Add:

```dart
final activeAttackProvider = StreamProvider<bool>((ref) {
  final db = ref.watch(databaseProvider);
  final q = db.select(db.attacks)..where((t) => t.inProgress.equals(true));
  return q.watch().map((rows) => rows.isNotEmpty);
});
```

### [MODIFY] `lib/state/correlation_provider.dart`
Add `'intraday_pressure_swing'` to `_moduleIds` so it shows up on the correlation cards.

### [MODIFY] `lib/app/theme.dart`
Add `buildComfortTheme()`:

- Background: `Color(0xFF232120)` (warm charcoal)
- Surface: `Color(0xFF2E2C2B)`
- onSurface text: `Color(0xFFDFD9D0)` (soft ivory, never pure white)
- Primary: `Color(0xFF8B9D88)` (olive-sage)
- "Ink"/scaffold under-surface: `Color(0xFF1C1A19)`
- Disable `Material.elevation` shadows that bake in cool tints; use border outlines instead.
- Use the same `TextTheme` shapes as the default dark theme so layout doesn't shift on transition.

### [MODIFY] `lib/app/app.dart`
- Watch `activeAttackProvider` + `settingsRepo.getBool('auto_comfort_mode')`.
- Compute `effectiveComfort = autoComfort && hasActiveAttack`.
- Pass `comfort ? buildComfortTheme() : buildAppTheme()` to both `theme` and `darkTheme` (so system theme cannot override during an attack).
- Animate the theme change with `AnimatedTheme(duration: const Duration(milliseconds: 250))` to avoid a hard flash.

### [MODIFY] `lib/ui/log/log_attack_screen.dart`
Wrap the screen body in a local `Theme(data: buildComfortTheme(), child: ...)` so the screen renders in Comfort Mode regardless of global state. Independent of the `auto_comfort_mode` setting (user must always be able to log without bright light).

### [MODIFY] `lib/ui/settings/settings_screen.dart`
- Under "Display": switch labelled "Auto Comfort Mode during attacks" persisted to settings key `auto_comfort_mode` (default `true`).
- Add module toggle for `intraday_pressure_swing` next to the other trigger toggles.
- New "Manage Data" section with one tile, **"Export JSON Data"**, opening a dialog with two actions:
  - **Copy to Clipboard** → `Clipboard.setData(ClipboardData(text: jsonString))` and a snackbar.
  - **Save to Documents folder** → write to `${(await getApplicationDocumentsDirectory()).path}/migraine_forecast_export_<YYYY-MM-DD>.json` using `path_provider`. Show the resolved path in the success snackbar.

### [NEW] `lib/data/repos/export_repo.dart`
```dart
class ExportRepo {
  Future<String> buildJson({DateTime? now}); // pretty-printed
}
```
Schema:

```json
{
  "schema_version": 1,
  "app_version": "<from package_info_plus>",
  "exported_at": "<ISO8601 UTC>",
  "attacks": [...],
  "journal_entries": [...],
  "settings": [...],
  "user_trigger_flags": [...]
}
```

Serialize `DateTime` as ISO-8601 UTC. Do not include `risk_assessments` or `weather_snapshots`.

---

## Verification

### Automated tests
- **Domain**
  - `packages/domain/test/types/weather_test.dart` — `hourlyPressureVolatilityAround` covers: empty, one sample (null), monotonic rise, oscillating samples, gap-around-anchor.
  - `packages/domain/test/modules/intraday_pressure_swing_test.dart` — below-threshold → 0; at 2× threshold → `weight_max`; missing weather → `DataRequirement.notMet`.
  - `cd packages/domain && dart test`
- **App**
  - `test/data/repos/export_repo_test.dart` — round-trip: seed DB with one attack + two journal entries + a setting; assert JSON shape and that derived tables are absent.
  - `test/state/providers/active_attack_provider_test.dart` — toggling `inProgress` flips the stream.
  - `test/ui/settings/export_dialog_test.dart` — clipboard action calls `Clipboard.setData` with valid JSON.
  - `flutter test`

### Manual verification
1. `flutter run -d macos`.
2. Tap "Log Attack". Verify the screen is in Comfort Mode even though the rest of the app isn't (toggle off "auto_comfort_mode" first to prove the screen-level default).
3. Mark the attack "Still in progress" and save. Confirm the whole app transitions (animated) into Comfort Mode.
4. Toggle "Auto Comfort Mode during attacks" off in Settings; app returns to the regular theme while the attack is still in progress.
5. Settings → Manage Data → Export JSON Data → Copy to Clipboard → paste into a text editor and validate the JSON shape (no `risk_assessments`, has `schema_version`).
6. Same dialog → Save to Documents folder; open the file at the path shown in the snackbar.
7. Seed a synthetic oscillating-pressure day (devtool or a debug button) and confirm `intraday_pressure_swing` shows up as a contributor with a sensible explanation.
