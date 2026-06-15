import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'native_database.dart'
    if (dart.library.js_interop) 'native_database_web.dart';
import 'database/oura_tables.dart';

part 'database.g.dart';

class Attacks extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  IntColumn get severity => integer()();
  TextColumn get notes => text().nullable()();
  IntColumn get riskAssessmentId => integer().nullable()();
  BoolColumn get inProgress => boolean().withDefault(const Constant(false))();
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
  TextColumn get forecastJson => text()();
  TextColumn get airQualityJson => text().nullable()();
  TextColumn get source => text().withDefault(const Constant('forecast'))();
  // Coverage window: the earliest and latest timestamps present in forecastJson.
  // Null on rows written before v7 (backfilled in the v7 migration from forecastJson).
  // The cache lookup uses these to find rows whose series *covers* the requested day,
  // enabling a single prime fetch to satisfy the entire per-day backfill loop.
  DateTimeColumn get coverageStart => dateTime().nullable()();
  DateTimeColumn get coverageEnd => dateTime().nullable()();
}

class BaselinesKv extends Table {
  TextColumn get key => text()();
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
  TextColumn get band => text()();
  DateTimeColumn get computedAt => dateTime()();
  IntColumn get configVersion => integer()();
  TextColumn get contributorsJson => text()();
  BoolColumn get backfilled => boolean().withDefault(const Constant(false))();

  @override
  List<Set<Column>> get uniqueKeys => [
        {targetDate, horizon},
      ];
}

class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  @override
  Set<Column> get primaryKey => {key};
}

class NotificationsSent extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get targetDate => dateTime()();
  TextColumn get horizon => text()(); // 'today' | 'tomorrow'
  TextColumn get band => text()(); // 'high' | 'veryHigh'
  DateTimeColumn get sentAt => dateTime()();
}

class Periods extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  IntColumn get baselineSeverity => integer()();
}

class PeriodDaySeverities extends Table {
  DateTimeColumn get day => dateTime()();
  IntColumn get severity => integer()();
  @override
  Set<Column> get primaryKey => {day};
}

class ManualSleepRecords extends Table {
  // UTC midnight of the night the sleep belongs to.
  DateTimeColumn get night => dateTime()();
  DateTimeColumn get sleepStart => dateTime()();
  IntColumn get totalSleepMinutes => integer()();
  RealColumn get efficiency => real().nullable()();
  @override
  Set<Column> get primaryKey => {night};
}

/// Stores a user-chosen location for a specific calendar day (UTC midnight).
/// When a day has an override, ContextBuilder uses its (lat, lon) instead of
/// the live GPS/manual location, so that historical risk assessments reflect
/// where the user actually was (e.g. while travelling).
class DayLocationOverrides extends Table {
  /// UTC midnight of the calendar day this override applies to.
  DateTimeColumn get day => dateTime()();
  RealColumn get lat => real()();
  RealColumn get lon => real()();
  TextColumn get displayName => text()();
  /// When the override was set — for audit and future "revert" capability.
  DateTimeColumn get setAt => dateTime()();
  @override
  Set<Column> get primaryKey => {day};
}

