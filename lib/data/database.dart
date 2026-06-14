import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'native_database.dart'
    if (dart.library.js_interop) 'native_database_web.dart';

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
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);
  AppDatabase.memory() : super(nativeMemoryDatabase());

  @override
  int get schemaVersion => 6;

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
            // The historical-location-override plan will require its own v6
            // migration — do not pre-add those columns here.
            //
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
        },
      );

  Future<void> clearAllData() async {
    await transaction(() async {
      for (final table in allTables) {
        await delete(table).go();
      }
    });
  }
}

QueryExecutor _openConnection() {
  // Drift DB filename kept as 'migraine_weatherr' even after the
  // migraine-weatherr → migraine-forecast rename: changing it would orphan
  // existing users' on-device data (attacks, baselines, settings).
  return driftDatabase(
    name: 'migraine_weatherr',
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.js'),
    ),
  );
}

AppDatabase openAppDatabase() => AppDatabase(_openConnection());
