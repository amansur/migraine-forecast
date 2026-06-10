# Plan 2 — Adapters + Storage

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement task-by-task. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Build every concrete adapter the domain layer expects — weather, air quality, health, journal, location — backed by SQLite (Drift) for the journal/migraine log/assessment history. Every domain input has a real implementation by the end of this plan.

**Architecture:** Adapters live in `lib/data/` of the Flutter app. Each adapter has an abstract interface in `lib/data/sources/` and a concrete implementation. The domain layer (`packages/domain/`) never imports anything from `lib/data/` — adapters depend on domain, not the other way around. Drift handles all SQLite work; codegen runs via `build_runner`.

**Tech Stack:** Flutter 3.44 / Dart 3.12. `drift` ^2.18 + `drift_dev` + `build_runner` for SQLite. `http` for Open-Meteo. `health` for Apple Health + Health Connect. `geolocator` + `permission_handler` for location. `path_provider` for SQLite file location. Tests use `package:test` (pure-Dart adapters) + `flutter_test` (widget/platform-channel parts). Open-Meteo responses are committed as recorded JSON fixtures — no live network in CI.

---

## File Structure

```
/Users/amansur/projects/migraine-weatherr/
├── lib/
│   ├── data/
│   │   ├── database.dart                       # Drift database + tables
│   │   ├── database.g.dart                     # generated
│   │   ├── sources/
│   │   │   ├── weather_source.dart             # abstract WeatherSource
│   │   │   ├── open_meteo/
│   │   │   │   ├── open_meteo_url_builder.dart
│   │   │   │   ├── open_meteo_parser.dart
│   │   │   │   ├── open_meteo_weather_source.dart   # implements WeatherSource
│   │   │   │   └── _cache.dart                  # Drift-backed cache
│   │   │   ├── health_source.dart               # abstract HealthSource
│   │   │   ├── health_package_source.dart       # concrete (health pkg)
│   │   │   ├── fake_health_source.dart          # test fake (also useful in dev)
│   │   │   ├── journal_source.dart              # abstract JournalSource
│   │   │   ├── drift_journal_source.dart        # Drift impl
│   │   │   ├── location_source.dart             # abstract LocationSource
│   │   │   └── manual_location_source.dart      # in-memory impl (geolocator wrapper deferred to Plan 3)
│   │   ├── repos/
│   │   │   ├── assessment_repository.dart       # RiskAssessment persistence
│   │   │   └── baseline_snapshot_builder.dart   # builds BaselineSnapshot from DB
│   │   └── context_builder.dart                 # orchestrator → EvaluationContext
│   └── main.dart                                # unchanged; UI in Plan 3
├── test/
│   ├── data/
│   │   ├── database_test.dart
│   │   ├── sources/
│   │   │   ├── drift_journal_source_test.dart
│   │   │   ├── open_meteo_url_builder_test.dart
│   │   │   ├── open_meteo_parser_test.dart
│   │   │   ├── open_meteo_weather_source_test.dart
│   │   │   ├── fake_health_source_test.dart
│   │   │   ├── manual_location_source_test.dart
│   │   │   └── fixtures/
│   │   │       └── open_meteo/
│   │   │           ├── forecast_typical_day.json
│   │   │           ├── forecast_pressure_drop.json
│   │   │           └── air_quality_typical.json
│   │   ├── repos/
│   │   │   ├── assessment_repository_test.dart
│   │   │   └── baseline_snapshot_builder_test.dart
│   │   └── context_builder_test.dart
│   └── end_to_end/
│       └── plan2_smoke_test.dart                # adapters → engine → repo
└── .github/workflows/ci.yaml                    # extend
```

---

## Task 1: Dependencies + Drift bootstrap

**Files:** `pubspec.yaml`, `build.yaml`

- [ ] **Step 1: Add dependencies**

Edit `/Users/amansur/projects/migraine-weatherr/pubspec.yaml`. Under `dependencies:`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  domain:
    path: packages/domain
  drift: ^2.18.0
  sqlite3_flutter_libs: ^0.5.0
  path: ^1.9.0
  path_provider: ^2.1.0
  http: ^1.2.0
  health: ^11.1.0
  geolocator: ^13.0.0
  permission_handler: ^11.3.0
```

Under `dev_dependencies:`:

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  drift_dev: ^2.18.0
  build_runner: ^2.4.0
  mocktail: ^1.0.0
```

- [ ] **Step 2: Create build.yaml at repo root**

Create `/Users/amansur/projects/migraine-weatherr/build.yaml`:

```yaml
targets:
  $default:
    builders:
      drift_dev:
        options:
          store_date_time_values_as_text: true
          named_parameters: true
```

- [ ] **Step 3: Resolve**

```bash
cd /Users/amansur/projects/migraine-weatherr && flutter pub get
```

Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "deps: add drift, http, health, geolocator, mocktail for Plan 2"
```

---

## Task 2: Drift schema + database

**Files:**
- Create: `lib/data/database.dart`
- Create: `lib/data/database.g.dart` (generated)
- Test: `test/data/database_test.dart`

- [ ] **Step 1: Write the schema**

Create `lib/data/database.dart`:

```dart
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

class Attacks extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  IntColumn get severity => integer()();
  TextColumn get notes => text().nullable()();
  IntColumn get riskAssessmentId => integer().nullable()();
}

class JournalEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get at => dateTime()();
  TextColumn get kind => text()(); // alcohol | caffeine | stress | hydration
  TextColumn get payloadJson => text()();
}

class WeatherSnapshots extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get fetchedAt => dateTime()();
  RealColumn get lat => real()();
  RealColumn get lon => real()();
  TextColumn get forecastJson => text()();      // raw Open-Meteo forecast response
  TextColumn get airQualityJson => text().nullable()();
}

class BaselinesKv extends Table {
  TextColumn get key => text()(); // 'sleep_median_minutes', 'hrv_rmssd_14d', 'pressure', 'caffeine_daily_mg'
  RealColumn get value => real()();
  DateTimeColumn get updatedAt => dateTime()();
  @override
  Set<Column> get primaryKey => {key};
}

class UserTriggerFlagsTbl extends Table {
  TextColumn get moduleId => text()();
  BoolColumn get flagged => boolean().withDefault(const Constant(false))();
  RealColumn get weightOverride => real().withDefault(const Constant(0))();
  @override
  Set<Column> get primaryKey => {moduleId};
  @override
  String get tableName => 'user_trigger_flags';
}

class RiskAssessments extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get targetDate => dateTime()();
  TextColumn get horizon => text()(); // today | tomorrow
  IntColumn get score => integer()();
  TextColumn get band => text()();    // low | moderate | high | veryHigh
  DateTimeColumn get computedAt => dateTime()();
  IntColumn get configVersion => integer()();
  TextColumn get contributorsJson => text()();
}

class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [
  Attacks,
  JournalEntries,
  WeatherSnapshots,
  BaselinesKv,
  UserTriggerFlagsTbl,
  RiskAssessments,
  Settings,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);
  AppDatabase.memory() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() => LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'migraine_weatherr.sqlite'));
      return NativeDatabase.createInBackground(file);
    });

AppDatabase openAppDatabase() => AppDatabase(_openConnection());
```

- [ ] **Step 2: Run codegen**

```bash
cd /Users/amansur/projects/migraine-weatherr && dart run build_runner build --delete-conflicting-outputs
```

Expected: generates `lib/data/database.g.dart`. Tail output should say "Succeeded".

- [ ] **Step 3: Write a smoke test**

Create `test/data/database_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_weatherr/data/database.dart';

