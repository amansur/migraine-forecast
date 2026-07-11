import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/data/database.dart' hide Attack, JournalEntry, WeatherSnapshot, RiskAssessment, PeriodDaySeverity;

void main() {
  test('schemaVersion is 13 and day_location_overrides exists on fresh DB', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    expect(db.schemaVersion, 13);
    // Insert a row to prove the table exists.
    await db.into(db.dayLocationOverrides).insert(
          DayLocationOverridesCompanion.insert(
            day: DateTime.utc(2026, 6, 1),
            lat: 40.7128,
            lon: -74.0060,
            displayName: 'New York, US',
            setAt: DateTime.utc(2026, 6, 1, 10),
          ),
        );
    final rows = await db.select(db.dayLocationOverrides).get();
    expect(rows, hasLength(1));
    expect(rows.single.displayName, 'New York, US');
  });

  test('schemaVersion is 13 and manual_sleep_records still exists', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    expect(db.schemaVersion, 13);
    // Insert a row to prove the table exists.
    await db.into(db.manualSleepRecords).insert(
          ManualSleepRecordsCompanion.insert(
            night: DateTime.utc(2026, 6, 12),
            sleepStart: DateTime.utc(2026, 6, 12, 22, 30),
            totalSleepMinutes: 7 * 60 + 15,
          ),
        );
    final rows = await db.select(db.manualSleepRecords).get();
    expect(rows, hasLength(1));
    expect(rows.single.efficiency, isNull);
  });

  test('schema v5 adds Attacks.inProgress and RiskAssessments.backfilled with false defaults', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    expect(db.schemaVersion, 13);

    final attackId = await db.into(db.attacks).insert(
          AttacksCompanion.insert(
            startedAt: DateTime.utc(2026, 6, 1, 12),
            severity: 5,
          ),
        );
    final attack = await (db.select(db.attacks)..where((t) => t.id.equals(attackId))).getSingle();
    expect(attack.inProgress, isFalse);

    final assId = await db.into(db.riskAssessments).insert(
          RiskAssessmentsCompanion.insert(
            targetDate: DateTime.utc(2026, 6, 1),
            horizon: 'today',
            score: 0,
            band: 'low',
            computedAt: DateTime.utc(2026, 6, 1, 12),
            configVersion: 1,
            contributorsJson: '[]',
          ),
        );
    final ass = await (db.select(db.riskAssessments)..where((t) => t.id.equals(assId))).getSingle();
    expect(ass.backfilled, isFalse);
  });

  test('Attacks.inProgress is writable', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    final id = await db.into(db.attacks).insert(
          AttacksCompanion.insert(
            startedAt: DateTime.utc(2026, 6, 1, 12),
            severity: 5,
            inProgress: const Value(true),
          ),
        );
    final row = await (db.select(db.attacks)..where((t) => t.id.equals(id))).getSingle();
    expect(row.inProgress, isTrue);
  });

  test('schema v4 creates Periods and PeriodDaySeverities tables', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    final pid = await db.into(db.periods).insert(
          PeriodsCompanion.insert(
            startedAt: DateTime.utc(2026, 6, 10),
            baselineSeverity: 5,
          ),
        );
    expect(pid, isPositive);

    await db.into(db.periodDaySeverities).insert(
          PeriodDaySeveritiesCompanion.insert(
            day: DateTime.utc(2026, 6, 11),
            severity: 7,
          ),
        );
    final overrides = await db.select(db.periodDaySeverities).get();
    expect(overrides, hasLength(1));
    expect(overrides.first.severity, 7);
  });

  test('v6: weather_snapshots.source column defaults to forecast', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    // Insert a row without specifying source — the column default must apply.
    final id = await db.into(db.weatherSnapshots).insert(
          WeatherSnapshotsCompanion.insert(
            fetchedAt: DateTime.utc(2026, 6, 1, 12),
            lat: 37.7,
            lon: -122.4,
            forecastJson: '{}',
          ),
        );

    final row = await (db.select(db.weatherSnapshots)..where((t) => t.id.equals(id))).getSingle();
    expect(row.source, 'forecast');
  });

  test('v12: oura_sleep.average_heart_rate stores fractional BPM without rounding', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    expect(db.schemaVersion, 13);

    // Insert a row with a fractional average_heart_rate value.
    await db.into(db.ouraSleep).insert(
          OuraSleepCompanion.insert(
            id: 'test-sleep-1',
            day: DateTime.utc(2026, 6, 15),
            fetchedAt: DateTime.utc(2026, 6, 15, 8),
            averageHeartRate: const Value(52.5),
          ),
        );
    final rows = await db.select(db.ouraSleep).get();
    expect(rows, hasLength(1));
    expect(rows.single.averageHeartRate, closeTo(52.5, 0.001));
  });

  test('v6: weather_snapshots.source can be set to archive', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    final id = await db.into(db.weatherSnapshots).insert(
          WeatherSnapshotsCompanion.insert(
            fetchedAt: DateTime.utc(2026, 6, 1, 12),
            lat: 37.7,
            lon: -122.4,
            forecastJson: '{}',
            source: const Value('archive'),
          ),
        );

    final row = await (db.select(db.weatherSnapshots)..where((t) => t.id.equals(id))).getSingle();
    expect(row.source, 'archive');
  });

  test('v13: day_checkins table exists and accepts inserts on fresh DB', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    expect(db.schemaVersion, 13);
    await db.into(db.dayCheckins).insert(
          DayCheckinsCompanion.insert(
            day: DateTime.utc(2026, 7, 10),
            hadAttack: false,
            answeredAt: DateTime.utc(2026, 7, 11, 9),
          ),
        );
    final rows = await db.select(db.dayCheckins).get();
    expect(rows, hasLength(1));
    expect(rows.single.hadAttack, isFalse);
  });
}
