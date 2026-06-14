# Maintenance Batch Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship five corrective items: severity label readability in comfort mode, cycle tracking default OFF, surfaced+extended historical backfill, three `dart analyze` warning cleanups, and `contents: write` on the release workflow.

**Architecture:** Items 1, 2, 4, 5 are localized edits with no migration. Item 3 introduces an Open-Meteo archive-API path in `OpenMeteoWeatherSource`, extends `BackfillReport`, adds a `source` column to `weather_snapshots` (Drift schema v6), and surfaces failed-day counts on Insights via a new "last backfill report" provider that outlives the in-flight progress strip.

**Tech Stack:** Flutter 3.44.1, Dart 3.12.1, Drift, Riverpod, Open-Meteo (forecast + archive + air-quality endpoints), GitHub Actions.

**Sequencing:**
- PR A (tasks 1-8): items 1, 2, 4, 5 — trivial, no migration.
- PR B (tasks 9-17): item 3 — archive API + migration + progress surfacing.

---

## PR A — UX polish, defaults, CI hygiene

### Task 1: Drop redundant Theme wrapper in log-attack screen

**Files:**
- Modify: `lib/ui/log/log_attack_screen.dart:46-114`

- [ ] **Step 1: Write the failing widget test**

Create `test/ui/log/log_attack_screen_comfort_color_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/app/theme.dart';
import 'package:migraine_forecast/ui/log/log_attack_screen.dart';

void main() {
  testWidgets('severity label uses onSurface color from ambient theme', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: buildComfortTheme(),
          home: const LogAttackScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final labelFinder = find.textContaining('Severity:');
    expect(labelFinder, findsOneWidget);

    final BuildContext ctx = tester.element(labelFinder);
    final expected = Theme.of(ctx).colorScheme.onSurface;

    final Text widget = tester.widget(labelFinder);
    final TextStyle resolved =
        widget.style ?? DefaultTextStyle.of(ctx).style;
    final Color effective = resolved.color ?? DefaultTextStyle.of(ctx).style.color!;

    expect(effective, expected);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/ui/log/log_attack_screen_comfort_color_test.dart`
Expected: FAIL — severity label color does not match `onSurface` because the inner `Theme(data: buildComfortTheme())` re-resolves against a different scheme than the ambient `MaterialApp` theme.

- [ ] **Step 3: Remove the inner Theme wrapper and color the label explicitly**

In `lib/ui/log/log_attack_screen.dart`, replace the `build` method's outer wrapper. Before:

```dart
  @override
  Widget build(BuildContext context) {
    return Theme(
      data: buildComfortTheme(),
      child: Scaffold(
      appBar: AppBar(title: const Text('Log a migraine')),
```

After:

```dart
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log a migraine')),
```

Remove the matching closing `),` for the `Theme` widget at the end of the method (currently around line 113).

Then replace line 83's severity label:

```dart
                  Text('Severity: ${_severity.round()}', style: Theme.of(context).textTheme.titleMedium),
```

with:

```dart
                  Text(
                    'Severity: ${_severity.round()}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
```

Also remove the unused `theme.dart` import if it is no longer referenced; keep it if other code in the file still uses it.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/ui/log/log_attack_screen_comfort_color_test.dart`
Expected: PASS.

- [ ] **Step 5: Run the existing log-attack tests to confirm no regression**

Run: `flutter test test/ui/log/log_attack_screen_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/ui/log/log_attack_screen.dart test/ui/log/log_attack_screen_comfort_color_test.dart
git commit -m "fix(log-attack): make severity label readable in comfort mode"
```

---

### Task 2: Default cycle tracking to OFF

**Files:**
- Modify: `lib/state/settings_provider.dart:29-34`
- Test: `test/state/cycle_tracking_default_test.dart` (create)

- [ ] **Step 1: Write the failing test**

Create `test/state/cycle_tracking_default_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/data/database.dart';
import 'package:migraine_forecast/data/repos/settings_repository.dart';
import 'package:migraine_forecast/state/providers.dart';
import 'package:migraine_forecast/state/settings_provider.dart';

