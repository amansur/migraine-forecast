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
  // Resolved location the assessment was scored at. Nullable: not every day has
  // a location-driven score, and pre-v16 rows are backfilled from the weather
  // cache (locationName stays null there — reverse-geocoded lazily at display).
  RealColumn get resolvedLat => real().nullable()();
  RealColumn get resolvedLon => real().nullable()();
  TextColumn get locationName => text().nullable()();

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

/// Next-morning check-in answers ("did yesterday's high-risk day bring a
/// migraine?"). One row per asked day; "no" answers are real negative data.
/// `day` follows the local-calendar-day-in-UTC-midnight-key convention.
class DayCheckins extends Table {
  DateTimeColumn get day => dateTime()();
  BoolColumn get hadAttack => boolean()();
  DateTimeColumn get answeredAt => dateTime()();
  @override
  Set<Column> get primaryKey => {day};
}

class MedicationDoses extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get at => dateTime()();
  TextColumn get name => text()();
  TextColumn get medClass => text()(); // MedClass.name
  IntColumn get reliefRating => integer().nullable()(); // 0 no, 1 some, 2 yes
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
  DayCheckins,
  MedicationDoses,
  OuraSleep,
  OuraDailySleep,
  OuraActivity,
  OuraReadiness,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);
  AppDatabase.memory() : super(nativeMemoryDatabase());

  @override
  int get schemaVersion => 19;

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
          if (from < 13) {
            await m.createTable(dayCheckins);
          }
          if (from < 14) {
            await m.createTable(medicationDoses);
          }
          if (from < 15) {
            // One-time sweep of weather rows future-stamped by the pre-fix
            // outlook code (fetchedAt used to be the requested-day anchor,
            // up to d+6 ahead). Such rows outrank genuinely newer ones in
            // the cache lookups and always fail the freshness gate, forcing
            // a network fetch on every compute until they age out.
            await (delete(weatherSnapshots)
                  ..where((t) =>
                      t.fetchedAt.isBiggerThanValue(DateTime.now().toUtc())))
                .go();
          }
          if (from < 16) {
            await _ensureResolvedLocationColumns();
            await _tryBackfillAssessmentLocations();
          }
          if (from < 17) {
            // Re-run with the broadened backfill (nearest-fetch fallback) so
            // historical days that had no exactly-covering snapshot still get a
            // real recorded location instead of showing "Location not recorded".
            await _tryBackfillAssessmentLocations();
          }
          if (from < 18) {
            // Earlier builds saved backfilled/recalculated assessments through a
            // path that dropped the resolved location (now fixed via copyWith),
            // so rows written after the v16/v17 backfill could have been nulled
            // again. Re-run the backfill to heal them.
            await _tryBackfillAssessmentLocations();
          }
          if (from < 19) {
            // Heal DBs whose v16 column-add didn't persist — notably drift's web
            // sharedIndexedDb fallback, where a migration interrupted by another
            // open tab could bump the version without applying the ALTERs.
            await _ensureResolvedLocationColumns();
            await _tryBackfillAssessmentLocations();
          }
        },
        beforeOpen: (details) async {
          // Final safety net: guarantee the resolved-location columns exist on
          // every open, regardless of how migrations played out. Idempotent, so
          // it's a no-op once the columns are present. This is what makes the
          // v18 "no column named resolved_lat" failure impossible to recur.
          await _ensureResolvedLocationColumns();
        },
      );

  /// Adds the resolved-location columns to `risk_assessments` if they are
  /// missing. Idempotent — checks `PRAGMA table_info` first — so it is safe to
  /// call from any migration step and from [beforeOpen]. Uses raw `ALTER TABLE`
  /// (not the generated schema) so it never depends on migration bookkeeping.
  Future<void> _ensureResolvedLocationColumns() async {
    final info =
        await customSelect('PRAGMA table_info(risk_assessments)').get();
    final columns = info.map((r) => r.read<String>('name')).toSet();
    if (!columns.contains('resolved_lat')) {
      await customStatement(
          'ALTER TABLE risk_assessments ADD COLUMN resolved_lat REAL');
    }
    if (!columns.contains('resolved_lon')) {
      await customStatement(
          'ALTER TABLE risk_assessments ADD COLUMN resolved_lon REAL');
    }
    if (!columns.contains('location_name')) {
      await customStatement(
          'ALTER TABLE risk_assessments ADD COLUMN location_name TEXT');
    }
  }

  /// Best-effort backfill. Wrapped so a failure (e.g. one unparseable cached
  /// row) can never roll back the column-add DDL that shares its transaction.
  Future<void> _tryBackfillAssessmentLocations() async {
    try {
      await backfillAssessmentLocations();
    } catch (_) {
      // Columns still exist; days simply show "Location not recorded" until a
      // later successful backfill or recompute fills them.
    }
  }

  /// Populates resolvedLat/resolvedLon on assessment rows that lack them from
  /// the cached weather snapshots.
  ///
  /// For each assessment we first look for a snapshot whose coverage window
  /// contains the assessment's targetDate; if none exists we fall back to the
  /// nearest snapshot by fetchedAt, but only when that fetch is within
  /// [nearestWindow] of the assessment's computedAt (default 2 days) so we
  /// never attribute a far-away fetch's location to an unrelated day. Both are
  /// real recorded fetch locations — not the user's *current* location — so
  /// history stays honest for people who travel. locationName is left null
  /// (historical name unknown; reverse-geocoded lazily at display). Returns the
  /// number of rows updated.
  Future<int> backfillAssessmentLocations({
    Duration nearestWindow = const Duration(days: 2),
  }) async {
    final snaps = await select(weatherSnapshots).get();
    if (snaps.isEmpty) return 0;
    final withCoverage = snaps
        .where((s) => s.coverageStart != null && s.coverageEnd != null)
        .toList();
    final assessments = await (select(riskAssessments)
          ..where((t) => t.resolvedLat.isNull()))
        .get();
    var updated = 0;
    for (final a in assessments) {
      final day = a.targetDate;
      final covering = withCoverage.where((s) =>
          !s.coverageStart!.isAfter(day) && !s.coverageEnd!.isBefore(day));

      WeatherSnapshot? best;
      if (covering.isNotEmpty) {
        best = covering.reduce((x, y) =>
            (x.fetchedAt.difference(a.computedAt).abs() <=
                    y.fetchedAt.difference(a.computedAt).abs())
                ? x
                : y);
      } else {
        // No covering snapshot — use the nearest fetch within the window.
        for (final s in snaps) {
          final gap = s.fetchedAt.difference(a.computedAt).abs();
          if (gap > nearestWindow) continue;
          if (best == null ||
              gap < best.fetchedAt.difference(a.computedAt).abs()) {
            best = s;
          }
        }
      }
      if (best == null) continue;

      await (update(riskAssessments)..where((t) => t.id.equals(a.id)))
          .write(RiskAssessmentsCompanion(
        resolvedLat: Value(best.lat),
        resolvedLon: Value(best.lon),
      ));
      updated++;
    }
    return updated;
  }

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