void main() {
  test('in-memory database opens and accepts a journal entry', () async {
    final db = AppDatabase.memory();
    addTearDown(db.close);

    await db.into(db.journalEntries).insert(JournalEntriesCompanion.insert(
          at: DateTime.utc(2026, 6, 10, 8),
          kind: 'alcohol',
          payloadJson: '{"units": 2.0}',
        ));

    final rows = await db.select(db.journalEntries).get();
    expect(rows, hasLength(1));
    expect(rows.first.kind, 'alcohol');
  });
}
```

- [ ] **Step 4: Run**

```bash
cd /Users/amansur/projects/migraine-weatherr && flutter test test/data/database_test.dart
```

Expected: 1 passing.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "data: add Drift schema with all Plan 2 tables"
```

---

## Task 3: JournalSource (interface + Drift impl)

**Files:**
- Create: `lib/data/sources/journal_source.dart`
- Create: `lib/data/sources/drift_journal_source.dart`
- Test: `test/data/sources/drift_journal_source_test.dart`

- [ ] **Step 1: Write failing test**

Create `test/data/sources/drift_journal_source_test.dart`:

```dart
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_weatherr/data/database.dart';
import 'package:migraine_weatherr/data/sources/drift_journal_source.dart';

void main() {
  late AppDatabase db;
  late DriftJournalSource source;

  setUp(() {
    db = AppDatabase.memory();
    source = DriftJournalSource(db);
  });
  tearDown(() => db.close());

  test('round-trips a journal entry', () async {
    final entry = JournalEntry(
      at: DateTime.utc(2026, 6, 10, 8),
      kind: JournalKind.alcohol,
      payload: {'units': 2.0},
    );
    await source.addEntry(entry);
    final recent = await source.recentEntries(const Duration(days: 1), now: DateTime.utc(2026, 6, 10, 12));
    expect(recent, hasLength(1));
    expect(recent.first.kind, JournalKind.alcohol);
    expect(recent.first.payload['units'], 2.0);
  });

  test('recentEntries respects the window', () async {
    await source.addEntry(JournalEntry(
      at: DateTime.utc(2026, 6, 8, 8),
      kind: JournalKind.caffeine,
      payload: {'mg': 100},
    ));
    final recent = await source.recentEntries(const Duration(hours: 24), now: DateTime.utc(2026, 6, 10, 12));
    expect(recent, isEmpty);
  });

  test('addAttack stores with risk assessment id', () async {
    final id = await source.addAttack(
      const Attack(startedAt: _T(2026, 6, 10, 9), severity: 7),
      riskAssessmentId: 42,
    );
    expect(id, isPositive);
    final attacks = await source.recentAttacks(const Duration(days: 7), now: DateTime.utc(2026, 6, 10, 18));
    expect(attacks, hasLength(1));
    expect(attacks.first.severity, 7);
  });
}

DateTime _T(int y, int m, int d, [int h = 0]) => DateTime.utc(y, m, d, h);
```

- [ ] **Step 2: Run — expect FAIL**

```bash
flutter test test/data/sources/drift_journal_source_test.dart
```

- [ ] **Step 3: Implement interface**

Create `lib/data/sources/journal_source.dart`:

```dart
import 'package:domain/domain.dart';

abstract class JournalSource {
  Future<void> addEntry(JournalEntry entry);
  Future<List<JournalEntry>> recentEntries(Duration window, {required DateTime now});
  Future<int> addAttack(Attack attack, {int? riskAssessmentId});
  Future<List<Attack>> recentAttacks(Duration window, {required DateTime now});
}
```

- [ ] **Step 4: Implement Drift backing**

Create `lib/data/sources/drift_journal_source.dart`:

```dart
import 'dart:convert';

import 'package:domain/domain.dart';
import 'package:drift/drift.dart';

import '../database.dart';
import 'journal_source.dart';

class DriftJournalSource implements JournalSource {
  final AppDatabase _db;
  DriftJournalSource(this._db);

  @override
  Future<void> addEntry(JournalEntry entry) async {
    await _db.into(_db.journalEntries).insert(
          JournalEntriesCompanion.insert(
            at: entry.at,
            kind: entry.kind.name,
            payloadJson: jsonEncode(entry.payload),
          ),
        );
  }

  @override
  Future<List<JournalEntry>> recentEntries(Duration window, {required DateTime now}) async {
    final cutoff = now.subtract(window);
    final rows = await (_db.select(_db.journalEntries)
          ..where((t) => t.at.isBiggerOrEqualValue(cutoff))
          ..orderBy([(t) => OrderingTerm.desc(t.at)]))
        .get();
    return rows
        .map((r) => JournalEntry(
              at: r.at,
              kind: JournalKind.values.firstWhere((k) => k.name == r.kind),
              payload: Map<String, Object?>.from(jsonDecode(r.payloadJson) as Map),
            ))
        .toList();
  }

  @override
  Future<int> addAttack(Attack attack, {int? riskAssessmentId}) async {
    return _db.into(_db.attacks).insert(
          AttacksCompanion.insert(
            startedAt: attack.startedAt,
            endedAt: Value(attack.endedAt),
            severity: attack.severity,
            notes: const Value.absent(),
            riskAssessmentId: Value(riskAssessmentId),
          ),
        );
  }

  @override
  Future<List<Attack>> recentAttacks(Duration window, {required DateTime now}) async {
    final cutoff = now.subtract(window);
    final rows = await (_db.select(_db.attacks)
          ..where((t) => t.startedAt.isBiggerOrEqualValue(cutoff))
          ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]))
        .get();
    return rows
        .map((r) => Attack(startedAt: r.startedAt, endedAt: r.endedAt, severity: r.severity))
        .toList();
  }
}
```

- [ ] **Step 5: Run — expect PASS**

```bash
flutter test test/data/sources/drift_journal_source_test.dart
```

Expected: 3 passing.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "data: DriftJournalSource (interface + impl + tests)"
```

---

## Task 4: BaselineSnapshotBuilder

**Files:**
- Create: `lib/data/repos/baseline_snapshot_builder.dart`
- Test: `test/data/repos/baseline_snapshot_builder_test.dart`

- [ ] **Step 1: Write failing test**

Create `test/data/repos/baseline_snapshot_builder_test.dart`:

```dart
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_weatherr/data/repos/baseline_snapshot_builder.dart';

void main() {
  test('builds a snapshot from health + journal history', () {
    final builder = BaselineSnapshotBuilder(const BaselineStore());
    final sleep = List.generate(
      7,
      (i) => SleepRecord(
        night: DateTime.utc(2026, 6, 1 + i),
        totalSleep: Duration(hours: 7),
        efficiency: 0.9,
        sleepStart: DateTime.utc(2026, 6, 1 + i, 22),
      ),
    );
    final hrv = List.generate(
      14,
      (i) => HrvSample(at: DateTime.utc(2026, 5, 27 + i), rmssdMs: (40 + i).toDouble()),
    );
    final caffeineDays = <double>[180, 200, 150, 220, 190, 175, 210];

    final snap = builder.build(
      sleep: sleep,
      hrv: hrv,
      pastDailyCaffeineMg: caffeineDays,
      pastPressures: const [],
    );
    expect(snap.sleepMedian7d, const Duration(hours: 7));
    expect(snap.hrvRmssdBaseline14d, 46.5);
    expect(snap.caffeineDailyMg, 190);
    expect(snap.pressureBaseline, isNull);
  });

  test('returns empty for missing inputs', () {
    final builder = BaselineSnapshotBuilder(const BaselineStore());
    final snap = builder.build(
      sleep: const [],
      hrv: const [],
      pastDailyCaffeineMg: const [],
      pastPressures: const [],
    );
    expect(snap, BaselineSnapshot.empty);
  });
}
```

- [ ] **Step 2: Run — expect FAIL**

```bash
flutter test test/data/repos/baseline_snapshot_builder_test.dart
```

- [ ] **Step 3: Implement**

Create `lib/data/repos/baseline_snapshot_builder.dart`:

```dart
import 'package:domain/domain.dart';