void main() {
  test('cycleTrackingEnabledProvider defaults to false on fresh install', () async {
    final db = AppDatabase.memory();
    addTearDown(db.close);

    final container = ProviderContainer(overrides: [
      settingsRepoProvider.overrideWithValue(SettingsRepository(db)),
    ]);
    addTearDown(container.dispose);

    final enabled = await container.read(cycleTrackingEnabledProvider.future);
    expect(enabled, isFalse);
  });

  test('cycleTrackingEnabledProvider returns true after explicit enable', () async {
    final db = AppDatabase.memory();
    addTearDown(db.close);

    final container = ProviderContainer(overrides: [
      settingsRepoProvider.overrideWithValue(SettingsRepository(db)),
    ]);
    addTearDown(container.dispose);

    await container.read(setCycleTrackingEnabledProvider)(true);
    final enabled = await container.read(cycleTrackingEnabledProvider.future);
    expect(enabled, isTrue);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/state/cycle_tracking_default_test.dart`
Expected: FAIL on the first test — fresh install returns `true`.

- [ ] **Step 3: Flip the default in the provider**

In `lib/state/settings_provider.dart`, replace lines 29-34:

```dart
/// Cycle tracking is opt-out — defaults to true on a fresh install. The
/// "off" state is stored explicitly as "false" in settings.
final cycleTrackingEnabledProvider = FutureProvider<bool>((ref) async {
  final s = await ref.watch(settingsRepoProvider).getString('cycle_tracking_enabled');
  return s != 'false';
});
```

with:

```dart
/// Cycle tracking is opt-in — defaults to false on a fresh install. The
/// "on" state is stored explicitly as "true" in settings.
final cycleTrackingEnabledProvider = FutureProvider<bool>((ref) async {
  final s = await ref.watch(settingsRepoProvider).getString('cycle_tracking_enabled');
  return s == 'true';
});
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/state/cycle_tracking_default_test.dart`
Expected: PASS (both tests).

- [ ] **Step 5: Hunt and update affected tests**

Run: `grep -rln "cycle_tracking_enabled\|cycleTrackingEnabledProvider" test/`

For each test file that listed: if it implicitly assumes the default is `true` (e.g. asserts cycle UI is visible without overriding the provider), either override the provider with `cycleTrackingEnabledProvider.overrideWith((_) async => true)` or update the assertion. Make one commit per file changed only if changes are non-trivial; otherwise bundle.

- [ ] **Step 6: Run the full test suite to catch fallout**

Run: `flutter test`
Expected: PASS. Fix any failures uncovered (most likely smoke or end-to-end tests that hit the cycle UI).

- [ ] **Step 7: Commit**

```bash
git add lib/state/settings_provider.dart test/state/cycle_tracking_default_test.dart test/
git commit -m "feat(cycle-tracking): default to OFF on fresh install"
```

---

### Task 3: Remove unused `sampleAt` helper in domain test

**Files:**
- Modify: `packages/domain/test/modules/intraday_pressure_swing_test.dart:22-27`

- [ ] **Step 1: Confirm no usage**

Run: `grep -n "sampleAt" packages/domain/test/modules/intraday_pressure_swing_test.dart`
Expected: only the declaration on line 22.

- [ ] **Step 2: Delete the helper**

Remove lines 22-27 (the entire `WeatherSample sampleAt(...) => ...` block) from `packages/domain/test/modules/intraday_pressure_swing_test.dart`.

- [ ] **Step 3: Run analyze and tests**

Run: `cd packages/domain && dart analyze`
Expected: no warnings on this file.
Run: `cd packages/domain && dart test test/modules/intraday_pressure_swing_test.dart`
Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add packages/domain/test/modules/intraday_pressure_swing_test.dart
git commit -m "test(domain): remove unused sampleAt helper"
```

---

### Task 4: Drop unused `overrides` param + field from `_FakeJournal`

**Files:**
- Modify: `test/ui/insights/day_detail_cycle_row_test.dart:10-23, 45-46`

- [ ] **Step 1: Confirm no caller sets `overrides`**

Run: `grep -n "_FakeJournal(" test/ui/insights/day_detail_cycle_row_test.dart`
Expected: every callsite uses `_FakeJournal()` or `_FakeJournal(periods: ...)` — none pass `overrides:`. (Line 165's `overrides:` is on `ProviderScope`, not `_FakeJournal`.)

- [ ] **Step 2: Delete the field + parameter, inline `const []` at consumers**

In `test/ui/insights/day_detail_cycle_row_test.dart`, remove line 12 (`List<PeriodDaySeverity> overrides;`).

Change line 18 from:

```dart
  _FakeJournal({this.periods = const [], this.overrides = const []});
```

to:

```dart
  _FakeJournal({this.periods = const []});
```

Change lines 45-46 from:

```dart
  @override Future<List<PeriodDaySeverity>> recentPeriodDaySeverities(Duration window, {required DateTime now}) async => overrides;
  @override Stream<List<PeriodDaySeverity>> watchRecentPeriodDaySeverities(Duration window, {required DateTime now}) => Stream.value(overrides);
```

to:

```dart
  @override Future<List<PeriodDaySeverity>> recentPeriodDaySeverities(Duration window, {required DateTime now}) async => const [];
  @override Stream<List<PeriodDaySeverity>> watchRecentPeriodDaySeverities(Duration window, {required DateTime now}) => Stream.value(const []);
```

- [ ] **Step 3: Run analyze and the affected test**

Run: `flutter analyze test/ui/insights/day_detail_cycle_row_test.dart`
Expected: no warnings.
Run: `flutter test test/ui/insights/day_detail_cycle_row_test.dart`
Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add test/ui/insights/day_detail_cycle_row_test.dart
git commit -m "test(insights): drop unused overrides param from _FakeJournal"
```

---

### Task 5: Remove unused `day` local in insights screen test

**Files:**
- Modify: `test/ui/insights/insights_screen_test.dart:69`

- [ ] **Step 1: Confirm the variable is unused**

Run: `grep -n "\\bday\\b" test/ui/insights/insights_screen_test.dart`
Expected: line 69 declares `day`; no later line in the same test reads it. (Other `day` matches will be in unrelated tests or comments — confirm by reading the body of the test starting at line 61.)

- [ ] **Step 2: Delete the line**

In `test/ui/insights/insights_screen_test.dart`, delete line 69 in its entirety:

```dart
    final day = DateTime.utc(2026, 6, 5);
```

- [ ] **Step 3: Run analyze and the affected test**

Run: `flutter analyze test/ui/insights/insights_screen_test.dart`
Expected: no warnings.
Run: `flutter test test/ui/insights/insights_screen_test.dart`
Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add test/ui/insights/insights_screen_test.dart
git commit -m "test(insights): remove unused day local"
```

---

### Task 6: Grant release workflow `contents: write`

**Files:**
- Modify: `.github/workflows/release.yaml`

- [ ] **Step 1: Add the permissions block**

In `.github/workflows/release.yaml`, insert after the `on:` block and before `jobs:`:

```yaml
permissions:
  contents: write
```

The file should read:

```yaml
name: Release

on:
  push:
    tags: ['v*']
  workflow_dispatch:

permissions:
  contents: write

jobs:
  android:
    ...
```

- [ ] **Step 2: Lint the YAML**

Run: `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/release.yaml'))"`
Expected: no output (valid YAML).

- [ ] **Step 3: Commit**

```bash
git add .github/workflows/release.yaml
git commit -m "ci(release): grant contents:write so action-gh-release can create the release"
```

---

### Task 7: Verify PR A locally

- [ ] **Step 1: Domain analyze + test**

Run: `cd packages/domain && dart analyze && dart test`
Expected: clean, all tests PASS.

- [ ] **Step 2: Flutter analyze + test**

Run: `flutter analyze && flutter test`
Expected: clean, all tests PASS.

- [ ] **Step 3: Manual smoke (comfort + log-attack)**

Launch the app, enable comfort mode in Settings, open the log-attack screen, confirm the "Severity: N" label is clearly readable on the dark surface.

---

### Task 8: Open PR A

- [ ] **Step 1: Push the branch**

```bash
git push -u origin HEAD
```

- [ ] **Step 2: Open the PR via gh CLI (or browser)**

If `gh` is available:

```bash
gh pr create --title "Maintenance batch A: comfort label, cycle default, analyze warnings, release perms" --body "$(cat <<'EOF'
## Summary
- Severity label readable in comfort mode (drop redundant inner Theme, color via onSurface).
- Cycle tracking defaults to OFF on fresh install.
- Cleared three dart analyze warnings (unused helper / param / local).
- Release workflow gets contents: write so action-gh-release succeeds.

## Test plan
- [x] flutter test (full suite)
- [x] dart analyze (domain + root) clean
- [x] manual: comfort mode + log-attack screen readable
- [ ] confirm tag push creates the GitHub Release once merged (next tag)
EOF
)"
```

If `gh` is not available, open the PR in the browser using the URL printed by `git push`.

---

## PR B — Backfill: surface failures and extend window via archive API

### Task 9: Add `source` column to `weather_snapshots` (schema v6)

**Files:**
- Modify: `lib/data/database.dart:25-32, 115, 118-150`
- Test: `test/data/database_migration_test.dart`

- [ ] **Step 1: Extend the table definition**

In `lib/data/database.dart`, replace the `WeatherSnapshots` class (lines 25-32):

```dart
class WeatherSnapshots extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get fetchedAt => dateTime()();
  RealColumn get lat => real()();
  RealColumn get lon => real()();
  TextColumn get forecastJson => text()();
  TextColumn get airQualityJson => text().nullable()();
  TextColumn get source => text().withDefault(const Constant('forecast'))();
}
```

- [ ] **Step 2: Bump schemaVersion and add the migration step**

Change line 115 from `int get schemaVersion => 5;` to `int get schemaVersion => 6;`.

In `migration`'s `onUpgrade`, append after the `if (from < 5)` block:

```dart
          if (from < 6) {
            await m.addColumn(weatherSnapshots, weatherSnapshots.source);
          }
```

- [ ] **Step 3: Regenerate Drift sources**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: `lib/data/database.g.dart` updated; no errors.

- [ ] **Step 4: Add migration test**

In `test/data/database_migration_test.dart`, add a test that opens a v5-schema database, runs the upgrade to v6, and asserts that `weather_snapshots.source` exists and existing rows resolve to `'forecast'`. Pattern after existing tests in the same file.

```dart
  test('v5 → v6 adds source column defaulting to forecast', () async {
    // Pattern after existing migration tests — instantiate the verifier,
    // seed a v5 row in weather_snapshots, run migration to v6, query the row,
    // assert source == 'forecast'.
    final verifier = SchemaVerifier(GeneratedHelper());
    final v5 = await verifier.schemaAt(5);
    final db = AppDatabase(v5.newConnection());
    await db.customStatement(
      "INSERT INTO weather_snapshots (fetched_at, lat, lon, forecast_json) "
      "VALUES (1700000000000, 0.0, 0.0, '{}')",
    );
    await verifier.migrateAndValidate(db, 6);
    final row = await db
        .customSelect('SELECT source FROM weather_snapshots LIMIT 1')
        .getSingle();
    expect(row.read<String>('source'), 'forecast');
    await db.close();
  });
```

Note: this requires the existing test file's harness (SchemaVerifier, GeneratedHelper). If the harness is not yet present, follow Drift docs (`drift_dev schema generate`) to scaffold it — but check first whether earlier migrations in the file use a simpler manual harness and pattern-match that style instead.

- [ ] **Step 5: Run migration test**

Run: `flutter test test/data/database_migration_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/data/database.dart lib/data/database.g.dart test/data/database_migration_test.dart
git commit -m "feat(db): add weather_snapshots.source column (schema v6)"
```

---

### Task 10: Add archive URL builder

**Files:**
- Modify: `lib/data/sources/open_meteo/open_meteo_url_builder.dart`
- Test: `test/data/sources/open_meteo/open_meteo_url_builder_test.dart` (create if not present)

- [ ] **Step 1: Write the failing test**

Add to (or create) `test/data/sources/open_meteo/open_meteo_url_builder_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/data/sources/open_meteo/open_meteo_url_builder.dart';

void main() {
  test('archive URL has correct host, path, and required params', () {
    final uri = OpenMeteoUrlBuilder.archive(
      lat: 40.7,
      lon: -74.0,
      startDate: DateTime.utc(2026, 3, 16),
      endDate: DateTime.utc(2026, 5, 11),
    );
    expect(uri.host, 'archive-api.open-meteo.com');
    expect(uri.path, '/v1/archive');
    expect(uri.queryParameters['latitude'], '40.7');
    expect(uri.queryParameters['longitude'], '-74.0');
    expect(uri.queryParameters['start_date'], '2026-03-16');
    expect(uri.queryParameters['end_date'], '2026-05-11');
    expect(uri.queryParameters['hourly'], contains('pressure_msl'));
    expect(uri.queryParameters['hourly'], contains('temperature_2m'));
    expect(uri.queryParameters['hourly'], contains('relative_humidity_2m'));
    expect(uri.queryParameters['timezone'], 'UTC');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/data/sources/open_meteo/open_meteo_url_builder_test.dart`
Expected: FAIL — `OpenMeteoUrlBuilder.archive` does not exist.

- [ ] **Step 3: Read the existing `forecast` builder for the hourly variable list**

Run: `cat lib/data/sources/open_meteo/open_meteo_url_builder.dart`

Note the exact `hourly` variable string used for `forecast`. The archive builder must use the same variables (subset that the archive endpoint supports) so the existing parser works without changes.

- [ ] **Step 4: Add the archive builder**

In `lib/data/sources/open_meteo/open_meteo_url_builder.dart`, append a new static method on the same class. Use the same `hourly` variable list as `forecast` (paste it verbatim — DRY can be addressed separately if it shows up as duplication noise):

```dart
  static Uri archive({
    required double lat,
    required double lon,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    String fmt(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    return Uri.https('archive-api.open-meteo.com', '/v1/archive', {
      'latitude': lat.toString(),
      'longitude': lon.toString(),
      'start_date': fmt(startDate),
      'end_date': fmt(endDate),
      'hourly': /* same value as forecast hourly param */ '<<COPY FROM forecast()>>',
      'timezone': 'UTC',
    });
  }
```

Replace `<<COPY FROM forecast()>>` with the exact hourly-variable string read in Step 3. The archive endpoint supports `pressure_msl`, `temperature_2m`, `relative_humidity_2m`, `dew_point_2m`, `wind_speed_10m`, `wind_direction_10m`; drop any forecast-only variables (e.g. `weathercode`) if present.

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/data/sources/open_meteo/open_meteo_url_builder_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/data/sources/open_meteo/open_meteo_url_builder.dart test/data/sources/open_meteo/open_meteo_url_builder_test.dart
git commit -m "feat(open-meteo): add archive URL builder"
```

---

### Task 11: Route deep backfill through the archive endpoint

**Files:**
- Modify: `lib/data/sources/open_meteo/open_meteo_weather_source.dart:25-75`

- [ ] **Step 1: Write the failing test**

Add to `test/data/sources/open_meteo/open_meteo_weather_source_test.dart` (or create if absent):

```dart
testWidgets('fetch routes to archive endpoint when requestedDay is > 30 days old',
    (tester) async {
  final calls = <Uri>[];
  final client = MockClient((req) async {
    calls.add(req.url);
    if (req.url.host.contains('archive-api')) {
      return http.Response('{"hourly":{"time":[],"pressure_msl":[],"temperature_2m":[],"relative_humidity_2m":[]}}', 200);
    }
    return http.Response('{"hourly":{"time":[],"pm10":[]}}', 200);
  });
  final db = AppDatabase.memory();
  addTearDown(db.close);

  final source = OpenMeteoWeatherSource(db: db, client: client);
  final old = DateTime.utc(2026, 3, 16);
  await source.fetch(lat: 0, lon: 0, now: old, forceRefresh: true);

  expect(calls.any((u) => u.host.contains('archive-api')), isTrue);
  expect(
    calls.any((u) => u.host == 'api.open-meteo.com' && u.path == '/v1/forecast'),
    isFalse,
  );
});
```

(Use the existing test's imports / mock-client setup as a model — match its `import` block.)

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/data/sources/open_meteo/open_meteo_weather_source_test.dart`
Expected: FAIL — the forecast endpoint is hit for old days.

- [ ] **Step 3: Add the archive branch**

In `lib/data/sources/open_meteo/open_meteo_weather_source.dart`, modify the `fetch` method's try block. Replace lines 45-64 with:

```dart
    try {
      final diffDays = todayStart.difference(requestedDay).inDays.abs();
      final useArchive = diffDays > 30;
      final http.Response forecastRes;
      final String sourceTag;
      if (useArchive) {
        forecastRes = await client.get(
          OpenMeteoUrlBuilder.archive(
            lat: lat,
            lon: lon,
            startDate: requestedDay.subtract(const Duration(days: 2)),
            endDate: requestedDay.add(const Duration(days: 1)),
          ),
        );
        sourceTag = 'archive';
      } else {
        final pastDays = (diffDays + 2).clamp(1, 90);
        forecastRes = await client.get(
          OpenMeteoUrlBuilder.forecast(lat: lat, lon: lon, pastDays: pastDays),
        );
        sourceTag = 'forecast';
      }
      // Air quality archive uses the same air-quality endpoint with past_days;
      // the air-quality endpoint already supports arbitrary historical windows
      // up to past_days=92, so the call shape is unchanged.
      final aqPastDays = (diffDays + 2).clamp(1, 92);
      final aqRes = await client.get(
        OpenMeteoUrlBuilder.airQuality(lat: lat, lon: lon, pastDays: aqPastDays),
      );
      if (forecastRes.statusCode >= 400 || aqRes.statusCode >= 400) {
        if (cached != null) return _toSnapshot(cached, stale: true);
        throw StateError('Open-Meteo fetch failed (no cache)');
      }
      await db.into(db.weatherSnapshots).insert(
            WeatherSnapshotsCompanion.insert(
              fetchedAt: nowUtc,
              lat: lat,
              lon: lon,
              forecastJson: forecastRes.body,
              airQualityJson: Value(aqRes.body),
              source: Value(sourceTag),
            ),
          );
      return WeatherSnapshot(
        weather: OpenMeteoParser.parseForecast(forecastRes.body),
        airQuality: OpenMeteoParser.parseAirQuality(aqRes.body),
        fetchedAt: nowUtc,
        stale: false,
      );
```

The closing `} catch (_) { … }` at lines 71-74 is unchanged.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/data/sources/open_meteo/open_meteo_weather_source_test.dart`
Expected: PASS.

- [ ] **Step 5: Run analyze on the file**

Run: `flutter analyze lib/data/sources/open_meteo/open_meteo_weather_source.dart`
Expected: no warnings.

- [ ] **Step 6: Commit**

```bash
git add lib/data/sources/open_meteo/open_meteo_weather_source.dart test/data/sources/open_meteo/open_meteo_weather_source_test.dart
git commit -m "feat(weather): route diffDays>30 backfill through Open-Meteo archive API"
```

---

### Task 12: Extend `BackfillReport` with `daysFailed` and per-day error map

**Files:**
- Modify: `lib/data/bulk_backfill_orchestrator.dart:10-22, 134-170`

- [ ] **Step 1: Write the failing test**

In `test/data/bulk_backfill_orchestrator_test.dart`, add a test:

```dart
test('report.daysFailed counts per-day errors and records firstError', () async {
  // Use the file's existing fakes (location source, weather source, repo).
  // Make the weather source throw for the oldest day only.
  // Run the orchestrator with a 3-day window.
  // Assert: report.daysFailed == 1, report.daysProcessed == 2,
  //         report.firstError is not null.
});
```

Implement the test body using the existing fakes in the same file. Use a 3-day window: today, yesterday, day-before. Make the fake weather source throw `StateError('boom')` whenever `requestedDay` equals the oldest day (`DateTime.utc(... today.subtract(Duration(days: 2)) ...)`).

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/data/bulk_backfill_orchestrator_test.dart`
Expected: FAIL — `BackfillReport.daysFailed` does not exist.

- [ ] **Step 3: Extend the report class**

In `lib/data/bulk_backfill_orchestrator.dart`, replace the `BackfillReport` class (lines 10-22):

```dart
class BackfillReport {
  final int daysProcessed;
  final int daysSkipped;
  final int daysFailed;
  final bool weatherFetchSucceeded;
  final Object? firstError;

  const BackfillReport({
    required this.daysProcessed,
    required this.daysSkipped,
    required this.daysFailed,
    required this.weatherFetchSucceeded,
    this.firstError,
  });
}
```

Update every `BackfillReport(...)` construction site in the same file (lines 59, 99, 109, 126, 165) to include `daysFailed:`. For the early-return cases where the per-day loop hasn't run, pass `daysFailed: 0`. For the final return at lines 165-170, replace with:

```dart
    return BackfillReport(
      daysProcessed: processed,
      daysSkipped: allDays.length - missingDays.length,
      daysFailed: missingDays.length - processed,
      weatherFetchSucceeded: true,
      firstError: firstError,
    );
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/data/bulk_backfill_orchestrator_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/data/bulk_backfill_orchestrator.dart test/data/bulk_backfill_orchestrator_test.dart
git commit -m "feat(backfill): surface daysFailed in BackfillReport"
```

---

### Task 13: Hold the last backfill report in a provider for the UI

**Files:**
- Modify: `lib/state/backfill_provider.dart`

- [ ] **Step 1: Add a `lastBackfillReportProvider`**

In `lib/state/backfill_provider.dart`, after the existing `backfillProgressProvider`, add:

```dart
/// Holds the most recent completed [BackfillReport], or null if no backfill
/// has finished in this session. The Insights screen surfaces this when
/// daysFailed > 0 so the user knows the heatmap is incomplete.
final lastBackfillReportProvider =
    StateProvider<BackfillReport?>((_) => null);
```

Add the import for `BackfillReport` at the top:

```dart
// (the import for bulk_backfill_orchestrator.dart already exists)
```

- [ ] **Step 2: Write the report at completion**

In the same file, in `launchBackfill`, replace the existing completion block:

```dart
    container.read(backfillProgressProvider.notifier).state = null;

    if (report.daysProcessed > 0) {
      container.invalidate(correlationResultsProvider);
      container.invalidate(recentAttacksProvider);
      container.invalidate(dayAssessmentProvider);
    }
```

with:

```dart
    container.read(backfillProgressProvider.notifier).state = null;
    container.read(lastBackfillReportProvider.notifier).state = report;

    if (report.daysProcessed > 0) {
      container.invalidate(correlationResultsProvider);
      container.invalidate(recentAttacksProvider);
      container.invalidate(dayAssessmentProvider);
    }
```

- [ ] **Step 3: Run analyze**

Run: `flutter analyze lib/state/backfill_provider.dart`
Expected: no warnings.

- [ ] **Step 4: Commit**

```bash
git add lib/state/backfill_provider.dart
git commit -m "feat(backfill): expose lastBackfillReportProvider for UI"
```

---

### Task 14: Surface failed-day count on Insights

**Files:**
- Modify: `lib/ui/insights/insights_screen.dart:7, 85-100, 519-540`
- Test: `test/ui/insights/insights_screen_test.dart`

- [ ] **Step 1: Write the failing test**

Add to `test/ui/insights/insights_screen_test.dart`:

```dart
testWidgets('insights shows a failure notice when last backfill had daysFailed > 0',
    (tester) async {
  final report = BackfillReport(
    daysProcessed: 33,
    daysSkipped: 0,
    daysFailed: 57,
    weatherFetchSucceeded: true,
    firstError: 'weather unavailable',
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        insightsEligibleProvider.overrideWith((ref) => Stream.value(true)),
        recentAttacksProvider.overrideWith((ref) => Stream.value(const <Attack>[])),
        correlationResultsProvider.overrideWith((ref) async => []),
        suggestionsProvider.overrideWith((ref) async => []),
        dayAssessmentProvider.overrideWith((ref, _) async => null),
        dayAttacksProvider.overrideWith((ref, _) => Stream.value(const <Attack>[])),
        lastBackfillReportProvider.overrideWith((_) => report),
      ],
      child: MaterialApp.router(
        routerConfig: GoRouter(routes: [
          GoRoute(path: '/', builder: (_, __) => const InsightsScreen()),
        ]),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(find.textContaining('57 failed'), findsOneWidget);
});
```

Add the necessary imports (`BackfillReport`, `lastBackfillReportProvider`) at the top of the file.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/ui/insights/insights_screen_test.dart`
Expected: FAIL — no widget rendering the "57 failed" text.

- [ ] **Step 3: Render the report below the progress strip**

In `lib/ui/insights/insights_screen.dart`, around line 87 where `backfillProgress` is read, also read the report:

```dart
    final backfillProgress = ref.watch(backfillProgressProvider);
    final lastReport = ref.watch(lastBackfillReportProvider);
```

Then update the conditional widget block (currently `if (backfillProgress != null) ...`) to add a sibling notice:

```dart
        if (backfillProgress != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: _BackfillProgressStrip(
              done: backfillProgress.done,
              total: backfillProgress.total,
            ),
          ),
        if (backfillProgress == null && lastReport != null && lastReport.daysFailed > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: _BackfillFailureNotice(report: lastReport),
          ),
```

Append a new private widget at the bottom of the file:

```dart
class _BackfillFailureNotice extends ConsumerWidget {
  final BackfillReport report;
  const _BackfillFailureNotice({required this.report});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = report.daysProcessed + report.daysFailed;
    final reason = report.firstError?.toString() ?? 'unknown';
    final truncated = reason.length > 120 ? '${reason.substring(0, 117)}…' : reason;
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filled ${report.daysProcessed} / $total days '
              '(${report.daysFailed} failed — $truncated)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () =>
                    ref.read(lastBackfillReportProvider.notifier).state = null,
                child: const Text('Dismiss'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

Add imports as needed at the top of `insights_screen.dart`:

```dart
import '../../data/bulk_backfill_orchestrator.dart';
```

(`lastBackfillReportProvider` comes from `backfill_provider.dart` which is already imported on line 7.)

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/ui/insights/insights_screen_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/ui/insights/insights_screen.dart test/ui/insights/insights_screen_test.dart
git commit -m "feat(insights): show backfill failure notice when days failed"
```

---

### Task 15: Drop the prime fetch from the orchestrator

**Files:**
- Modify: `lib/data/bulk_backfill_orchestrator.dart:106-132`

- [ ] **Step 1: Verify per-day fetches now cover all windows**

Per Task 11, `OpenMeteoWeatherSource.fetch` already routes archive vs. forecast per requested day, so the orchestrator's single prime fetch (which set `pastDays = 2` and only covered ~2 days) is now redundant and misleading.

- [ ] **Step 2: Remove the prime block**

In `lib/data/bulk_backfill_orchestrator.dart`, delete lines 106-132 (the comment `// Prime the weather cache ...` through the closing `}` of the inner `try { ... } catch` that early-returned on prime failure).

Then update the location-required check: the location lookup is still needed (it's used implicitly via `ContextBuilder.build`, which reads location). Inspect `ContextBuilder.build` — if it fetches location internally, drop the explicit `locationSource.current()` call here too; otherwise keep just the `final loc = await locationSource.current();` and the early-return on null, removing the `weatherSource.fetch(...)` call.

Replace lines 106-132 with:

```dart
    // ContextBuilder.build pulls location and weather per-day; an upfront
    // location null-check still gives a clean early return when permissions
    // are denied so we don't waste 90 iterations.
    final loc = await locationSource.current();
    if (loc == null) {
      return BackfillReport(
        daysProcessed: 0,
        daysSkipped: allDays.length,
        daysFailed: 0,
        weatherFetchSucceeded: false,
        firstError: 'location unavailable',
      );
    }
```

If `loc` is then not referenced below, prefix with `_` (`final _ = await locationSource.current();`) or use `await locationSource.current().then((v) => v ?? (throw ...))` — pick whatever passes analyze.

- [ ] **Step 3: Run the orchestrator tests**

Run: `flutter test test/data/bulk_backfill_orchestrator_test.dart`
Expected: PASS. Update fakes if they relied on `weatherSource.fetch` being called once upfront.

- [ ] **Step 4: Commit**

```bash
git add lib/data/bulk_backfill_orchestrator.dart test/data/bulk_backfill_orchestrator_test.dart
git commit -m "refactor(backfill): drop misleading 2-day prime fetch"
```

---

### Task 16: Verify PR B locally

- [ ] **Step 1: Full domain + flutter check**

Run: `cd packages/domain && dart analyze && dart test && cd - && flutter analyze && flutter test`
Expected: clean and all tests PASS.

- [ ] **Step 2: Manual smoke**

Launch the app on a device or emulator. From Insights, trigger a backfill (or wipe local data and re-onboard to trigger a fresh backfill). Confirm:
- Progress strip shows during the run.
- After completion, the heatmap reaches the full 90-day window (no May 12 cliff).
- If you simulate failures (toggle airplane mode mid-backfill), the failure notice appears with a sensible reason.

---

### Task 17: Open PR B

- [ ] **Step 1: Push the branch**

```bash
git push -u origin HEAD
```

- [ ] **Step 2: Open the PR**

```bash
gh pr create --title "Backfill: archive API + surface failed-day count" --body "$(cat <<'EOF'
## Summary
- Add weather_snapshots.source column (schema v6).
- New OpenMeteoUrlBuilder.archive(...).
- OpenMeteoWeatherSource routes diffDays > 30 to archive-api.open-meteo.com.
- BackfillReport.daysFailed surfaced via lastBackfillReportProvider.
- Insights renders a dismissible failure notice when daysFailed > 0.
- Drop the misleading 2-day prime fetch in the orchestrator.

## Test plan
- [x] new archive URL builder test
- [x] weather source archive-routing test
- [x] orchestrator daysFailed test
- [x] insights failure-notice widget test
- [x] migration v5 → v6 test
- [x] full flutter test + analyze
- [ ] manual: full 90-day backfill reaches the window cutoff (no ~30-day cliff)
EOF
)"
```

---

## Self-Review Notes

- Spec items 1, 2, 3, 4, 5 each map to tasks: 1→T1, 2→T2, 3→T9-T15, 4→T3-T5, 5→T6.
- Type/signature consistency: `BackfillReport` now requires `daysFailed`; every construction site updated in T12. `lastBackfillReportProvider` introduced in T13 and consumed in T14. `OpenMeteoUrlBuilder.archive` defined in T10 and consumed in T11.
- No "TBD" or "TODO"; the only placeholder is `<<COPY FROM forecast()>>` in T10 step 4 with explicit instruction to read the value in step 3.
- T15 has a small judgement call (whether to keep `locationSource.current()` or drop it) — explicit guidance given to pick whichever passes analyze.
