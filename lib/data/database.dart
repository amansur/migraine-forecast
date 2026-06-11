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
  AppDatabase.memory() : super(nativeMemoryDatabase());

  @override
  int get schemaVersion => 1;
}

QueryExecutor _openConnection() {
  return driftDatabase(
    name: 'migraine_weatherr',
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.js'),
    ),
  );
}

AppDatabase openAppDatabase() => AppDatabase(_openConnection());