class BaselineSnapshotBuilder {
  final BaselineStore _store;
  const BaselineSnapshotBuilder(this._store);

  BaselineSnapshot build({
    required List<SleepRecord> sleep,
    required List<HrvSample> hrv,
    required List<double> pastDailyCaffeineMg,
    required List<double> pastPressures,
  }) {
    final sleepMedianHours = _store.medianSleepHours(
      sleep.map((s) => s.totalSleep.inMinutes / 60.0).toList(),
    );
    final hrvBaseline =
        _store.hrvRmssdBaseline(hrv.map((h) => h.rmssdMs).toList());
    final caffeine = _store.caffeineBaselineMg(pastDailyCaffeineMg);
    final pressure = _store.pressureBaseline(pastPressures);

    return BaselineSnapshot(
      sleepMedian7d: sleepMedianHours == null
          ? null
          : Duration(minutes: (sleepMedianHours * 60).round()),
      hrvRmssdBaseline14d: hrvBaseline,
      caffeineDailyMg: caffeine,
      pressureBaseline: pressure,
    );
  }
}
```

- [ ] **Step 4: Run**

```bash
flutter test test/data/repos/baseline_snapshot_builder_test.dart
```

Expected: 2 passing.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "data: BaselineSnapshotBuilder over domain BaselineStore"
```

---

## Task 5: WeatherSource interface + Open-Meteo URL builder

**Files:**
- Create: `lib/data/sources/weather_source.dart`
- Create: `lib/data/sources/open_meteo/open_meteo_url_builder.dart`
- Test: `test/data/sources/open_meteo_url_builder_test.dart`

- [ ] **Step 1: Write failing test**

Create `test/data/sources/open_meteo_url_builder_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_weatherr/data/sources/open_meteo/open_meteo_url_builder.dart';

void main() {
  test('forecast URL includes required hourly params', () {
    final uri = OpenMeteoUrlBuilder.forecast(lat: 40.7, lon: -74.0);
    expect(uri.host, 'api.open-meteo.com');
    expect(uri.path, '/v1/forecast');
    expect(uri.queryParameters['latitude'], '40.7');
    expect(uri.queryParameters['longitude'], '-74.0');
    final hourly = uri.queryParameters['hourly']!;
    expect(hourly, contains('pressure_msl'));
    expect(hourly, contains('temperature_2m'));
    expect(hourly, contains('relative_humidity_2m'));
    expect(uri.queryParameters['forecast_days'], '3');
    expect(uri.queryParameters['past_days'], '1');
    expect(uri.queryParameters['timezone'], 'UTC');
  });

  test('air quality URL targets the AQ endpoint', () {
    final uri = OpenMeteoUrlBuilder.airQuality(lat: 40.7, lon: -74.0);
    expect(uri.host, 'air-quality-api.open-meteo.com');
    expect(uri.path, '/v1/air-quality');
    expect(uri.queryParameters['hourly'], contains('pm2_5'));
    expect(uri.queryParameters['forecast_days'], '2');
  });
}
```

- [ ] **Step 2: Run — expect FAIL**

```bash
flutter test test/data/sources/open_meteo_url_builder_test.dart
```

- [ ] **Step 3: Implement interface**

Create `lib/data/sources/weather_source.dart`:

```dart
import 'package:domain/domain.dart';

class WeatherSnapshot {
  final WeatherSeries weather;
  final AirQualitySeries airQuality;
  final DateTime fetchedAt;
  final bool stale;
  const WeatherSnapshot({
    required this.weather,
    required this.airQuality,
    required this.fetchedAt,
    this.stale = false,
  });
}

abstract class WeatherSource {
  /// Returns the latest cached snapshot if fresh (per the source's freshness
  /// policy), otherwise fetches a new one. Returns a stale snapshot if a fetch
  /// fails and a cached value exists.
  Future<WeatherSnapshot> fetch({required double lat, required double lon, required DateTime now});
}
```

- [ ] **Step 4: Implement URL builder**

Create `lib/data/sources/open_meteo/open_meteo_url_builder.dart`:

```dart
class OpenMeteoUrlBuilder {
  static Uri forecast({required double lat, required double lon}) =>
      Uri.https('api.open-meteo.com', '/v1/forecast', {
        'latitude': lat.toString(),
        'longitude': lon.toString(),
        'hourly': 'pressure_msl,temperature_2m,relative_humidity_2m',
        'forecast_days': '3',
        'past_days': '1',
        'timezone': 'UTC',
      });

  static Uri airQuality({required double lat, required double lon}) =>
      Uri.https('air-quality-api.open-meteo.com', '/v1/air-quality', {
        'latitude': lat.toString(),
        'longitude': lon.toString(),
        'hourly': 'pm2_5',
        'forecast_days': '2',
        'timezone': 'UTC',
      });
}
```

- [ ] **Step 5: Run**

```bash
flutter test test/data/sources/open_meteo_url_builder_test.dart
```

Expected: 2 passing.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "data: WeatherSource interface + Open-Meteo URL builder"
```

---

## Task 6: Open-Meteo response parser + recorded fixtures

**Files:**
- Create: `lib/data/sources/open_meteo/open_meteo_parser.dart`
- Create: `test/data/sources/fixtures/open_meteo/forecast_typical_day.json`
- Create: `test/data/sources/fixtures/open_meteo/forecast_pressure_drop.json`
- Create: `test/data/sources/fixtures/open_meteo/air_quality_typical.json`
- Test: `test/data/sources/open_meteo_parser_test.dart`

- [ ] **Step 1: Commit minimal recorded fixtures**

Create `test/data/sources/fixtures/open_meteo/forecast_typical_day.json`:

```json
{
  "latitude": 40.7,
  "longitude": -74.0,
  "timezone": "UTC",
  "hourly": {
    "time": [
      "2026-06-10T00:00", "2026-06-10T01:00", "2026-06-10T02:00", "2026-06-10T03:00",
      "2026-06-10T04:00", "2026-06-10T05:00", "2026-06-10T06:00", "2026-06-10T07:00"
    ],
    "pressure_msl": [1015.0, 1015.1, 1015.0, 1014.9, 1014.8, 1014.9, 1015.0, 1015.1],
    "temperature_2m": [18.5, 18.2, 18.0, 17.9, 17.8, 18.1, 18.5, 19.2],
    "relative_humidity_2m": [55, 56, 57, 58, 58, 56, 54, 52]
  }
}
```

Create `test/data/sources/fixtures/open_meteo/forecast_pressure_drop.json`:

```json
{
  "latitude": 40.7,
  "longitude": -74.0,
  "timezone": "UTC",
  "hourly": {
    "time": [
      "2026-06-10T06:00", "2026-06-10T12:00", "2026-06-10T18:00",
      "2026-06-11T00:00", "2026-06-11T06:00"
    ],
    "pressure_msl": [1020.0, 1017.0, 1013.0, 1009.0, 1006.0],
    "temperature_2m": [18.0, 19.5, 20.1, 18.7, 18.0],
    "relative_humidity_2m": [50, 55, 62, 68, 70]
  }
}
```

Create `test/data/sources/fixtures/open_meteo/air_quality_typical.json`:

```json
{
  "latitude": 40.7,
  "longitude": -74.0,
  "timezone": "UTC",
  "hourly": {
    "time": ["2026-06-10T06:00", "2026-06-10T12:00", "2026-06-10T18:00", "2026-06-11T00:00"],
    "pm2_5": [12.0, 15.0, 22.0, 28.0]
  }
}
```

- [ ] **Step 2: Write failing test**

Create `test/data/sources/open_meteo_parser_test.dart`:

```dart
import 'dart:io';