@DriftDatabase(tables: [
  Attacks,
  JournalEntries,
  WeatherSnapshots,
  BaselinesKv,
  UserTriggerFlagsTbl,
  RiskAssessments,
  Settings,
  NotificationsSent,
  Periods,
  PeriodDaySeverities,
  ManualSleepRecords,
  DayLocationOverrides,
  OuraSleep,
  OuraDailySleep,
  OuraActivity,
  OuraReadiness,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);
  AppDatabase.memory() : super(nativeMemoryDatabase());

  @override
  int get schemaVersion => 12;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) await m.createTable(notificationsSent);
          if (from < 3) {
            await m.addColumn(attacks, attacks.inProgress);
            await m.addColumn(riskAssessments, riskAssessments.backfilled);
          }
          if (from < 4) {
            await m.createTable(periods);
            await m.createTable(periodDaySeverities);
          }
          if (from < 5) {
            // Adds unique index on (targetDate, horizon) for idempotent upsert.
            // Pre-v5 the existing RiskAssessmentNotifier.backfill could append
            // duplicate (target_date, horizon) rows when an attack was logged
            // twice for the same day. Dedupe (keeping the most recent id, which
            // corresponds to the latest computedAt) before creating the index,
            // otherwise CREATE UNIQUE INDEX throws on existing duplicates.
            await customStatement(
              'DELETE FROM risk_assessments WHERE id NOT IN ('
              'SELECT MAX(id) FROM risk_assessments GROUP BY target_date, horizon'
              ')',
            );
            await customStatement(
              'CREATE UNIQUE INDEX IF NOT EXISTS risk_assessments_target_horizon '
              'ON risk_assessments (target_date, horizon)',
            );
          }
          if (from < 6) {
            await m.addColumn(weatherSnapshots, weatherSnapshots.source);
          }
          if (from < 7) {
            // NOTE: The historical-location-override plan also targets a v7
            // migration. If that plan lands first, this block must be merged
            // into that migration or shipped as v8 instead.
            //
            // Add coverage window columns so the cache lookup can match on
            // which days a snapshot's series *covers* rather than when it was
            // fetched. Nullable to handle rows written before this migration;
            // the backfill below populates them from forecastJson where possible.
            await m.addColumn(weatherSnapshots, weatherSnapshots.coverageStart);
            await m.addColumn(weatherSnapshots, weatherSnapshots.coverageEnd);

            // Backfill coverage columns for existing rows by parsing forecastJson.
            // If parsing fails (corrupt JSON), leave both columns null — the
            // coverage-aware cache lookup treats null as "doesn't cover", so
            // such rows are simply re-fetched on the next backfill.
            final rows = await select(weatherSnapshots).get();
            for (final row in rows) {
              try {
                final times = extractForecastTimes(row.forecastJson);
                if (times.isEmpty) continue;
                await (update(weatherSnapshots)..where((t) => t.id.equals(row.id)))
                    .write(WeatherSnapshotsCompanion(
                  coverageStart: Value(times.first),
                  coverageEnd: Value(times.last),
                ));
              } catch (_) {
                // Leave nulls on corrupt rows — see note above.
              }
            }
          }
          if (from < 8) {
            await m.createTable(manualSleepRecords);
          }
          if (from < 9) {
            await m.createTable(dayLocationOverrides);
          }
          if (from < 10) {
            await m.createTable(ouraSleep);
            await m.createTable(ouraActivity);
            await m.createTable(ouraReadiness);
          }
          if (from < 11) {
            await m.createTable(ouraDailySleep);
            // Only databases that lived at exactly v10 contain the
            // prefix-hack rows + sleep_score column on oura_sleep. Anything
            // jumping from pre-10 straight to 11 had oura_sleep created by
            // the `from < 10` block above using the current Dart definition,
            // which already omits sleep_score — so the SELECT/DELETE/ALTER
            // below would fail with "no such column: sleep_score".
            if (from == 10) {
              await customStatement(
                'INSERT INTO oura_daily_sleep (id, day, score, fetched_at) '
                'SELECT id, day, sleep_score, fetched_at FROM oura_sleep '
                "WHERE id LIKE 'daily_%'",
              );
              await customStatement(
                "DELETE FROM oura_sleep WHERE id LIKE 'daily_%'",
              );
              await customStatement(
                'ALTER TABLE oura_sleep DROP COLUMN sleep_score',
              );
            }
          }
          if (from < 12) {
            // averageHeartRate column changed from INTEGER to REAL so that
            // fractional BPM values from the live API are preserved in cache.
            // SQLite does not support ALTER COLUMN, so we use the
            // rename-create-copy-drop dance.
            await customStatement(
              'ALTER TABLE oura_sleep RENAME TO oura_sleep_old',
            );
            await customStatement(
              'CREATE TABLE oura_sleep ('
              '  id TEXT NOT NULL PRIMARY KEY,'
              '  day INTEGER NOT NULL,'
              '  lowest_heart_rate INTEGER,'
              '  restless_periods INTEGER,'
              '  average_heart_rate REAL,'
              '  average_hrv INTEGER,'
              '  fetched_at INTEGER NOT NULL'
              ')',
            );
            await customStatement(
              'INSERT INTO oura_sleep '
              '  (id, day, lowest_heart_rate, restless_periods, average_heart_rate, average_hrv, fetched_at) '
              'SELECT '
              '  id, day, lowest_heart_rate, restless_periods, CAST(average_heart_rate AS REAL), average_hrv, fetched_at '
              'FROM oura_sleep_old',
            );
            await customStatement('DROP TABLE oura_sleep_old');
          }
        },
      );

  /// Parses [forecastJson] and returns the hourly timestamps as UTC [DateTime]
  /// objects. Returns an empty list if the JSON is missing a "time" array.
  /// Throws on malformed JSON so callers can catch and leave coverage null.
  static List<DateTime> extractForecastTimes(String forecastJson) {
    final root = jsonDecode(forecastJson) as Map<String, Object?>;
    final hourly = root['hourly'] as Map<String, Object?>?;
    if (hourly == null) return const [];
    final times = hourly['time'] as List?;
    if (times == null) return const [];
    return times
        .cast<String>()
        .map((s) => DateTime.parse(s.endsWith('Z') || s.contains('+') ? s : '${s}Z'))
        .toList();
  }

  Selectable<OuraSleepData> get allOuraSleep => select(ouraSleep);
  Selectable<OuraDailySleepData> get allOuraDailySleep => select(ouraDailySleep);
  Selectable<OuraActivityData> get allOuraActivity => select(ouraActivity);
  Selectable<OuraReadinessData> get allOuraReadiness => select(ouraReadiness);

  // ---------------------------------------------------------------------------
  // Oura upsert helpers
  // ---------------------------------------------------------------------------

  Future<void> upsertOuraSleep(List<OuraSleepCompanion> rows) async {
    await batch((b) {
      b.insertAll(ouraSleep, rows, mode: InsertMode.insertOrReplace);
    });
  }

  Future<void> upsertOuraDailySleep(List<OuraDailySleepCompanion> rows) async {
    await batch((b) {
      b.insertAll(ouraDailySleep, rows, mode: InsertMode.insertOrReplace);
    });
  }

  Future<void> upsertOuraActivity(List<OuraActivityCompanion> rows) async {
    await batch((b) {
      b.insertAll(ouraActivity, rows, mode: InsertMode.insertOrReplace);
    });
  }

  Future<void> upsertOuraReadiness(List<OuraReadinessCompanion> rows) async {
    await batch((b) {
      b.insertAll(ouraReadiness, rows, mode: InsertMode.insertOrReplace);
    });
  }

  // ---------------------------------------------------------------------------
  // Oura cache reads
  // ---------------------------------------------------------------------------

  Future<List<OuraSleepData>> recentOuraSleep({required Duration window}) {
    final cutoff = DateTime.now().subtract(window);
    return (select(ouraSleep)
          ..where((t) => t.day.isBiggerOrEqualValue(cutoff))
          ..orderBy([(t) => OrderingTerm.desc(t.day)]))
        .get();
  }

  Future<List<OuraDailySleepData>> recentOuraDailySleep({required Duration window}) {
    final cutoff = DateTime.now().subtract(window);
    return (select(ouraDailySleep)
          ..where((t) => t.day.isBiggerOrEqualValue(cutoff))
          ..orderBy([(t) => OrderingTerm.desc(t.day)]))
        .get();
  }

  Future<List<OuraActivityData>> recentOuraActivity({required Duration window}) {
    final cutoff = DateTime.now().subtract(window);
    return (select(ouraActivity)
          ..where((t) => t.day.isBiggerOrEqualValue(cutoff))
          ..orderBy([(t) => OrderingTerm.desc(t.day)]))
        .get();
  }

  Future<List<OuraReadinessData>> recentOuraReadiness({required Duration window}) {
    final cutoff = DateTime.now().subtract(window);
    return (select(ouraReadiness)
          ..where((t) => t.day.isBiggerOrEqualValue(cutoff))
          ..orderBy([(t) => OrderingTerm.desc(t.day)]))
        .get();
  }

  // ---------------------------------------------------------------------------
  // Oura cache eviction
  // ---------------------------------------------------------------------------

  /// Deletes rows from all four Oura tables whose [day] is older than
  /// [horizon] ago. Call this after every successful API fetch to keep the
  /// cache bounded.
  Future<void> evictStaleOuraCache({required Duration horizon}) async {
    final cutoff = DateTime.now().subtract(horizon);
    await transaction(() async {
      await (delete(ouraSleep)..where((t) => t.day.isSmallerThanValue(cutoff))).go();
      await (delete(ouraDailySleep)..where((t) => t.day.isSmallerThanValue(cutoff))).go();
      await (delete(ouraActivity)..where((t) => t.day.isSmallerThanValue(cutoff))).go();
      await (delete(ouraReadiness)..where((t) => t.day.isSmallerThanValue(cutoff))).go();
    });
  }

  Future<void> clearAllData() async {
    await transaction(() async {
      for (final table in allTables) {
        await delete(table).go();
      }
    });
  }
}

QueryExecutor _openConnection() {
  // Wrap in LazyDatabase so the legacy-filename rename can run before the
  // first SQLite open. Pre-rename DBs were called 'migraine_weatherr.sqlite';
  // we now use 'migraine_forecast.sqlite' to match the project name.
  return LazyDatabase(() async {
    await renameLegacyDbFile();
    return driftDatabase(
      name: 'migraine_forecast',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    );
  });
}

AppDatabase openAppDatabase() => AppDatabase(_openConnection());
