import 'package:drift/drift.dart';

class OuraSleep extends Table {
  TextColumn get id => text()();
  DateTimeColumn get day => dateTime()();
  IntColumn get sleepScore => integer().nullable()();
  IntColumn get lowestHeartRate => integer().nullable()();
  IntColumn get restlessPeriods => integer().nullable()();
  IntColumn get averageHeartRate => integer().nullable()();
  IntColumn get averageHrv => integer().nullable()();
  DateTimeColumn get fetchedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class OuraActivity extends Table {
  TextColumn get id => text()();
  DateTimeColumn get day => dateTime()();
  IntColumn get activityScore => integer().nullable()();
  DateTimeColumn get fetchedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class OuraReadiness extends Table {
  TextColumn get id => text()();
  DateTimeColumn get day => dateTime()();
  IntColumn get readinessScore => integer().nullable()();
  RealColumn get temperatureDeviation => real().nullable()();
  DateTimeColumn get fetchedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