import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_weatherr/data/sources/open_meteo/open_meteo_parser.dart';

void main() {
  test('parses a typical forecast into a WeatherSeries', () {
    final json = File('test/data/sources/fixtures/open_meteo/forecast_typical_day.json').readAsStringSync();
    final series = OpenMeteoParser.parseForecast(json);
    expect(series.samples, hasLength(8));
    expect(series.samples.first.pressureMsl, 1015.0);
    expect(series.samples.first.at, DateTime.utc(2026, 6, 10, 0));
    expect(series.samples.first.humidityPct, 55);
  });

  test('parses a pressure-drop scenario and the WeatherSeries surfaces the drop', () {
    final json = File('test/data/sources/fixtures/open_meteo/forecast_pressure_drop.json').readAsStringSync();
    final series = OpenMeteoParser.parseForecast(json);
    final drop = series.maxPressureDropOver(const Duration(hours: 24));
    expect(drop, closeTo(14.0, 0.1)); // 1020 -> 1006 over 24h
  });

  test('parses air quality JSON', () {
    final json = File('test/data/sources/fixtures/open_meteo/air_quality_typical.json').readAsStringSync();
    final aq = OpenMeteoParser.parseAirQuality(json);
    expect(aq.samples, hasLength(4));
    expect(aq.samples.last.pm25, 28.0);
  });

  test('throws on malformed JSON', () {
    expect(() => OpenMeteoParser.parseForecast('not json'), throwsFormatException);
  });
}
```

- [ ] **Step 3: Run — expect FAIL**

```bash
flutter test test/data/sources/open_meteo_parser_test.dart
```

- [ ] **Step 4: Implement parser**

Create `lib/data/sources/open_meteo/open_meteo_parser.dart`:

```dart
import 'dart:convert';

import 'package:domain/domain.dart';

class OpenMeteoParser {
  static WeatherSeries parseForecast(String body) {
    final root = jsonDecode(body) as Map<String, Object?>;
    final hourly = root['hourly'] as Map<String, Object?>?;
    if (hourly == null) {
      throw const FormatException('Open-Meteo response missing "hourly"');
    }
    final times = (hourly['time'] as List).cast<String>();
    final pressures = (hourly['pressure_msl'] as List).cast<num>();
    final temps = (hourly['temperature_2m'] as List).cast<num>();
    final humidities = (hourly['relative_humidity_2m'] as List).cast<num>();
    final samples = <WeatherSample>[];
    for (var i = 0; i < times.length; i++) {
      samples.add(WeatherSample(
        at: _parseUtc(times[i]),
        pressureMsl: pressures[i].toDouble(),
        temperatureC: temps[i].toDouble(),
        humidityPct: humidities[i].toDouble(),
      ));
    }
    return WeatherSeries(samples: samples);
  }

  static AirQualitySeries parseAirQuality(String body) {
    final root = jsonDecode(body) as Map<String, Object?>;
    final hourly = root['hourly'] as Map<String, Object?>?;
    if (hourly == null) {
      throw const FormatException('Open-Meteo AQ response missing "hourly"');
    }
    final times = (hourly['time'] as List).cast<String>();
    final pm25 = (hourly['pm2_5'] as List).cast<num>();
    final samples = <AirQualitySample>[];
    for (var i = 0; i < times.length; i++) {
      samples.add(AirQualitySample(at: _parseUtc(times[i]), pm25: pm25[i].toDouble()));
    }
    return AirQualitySeries(samples: samples);
  }

  static DateTime _parseUtc(String s) =>
      DateTime.parse(s.endsWith('Z') || s.contains('+') ? s : '${s}Z');
}
```

- [ ] **Step 5: Run**

```bash
flutter test test/data/sources/open_meteo_parser_test.dart
```

Expected: 4 passing.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "data: Open-Meteo response parser + fixtures"
```

---

## Task 7: OpenMeteoWeatherSource (HTTP + caching)

**Files:**
- Create: `lib/data/sources/open_meteo/open_meteo_weather_source.dart`
- Test: `test/data/sources/open_meteo_weather_source_test.dart`

- [ ] **Step 1: Write failing test**

Create `test/data/sources/open_meteo_weather_source_test.dart`:

```dart
import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:migraine_weatherr/data/database.dart';
import 'package:migraine_weatherr/data/sources/open_meteo/open_meteo_weather_source.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase.memory());
  tearDown(() => db.close());

  Future<String> _fx(String name) async => File('test/data/sources/fixtures/open_meteo/$name').readAsString();

  test('fetches once and caches within freshness window', () async {
    var calls = 0;
    final client = MockClient((req) async {
      calls++;
      if (req.url.host == 'api.open-meteo.com') {
        return http.Response(await _fx('forecast_typical_day.json'), 200);
      }
      return http.Response(await _fx('air_quality_typical.json'), 200);
    });
    final source = OpenMeteoWeatherSource(client: client, db: db, freshness: const Duration(hours: 1));
    final now = DateTime.utc(2026, 6, 10, 6);
    final first = await source.fetch(lat: 40.7, lon: -74.0, now: now);
    expect(first.stale, isFalse);
    expect(calls, 2);

    // 30 minutes later, no new HTTP calls.
    final second = await source.fetch(lat: 40.7, lon: -74.0, now: now.add(const Duration(minutes: 30)));
    expect(second.stale, isFalse);
    expect(calls, 2);
  });

  test('returns stale snapshot when network fails after cache expires', () async {
    var calls = 0;
    final client = MockClient((req) async {
      calls++;
      if (calls <= 2) {
        return http.Response(
          req.url.host == 'api.open-meteo.com'
              ? await _fx('forecast_typical_day.json')
              : await _fx('air_quality_typical.json'),
          200,
        );
      }
      throw const SocketException('offline');
    });
    final source = OpenMeteoWeatherSource(client: client, db: db, freshness: const Duration(hours: 1));
    final now = DateTime.utc(2026, 6, 10, 6);
    await source.fetch(lat: 40.7, lon: -74.0, now: now);

    final stale = await source.fetch(lat: 40.7, lon: -74.0, now: now.add(const Duration(hours: 3)));
    expect(stale.stale, isTrue);
    expect(stale.weather.samples, isNotEmpty);
  });
}
```

- [ ] **Step 2: Run — expect FAIL**

```bash
flutter test test/data/sources/open_meteo_weather_source_test.dart
```

- [ ] **Step 3: Implement**

Create `lib/data/sources/open_meteo/open_meteo_weather_source.dart`:

```dart
import 'package:domain/domain.dart';
import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;

import '../../database.dart';
import '../weather_source.dart';
import 'open_meteo_parser.dart';
import 'open_meteo_url_builder.dart';

class OpenMeteoWeatherSource implements WeatherSource {
  final http.Client client;
  final AppDatabase db;
  final Duration freshness;

  OpenMeteoWeatherSource({
    required this.client,
    required this.db,
    this.freshness = const Duration(hours: 1),
  });

  @override
  Future<WeatherSnapshot> fetch({required double lat, required double lon, required DateTime now}) async {
    final cached = await _latestCached(lat, lon);
    if (cached != null && now.difference(cached.fetchedAt) <= freshness) {
      return _toSnapshot(cached, stale: false);
    }
    try {
      final forecastRes = await client.get(OpenMeteoUrlBuilder.forecast(lat: lat, lon: lon));
      final aqRes = await client.get(OpenMeteoUrlBuilder.airQuality(lat: lat, lon: lon));
      if (forecastRes.statusCode >= 400 || aqRes.statusCode >= 400) {
        if (cached != null) return _toSnapshot(cached, stale: true);
        throw StateError('Open-Meteo fetch failed (no cache)');
      }
      await db.into(db.weatherSnapshots).insert(
            WeatherSnapshotsCompanion.insert(
              fetchedAt: now,
              lat: lat,
              lon: lon,
              forecastJson: forecastRes.body,
              airQualityJson: Value(aqRes.body),
            ),
          );
      return WeatherSnapshot(
        weather: OpenMeteoParser.parseForecast(forecastRes.body),
        airQuality: OpenMeteoParser.parseAirQuality(aqRes.body),
        fetchedAt: now,
        stale: false,
      );
    } catch (_) {
      if (cached != null) return _toSnapshot(cached, stale: true);
      rethrow;
    }
  }

  Future<WeatherSnapshotsData?> _latestCached(double lat, double lon) async {
    final q = db.select(db.weatherSnapshots)
      ..where((t) => t.lat.equals(lat) & t.lon.equals(lon))
      ..orderBy([(t) => OrderingTerm.desc(t.fetchedAt)])
      ..limit(1);
    final rows = await q.get();
    return rows.isEmpty ? null : rows.first;
  }

  WeatherSnapshot _toSnapshot(WeatherSnapshotsData row, {required bool stale}) => WeatherSnapshot(
        weather: OpenMeteoParser.parseForecast(row.forecastJson),
        airQuality: row.airQualityJson == null
            ? const AirQualitySeries(samples: [])
            : OpenMeteoParser.parseAirQuality(row.airQualityJson!),
        fetchedAt: row.fetchedAt,
        stale: stale,
      );
}
```

- [ ] **Step 4: Run**

```bash
flutter test test/data/sources/open_meteo_weather_source_test.dart
```

Expected: 2 passing.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "data: OpenMeteoWeatherSource with Drift-backed cache + stale fallback"
```

---

## Task 8: HealthSource interface + FakeHealthSource

**Files:**
- Create: `lib/data/sources/health_source.dart`
- Create: `lib/data/sources/fake_health_source.dart`
- Test: `test/data/sources/fake_health_source_test.dart`

- [ ] **Step 1: Write failing test**

Create `test/data/sources/fake_health_source_test.dart`:

```dart
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_weatherr/data/sources/fake_health_source.dart';
import 'package:migraine_weatherr/data/sources/health_source.dart';

void main() {
  test('returns canned values for each call', () async {
    final fake = FakeHealthSource()
      ..sleep = [
        SleepRecord(
          night: DateTime.utc(2026, 6, 9),
          totalSleep: const Duration(hours: 7),
          efficiency: 0.9,
          sleepStart: DateTime.utc(2026, 6, 9, 22),
        ),
      ]
      ..hrv = [HrvSample(at: DateTime.utc(2026, 6, 10), rmssdMs: 50)];
    final metrics = await fake.recentMetrics(window: const Duration(days: 14));
    expect(metrics.recentSleep, hasLength(1));
    expect(metrics.recentHrv, hasLength(1));
    expect(metrics.menstrualHistory, isEmpty);
  });

  test('permission denial yields empty metrics for that category', () async {
    final fake = FakeHealthSource()..granted = {HealthCategory.sleep};
    fake.sleep = [
      SleepRecord(
        night: DateTime.utc(2026, 6, 9),
        totalSleep: const Duration(hours: 7),
        efficiency: 0.9,
        sleepStart: DateTime.utc(2026, 6, 9, 22),
      ),
    ];
    fake.hrv = [HrvSample(at: DateTime.utc(2026, 6, 10), rmssdMs: 50)];
    final metrics = await fake.recentMetrics(window: const Duration(days: 14));
    expect(metrics.recentSleep, hasLength(1));
    expect(metrics.recentHrv, isEmpty); // hrv permission not granted
  });
}
```

- [ ] **Step 2: Run — expect FAIL**

```bash
flutter test test/data/sources/fake_health_source_test.dart
```

- [ ] **Step 3: Implement interface + fake**

Create `lib/data/sources/health_source.dart`:

```dart
import 'package:domain/domain.dart';

enum HealthCategory { sleep, hrv, menstrual }

abstract class HealthSource {
  /// Returns metrics over the given window for each granted category.
  Future<HealthMetrics> recentMetrics({required Duration window});

  /// Request permissions for the specified categories. Returns the categories
  /// that ended up granted (subset of [categories]).
  Future<Set<HealthCategory>> requestPermissions(Set<HealthCategory> categories);

  Set<HealthCategory> get grantedCategories;
}
```

Create `lib/data/sources/fake_health_source.dart`:

```dart
import 'package:domain/domain.dart';

import 'health_source.dart';

class FakeHealthSource implements HealthSource {
  List<SleepRecord> sleep = const [];
  List<HrvSample> hrv = const [];
  List<MenstrualEvent> menstrual = const [];
  Set<HealthCategory> granted = HealthCategory.values.toSet();

  @override
  Future<HealthMetrics> recentMetrics({required Duration window}) async {
    return HealthMetrics(
      recentSleep: granted.contains(HealthCategory.sleep) ? sleep : const [],
      recentHrv: granted.contains(HealthCategory.hrv) ? hrv : const [],
      menstrualHistory:
          granted.contains(HealthCategory.menstrual) ? menstrual : const [],
    );
  }

  @override
  Future<Set<HealthCategory>> requestPermissions(Set<HealthCategory> categories) async {
    granted = {...granted, ...categories};
    return granted.intersection(categories);
  }

  @override
  Set<HealthCategory> get grantedCategories => granted;
}
```

- [ ] **Step 4: Run**

```bash
flutter test test/data/sources/fake_health_source_test.dart
```

Expected: 2 passing.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "data: HealthSource interface + FakeHealthSource"
```

---

## Task 9: HealthPackageSource (real `health` plugin wrapper)

**Files:**
- Create: `lib/data/sources/health_package_source.dart`

This wraps `package:health` for the production app. **No unit tests** — the plugin requires platform channels and can't run in `flutter test` for Dart-only logic. We test the interface via the fake (Task 8); we'll smoke-test this implementation manually before Plan 3 ships.

- [ ] **Step 1: Implement**

Create `lib/data/sources/health_package_source.dart`:

```dart
import 'package:domain/domain.dart';
import 'package:health/health.dart';

import 'health_source.dart';

class HealthPackageSource implements HealthSource {
  final Health _health;
  final Set<HealthCategory> _granted = {};

  HealthPackageSource({Health? health}) : _health = health ?? Health();

  static const _typeMap = <HealthCategory, List<HealthDataType>>{
    HealthCategory.sleep: [
      HealthDataType.SLEEP_SESSION,
      HealthDataType.SLEEP_IN_BED,
    ],
    HealthCategory.hrv: [HealthDataType.HEART_RATE_VARIABILITY_SDNN],
    HealthCategory.menstrual: [HealthDataType.MENSTRUATION_FLOW],
  };

  @override
  Set<HealthCategory> get grantedCategories => Set.of(_granted);

  @override
  Future<Set<HealthCategory>> requestPermissions(Set<HealthCategory> categories) async {
    final types = categories.expand((c) => _typeMap[c] ?? const <HealthDataType>[]).toList();
    final permissions = List.filled(types.length, HealthDataAccess.READ);
    final granted = await _health.requestAuthorization(types, permissions: permissions);
    if (granted) {
      _granted.addAll(categories);
    }
    return Set.of(_granted).intersection(categories);
  }

  @override
  Future<HealthMetrics> recentMetrics({required Duration window}) async {
    final end = DateTime.now();
    final start = end.subtract(window);
    final sleep = _granted.contains(HealthCategory.sleep) ? await _fetchSleep(start, end) : <SleepRecord>[];
    final hrv = _granted.contains(HealthCategory.hrv) ? await _fetchHrv(start, end) : <HrvSample>[];
    final menstrual = _granted.contains(HealthCategory.menstrual) ? await _fetchMenstrual(start, end) : <MenstrualEvent>[];
    return HealthMetrics(recentSleep: sleep, recentHrv: hrv, menstrualHistory: menstrual);
  }

  Future<List<SleepRecord>> _fetchSleep(DateTime start, DateTime end) async {
    try {
      final points = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: end,
        types: [HealthDataType.SLEEP_SESSION, HealthDataType.SLEEP_IN_BED],
      );
      final byNight = <DateTime, List<HealthDataPoint>>{};
      for (final p in points) {
        final night = DateTime.utc(p.dateFrom.year, p.dateFrom.month, p.dateFrom.day);
        byNight.putIfAbsent(night, () => []).add(p);
      }
      return byNight.entries.map((e) {
        final session = e.value.firstWhere(
          (p) => p.type == HealthDataType.SLEEP_SESSION,
          orElse: () => e.value.first,
        );
        final inBed = e.value.firstWhere(
          (p) => p.type == HealthDataType.SLEEP_IN_BED,
          orElse: () => session,
        );
        final totalSleep = session.dateTo.difference(session.dateFrom);
        final inBedDuration = inBed.dateTo.difference(inBed.dateFrom);
        final efficiency = inBedDuration.inMinutes == 0
            ? 1.0
            : totalSleep.inMinutes / inBedDuration.inMinutes;
        return SleepRecord(
          night: e.key,
          totalSleep: totalSleep,
          efficiency: efficiency.clamp(0.0, 1.0).toDouble(),
          sleepStart: session.dateFrom,
        );
      }).toList()
        ..sort((a, b) => b.night.compareTo(a.night));
    } catch (_) {
      return const [];
    }
  }

  Future<List<HrvSample>> _fetchHrv(DateTime start, DateTime end) async {
    try {
      final points = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: end,
        types: const [HealthDataType.HEART_RATE_VARIABILITY_SDNN],
      );
      return points
          .map((p) => HrvSample(at: p.dateFrom, rmssdMs: (p.value as num).toDouble()))
          .toList()
        ..sort((a, b) => b.at.compareTo(a.at));
    } catch (_) {
      return const [];
    }
  }

  Future<List<MenstrualEvent>> _fetchMenstrual(DateTime start, DateTime end) async {
    try {
      final points = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: end,
        types: const [HealthDataType.MENSTRUATION_FLOW],
      );
      // Detect onsets: first flow record per >2-day gap.
      final dates = points.map((p) => DateTime.utc(p.dateFrom.year, p.dateFrom.month, p.dateFrom.day)).toSet().toList()
        ..sort();
      final onsets = <DateTime>[];
      for (var i = 0; i < dates.length; i++) {
        if (i == 0 || dates[i].difference(dates[i - 1]).inDays > 2) {
          onsets.add(dates[i]);
        }
      }
      return onsets.map((d) => MenstrualEvent(onsetDate: d)).toList()
        ..sort((a, b) => b.onsetDate.compareTo(a.onsetDate));
    } catch (_) {
      return const [];
    }
  }
}
```

- [ ] **Step 2: Verify it compiles**

```bash
cd /Users/amansur/projects/migraine-weatherr && flutter analyze lib/data/sources/health_package_source.dart
```

Expected: no errors. Some `health` package types may need API tweaks — if so, consult the latest `health` docs and adjust. If there's a 1-line API drift, fix it; if it's a structural mismatch, report it.

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "data: HealthPackageSource wrapper around health plugin"
```

---

## Task 10: LocationSource interface + manual impl

**Files:**
- Create: `lib/data/sources/location_source.dart`
- Create: `lib/data/sources/manual_location_source.dart`
- Test: `test/data/sources/manual_location_source_test.dart`

- [ ] **Step 1: Write failing test**

Create `test/data/sources/manual_location_source_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_weatherr/data/sources/manual_location_source.dart';

void main() {
  test('round-trips a set location', () async {
    final src = ManualLocationSource();
    expect(await src.current(), isNull);
    await src.set(lat: 40.7128, lon: -74.0060, label: 'New York');
    final loc = await src.current();
    expect(loc?.lat, 40.7128);
    expect(loc?.lon, -74.0060);
    expect(loc?.label, 'New York');
  });
}
```

- [ ] **Step 2: Run — expect FAIL**

```bash
flutter test test/data/sources/manual_location_source_test.dart
```

- [ ] **Step 3: Implement**

Create `lib/data/sources/location_source.dart`:

```dart
class UserLocation {
  final double lat;
  final double lon;
  final String? label;
  const UserLocation({required this.lat, required this.lon, this.label});
}

abstract class LocationSource {
  Future<UserLocation?> current();
}
```

Create `lib/data/sources/manual_location_source.dart`:

```dart
import 'location_source.dart';

/// In-memory location store. The device-GPS implementation is wired in Plan 3
/// using `geolocator`; for Plan 2 tests + headless usage, callers set the
/// location explicitly.
class ManualLocationSource implements LocationSource {
  UserLocation? _value;

  Future<void> set({required double lat, required double lon, String? label}) async {
    _value = UserLocation(lat: lat, lon: lon, label: label);
  }

  @override
  Future<UserLocation?> current() async => _value;
}
```

- [ ] **Step 4: Run**

```bash
flutter test test/data/sources/manual_location_source_test.dart
```

Expected: 1 passing.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "data: LocationSource interface + ManualLocationSource"
```

---

## Task 11: AssessmentRepository

**Files:**
- Create: `lib/data/repos/assessment_repository.dart`
- Test: `test/data/repos/assessment_repository_test.dart`

- [ ] **Step 1: Write failing test**

Create `test/data/repos/assessment_repository_test.dart`:

```dart
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_weatherr/data/database.dart';
import 'package:migraine_weatherr/data/repos/assessment_repository.dart';

void main() {
  late AppDatabase db;
  late AssessmentRepository repo;
  setUp(() {
    db = AppDatabase.memory();
    repo = AssessmentRepository(db);
  });
  tearDown(() => db.close());

  RiskAssessment _ass({int score = 50, RiskBand band = RiskBand.high, DateTime? date}) => RiskAssessment(
        score: score,
        band: band,
        contributors: [
          TriggerSignal(
            moduleId: 'pressure_drop',
            weight: 18,
            confidence: 1.0,
            explanation: 'Pressure dropping 12 hPa',
          ),
        ],
        computedAt: DateTime.utc(2026, 6, 10, 6),
        configVersion: 1,
        targetDate: date ?? DateTime.utc(2026, 6, 10),
        horizon: RiskHorizon.today,
      );

  test('save then look up by date+horizon', () async {
    final id = await repo.save(_ass());
    expect(id, isPositive);
    final latest = await repo.latestForDate(
      target: DateTime.utc(2026, 6, 10),
      horizon: RiskHorizon.today,
    );
    expect(latest?.score, 50);
    expect(latest?.contributors.first.moduleId, 'pressure_drop');
  });

  test('activeAt returns the most recent assessment at or before the given time', () async {
    await repo.save(_ass(score: 30));
    await repo.save(_ass(score: 60).copyWithComputedAt(DateTime.utc(2026, 6, 10, 18)));
    final active = await repo.activeAt(DateTime.utc(2026, 6, 10, 20));
    expect(active?.score, 60);
  });
}

extension on RiskAssessment {
  RiskAssessment copyWithComputedAt(DateTime t) => RiskAssessment(
        score: score,
        band: band,
        contributors: contributors,
        computedAt: t,
        configVersion: configVersion,
        targetDate: targetDate,
        horizon: horizon,
      );
}
```

- [ ] **Step 2: Run — expect FAIL**

```bash
flutter test test/data/repos/assessment_repository_test.dart
```

- [ ] **Step 3: Implement**

Create `lib/data/repos/assessment_repository.dart`:

```dart
import 'dart:convert';

import 'package:domain/domain.dart';
import 'package:drift/drift.dart';

import '../database.dart';

class AssessmentRepository {
  final AppDatabase _db;
  AssessmentRepository(this._db);

  Future<int> save(RiskAssessment ass) async {
    return _db.into(_db.riskAssessments).insert(
          RiskAssessmentsCompanion.insert(
            targetDate: ass.targetDate,
            horizon: ass.horizon.name,
            score: ass.score,
            band: ass.band.name,
            computedAt: ass.computedAt,
            configVersion: ass.configVersion,
            contributorsJson: jsonEncode(ass.contributors
                .map((c) => {
                      'moduleId': c.moduleId,
                      'weight': c.weight,
                      'confidence': c.confidence,
                      'explanation': c.explanation,
                    })
                .toList()),
          ),
        );
  }

  Future<RiskAssessment?> latestForDate({
    required DateTime target,
    required RiskHorizon horizon,
  }) async {
    final rows = await (_db.select(_db.riskAssessments)
          ..where((t) => t.targetDate.equals(target) & t.horizon.equals(horizon.name))
          ..orderBy([(t) => OrderingTerm.desc(t.computedAt)])
          ..limit(1))
        .get();
    return rows.isEmpty ? null : _toDomain(rows.first);
  }

  Future<RiskAssessment?> activeAt(DateTime when) async {
    final rows = await (_db.select(_db.riskAssessments)
          ..where((t) => t.computedAt.isSmallerOrEqualValue(when))
          ..orderBy([(t) => OrderingTerm.desc(t.computedAt)])
          ..limit(1))
        .get();
    return rows.isEmpty ? null : _toDomain(rows.first);
  }

  RiskAssessment _toDomain(RiskAssessmentsData row) {
    final contributors = (jsonDecode(row.contributorsJson) as List)
        .map((e) {
          final m = e as Map<String, Object?>;
          return TriggerSignal(
            moduleId: m['moduleId'] as String,
            weight: (m['weight'] as num).toDouble(),
            confidence: (m['confidence'] as num).toDouble(),
            explanation: m['explanation'] as String,
          );
        })
        .toList();
    return RiskAssessment(
      score: row.score,
      band: RiskBand.values.firstWhere((b) => b.name == row.band),
      contributors: contributors,
      computedAt: row.computedAt,
      configVersion: row.configVersion,
      targetDate: row.targetDate,
      horizon: RiskHorizon.values.firstWhere((h) => h.name == row.horizon),
    );
  }
}
```

- [ ] **Step 4: Run**

```bash
flutter test test/data/repos/assessment_repository_test.dart
```

Expected: 2 passing.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "data: AssessmentRepository (Drift)"
```

---

## Task 12: ContextBuilder

**Files:**
- Create: `lib/data/context_builder.dart`
- Test: `test/data/context_builder_test.dart`

- [ ] **Step 1: Write failing test**

Create `test/data/context_builder_test.dart`:

```dart
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_weatherr/data/context_builder.dart';
import 'package:migraine_weatherr/data/database.dart';
import 'package:migraine_weatherr/data/repos/baseline_snapshot_builder.dart';
import 'package:migraine_weatherr/data/sources/drift_journal_source.dart';
import 'package:migraine_weatherr/data/sources/fake_health_source.dart';
import 'package:migraine_weatherr/data/sources/manual_location_source.dart';
import 'package:migraine_weatherr/data/sources/open_meteo/open_meteo_parser.dart';
import 'package:migraine_weatherr/data/sources/weather_source.dart';

class _StubWeatherSource implements WeatherSource {
  final WeatherSnapshot snap;
  _StubWeatherSource(this.snap);
  @override
  Future<WeatherSnapshot> fetch({required double lat, required double lon, required DateTime now}) async => snap;
}

void main() {
  test('builds an EvaluationContext from all adapters', () async {
    final db = AppDatabase.memory();
    addTearDown(db.close);
    final journal = DriftJournalSource(db);
    await journal.addEntry(JournalEntry(
      at: DateTime.utc(2026, 6, 10, 2),
      kind: JournalKind.stress,
      payload: {'rating': 5},
    ));

    final weather = OpenMeteoParser.parseForecast('{"hourly": {"time": ["2026-06-10T06:00"], "pressure_msl": [1012], "temperature_2m": [20], "relative_humidity_2m": [55]}}');
    final aq = const AirQualitySeries(samples: []);
    final stubWeather = _StubWeatherSource(
      WeatherSnapshot(weather: weather, airQuality: aq, fetchedAt: DateTime.utc(2026, 6, 10, 6)),
    );

    final health = FakeHealthSource();
    final location = ManualLocationSource()..set(lat: 40.7, lon: -74.0);
    final flagsRepo = _NoFlagsRepo();

    final builder = ContextBuilder(
      weather: stubWeather,
      health: health,
      journal: journal,
      location: location,
      flagsRepo: flagsRepo,
      baselineBuilder: BaselineSnapshotBuilder(const BaselineStore()),
      db: db,
    );

    final ctx = await builder.build(
      now: DateTime.utc(2026, 6, 10, 6),
      target: DateTime.utc(2026, 6, 10),
    );

    expect(ctx.weather, isNotNull);
    expect(ctx.recentJournal, hasLength(1));
    expect(ctx.userFlags.flaggedModuleIds, isEmpty);
  });
}

class _NoFlagsRepo implements UserTriggerFlagsRepo {
  @override
  Future<UserTriggerFlags> load() async => const UserTriggerFlags();
  @override
  Future<void> save(UserTriggerFlags flags) async {}
}
```

- [ ] **Step 2: Run — expect FAIL**

```bash
flutter test test/data/context_builder_test.dart
```

- [ ] **Step 3: Implement**

Create `lib/data/context_builder.dart`:

```dart
import 'package:domain/domain.dart';

import 'database.dart';
import 'repos/baseline_snapshot_builder.dart';
import 'sources/health_source.dart';
import 'sources/journal_source.dart';
import 'sources/location_source.dart';
import 'sources/weather_source.dart';

abstract class UserTriggerFlagsRepo {
  Future<UserTriggerFlags> load();
  Future<void> save(UserTriggerFlags flags);
}

class ContextBuilder {
  final WeatherSource weather;
  final HealthSource health;
  final JournalSource journal;
  final LocationSource location;
  final UserTriggerFlagsRepo flagsRepo;
  final BaselineSnapshotBuilder baselineBuilder;
  final AppDatabase db;

  const ContextBuilder({
    required this.weather,
    required this.health,
    required this.journal,
    required this.location,
    required this.flagsRepo,
    required this.baselineBuilder,
    required this.db,
  });

  Future<EvaluationContext> build({required DateTime now, required DateTime target}) async {
    final loc = await location.current();
    WeatherSnapshot? weatherSnap;
    if (loc != null) {
      try {
        weatherSnap = await weather.fetch(lat: loc.lat, lon: loc.lon, now: now);
      } catch (_) {
        weatherSnap = null;
      }
    }

    final metrics = await health.recentMetrics(window: const Duration(days: 30));
    final journalEntries = await journal.recentEntries(const Duration(days: 7), now: now);
    final attacks = await journal.recentAttacks(const Duration(days: 14), now: now);
    final flags = await flagsRepo.load();

    final baselines = baselineBuilder.build(
      sleep: metrics.recentSleep,
      hrv: metrics.recentHrv,
      pastDailyCaffeineMg: const [],   // Plan 5 will derive these from journal history
      pastPressures: const [],
    );

    return EvaluationContext(
      now: now,
      targetDate: target,
      weather: weatherSnap?.weather,
      airQuality: weatherSnap?.airQuality,
      health: metrics,
      recentJournal: journalEntries,
      recentAttacks: attacks,
      userFlags: flags,
      baselines: baselines,
    );
  }
}
```

- [ ] **Step 4: Run**

```bash
flutter test test/data/context_builder_test.dart
```

Expected: 1 passing.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "data: ContextBuilder orchestrates adapters into EvaluationContext"
```

---

## Task 13: End-to-end smoke — adapters → engine → repo

**Files:**
- Test: `test/end_to_end/plan2_smoke_test.dart`

- [ ] **Step 1: Write end-to-end test**

Create `test/end_to_end/plan2_smoke_test.dart`:

```dart
import 'package:domain/domain.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_weatherr/data/context_builder.dart';
import 'package:migraine_weatherr/data/database.dart';
import 'package:migraine_weatherr/data/repos/assessment_repository.dart';
import 'package:migraine_weatherr/data/repos/baseline_snapshot_builder.dart';
import 'package:migraine_weatherr/data/sources/drift_journal_source.dart';
import 'package:migraine_weatherr/data/sources/fake_health_source.dart';
import 'package:migraine_weatherr/data/sources/manual_location_source.dart';
import 'package:migraine_weatherr/data/sources/open_meteo/open_meteo_parser.dart';
import 'package:migraine_weatherr/data/sources/weather_source.dart';

class _StubWeather implements WeatherSource {
  final WeatherSnapshot snap;
  _StubWeather(this.snap);
  @override
  Future<WeatherSnapshot> fetch({required double lat, required double lon, required DateTime now}) async => snap;
}

class _MemFlagsRepo implements UserTriggerFlagsRepo {
  UserTriggerFlags _f = const UserTriggerFlags();
  @override
  Future<UserTriggerFlags> load() async => _f;
  @override
  Future<void> save(UserTriggerFlags flags) async => _f = flags;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('full pipeline: adapters → context → engine → save assessment', () async {
    final db = AppDatabase.memory();
    addTearDown(db.close);
    final journal = DriftJournalSource(db);
    await journal.addEntry(JournalEntry(
      at: DateTime.utc(2026, 6, 10, 2),
      kind: JournalKind.stress,
      payload: {'rating': 5},
    ));
    await journal.addEntry(JournalEntry(
      at: DateTime.utc(2026, 6, 9, 22),
      kind: JournalKind.alcohol,
      payload: {'units': 3.0},
    ));

    // Pressure-drop fixture.
    final fxText = await rootBundle.loadString('test/data/sources/fixtures/open_meteo/forecast_pressure_drop.json');
    final weather = OpenMeteoParser.parseForecast(fxText);
    final stubWeather = _StubWeather(
      WeatherSnapshot(weather: weather, airQuality: const AirQualitySeries(samples: []), fetchedAt: DateTime.utc(2026, 6, 10, 6)),
    );

    final health = FakeHealthSource()
      ..sleep = [
        SleepRecord(
          night: DateTime.utc(2026, 6, 9),
          totalSleep: const Duration(hours: 4, minutes: 30),
          efficiency: 0.78,
          sleepStart: DateTime.utc(2026, 6, 10, 1),
        ),
      ]
      ..hrv = [HrvSample(at: DateTime.utc(2026, 6, 10, 6), rmssdMs: 30)];

    final location = ManualLocationSource();
    await location.set(lat: 40.7, lon: -74.0);

    final flagsRepo = _MemFlagsRepo();
    await flagsRepo.save(const UserTriggerFlags(
      flaggedModuleIds: {'pressure_drop', 'sleep_deficit', 'alcohol', 'stress', 'hrv_letdown'},
    ));

    final builder = ContextBuilder(
      weather: stubWeather,
      health: health,
      journal: journal,
      location: location,
      flagsRepo: flagsRepo,
      baselineBuilder: BaselineSnapshotBuilder(const BaselineStore()),
      db: db,
    );

    // Load bundled config (the same one the app ships).
    final cfgText = await rootBundle.loadString('assets/rules_config_v1.json');
    final cfg = RulesConfigLoader.parse(cfgText);
    final engine = RiskEngine(modules: [
      PressureDropModule(),
      HumidityTempSwingModule(),
      AirQualityModule(),
      SleepDeficitModule(),
      HrvLetdownModule(),
      MenstrualPhaseModule(),
      RefractoryModule(),
      AlcoholModule(),
      CaffeineModule(),
      StressModule(),
      HydrationModule(),
    ]);

    final ctx = await builder.build(
      now: DateTime.utc(2026, 6, 10, 6),
      target: DateTime.utc(2026, 6, 10),
    );
    final ass = engine.evaluate(ctx, cfg, horizon: RiskHorizon.today);
    expect(ass.band, anyOf(RiskBand.high, RiskBand.veryHigh));

    final repo = AssessmentRepository(db);
    final id = await repo.save(ass);
    expect(id, isPositive);
    final reloaded = await repo.activeAt(DateTime.utc(2026, 6, 10, 6, 1));
    expect(reloaded?.score, ass.score);
  });
}
```

- [ ] **Step 2: Wire test asset access**

Edit the root `pubspec.yaml`. Under `flutter:`, make sure `assets:` already contains `assets/rules_config_v1.json` (from Plan 1) AND add the fixture directory:

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/rules_config_v1.json
    - test/data/sources/fixtures/open_meteo/
```

(Listing the fixtures as Flutter assets lets `rootBundle.loadString` find them from a widget test.)

- [ ] **Step 3: Run**

```bash
flutter test test/end_to_end/plan2_smoke_test.dart
```

Expected: 1 passing.

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "test: end-to-end Plan 2 smoke (adapters → engine → repo)"
```

---

## Task 14: CI extension

**Files:**
- Modify: `.github/workflows/ci.yaml`

- [ ] **Step 1: Add build_runner + flutter test steps**

Edit `.github/workflows/ci.yaml`. Replace the `flutter-build` job with:

```yaml
  flutter-tests:
    name: Flutter analyze + tests
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.44.1'
          channel: 'stable'
      - run: flutter pub get
      - run: dart run build_runner build --delete-conflicting-outputs
      - run: flutter analyze
      - run: flutter test
```

(Keep the existing `domain-tests` job as-is.)

- [ ] **Step 2: Sanity-check locally**

```bash
cd /Users/amansur/projects/migraine-weatherr && dart run build_runner build --delete-conflicting-outputs && flutter analyze && flutter test
```

Expected: build_runner says "Succeeded", `flutter analyze` exits 0 (infos OK), `flutter test` passes everything.

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "ci: run build_runner + flutter test in addition to domain tests"
```

---

## Done

After Task 14, you have:

- A full Drift database with seven tables backing the journal, attacks, weather cache, baselines, user flags, assessment history, and settings.
- Concrete `WeatherSource` against Open-Meteo with a Drift-backed 1-hour cache and graceful stale fallback when offline.
- `HealthSource` interface with both a production wrapper (`HealthPackageSource`) over the `health` plugin and a `FakeHealthSource` for tests/dev.
- `JournalSource`, `LocationSource`, `AssessmentRepository`, `BaselineSnapshotBuilder`, and `ContextBuilder` — every collaborator the domain `RiskEngine` needs in production.
- An end-to-end test that wires the bundled `rules_config_v1.json` through `ContextBuilder` and the engine all the way to a persisted `RiskAssessment`.

Plan 3 (App MVP) wires these adapters into Riverpod controllers and Flutter screens (Onboarding, Today, Log, Settings) and adds a `geolocator`-backed `LocationSource`. The pieces from Plan 2 don't change shape — Plan 3 is a UI/orchestration layer on top.
