import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/data/database.dart' hide Attack, JournalEntry, WeatherSnapshot, RiskAssessment, PeriodDaySeverity;

void main() {
  test('schemaVersion is 15 and day_location_overrides exists on fresh DB', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    expect(db.schemaVersion, 17);
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

  test('schemaVersion is 15 and manual_sleep_records still exists', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    expect(db.schemaVersion, 17);
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

    expect(db.schemaVersion, 17);

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
    expect(db.schemaVersion, 17);

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
    expect(db.schemaVersion, 17);
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

  test('v14: medication_doses table exists and accepts inserts on fresh DB', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    expect(db.schemaVersion, 17);
    await db.into(db.medicationDoses).insert(
          MedicationDosesCompanion.insert(
            at: DateTime.utc(2026, 7, 11, 8),
            name: 'Sumatriptan',
            medClass: 'triptan',
          ),
        );
    final rows = await db.select(db.medicationDoses).get();
    expect(rows, hasLength(1));
    expect(rows.single.reliefRating, isNull);
  });

  test('v16: risk_assessments has nullable resolved location columns', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    expect(db.schemaVersion, 17);

    final id = await db.into(db.riskAssessments).insert(
          RiskAssessmentsCompanion.insert(
            targetDate: DateTime.utc(2026, 7, 20),
            horizon: 'today',
            score: 30,
            band: 'moderate',
            computedAt: DateTime.utc(2026, 7, 20, 23),
            configVersion: 1,
            contributorsJson: '[]',
            resolvedLat: const Value(37.8044),
            resolvedLon: const Value(-122.2712),
            locationName: const Value('Oakland, California'),
          ),
        );
    final row = await (db.select(db.riskAssessments)
          ..where((t) => t.id.equals(id)))
        .getSingle();
    expect(row.resolvedLat, closeTo(37.8044, 0.0001));
    expect(row.resolvedLon, closeTo(-122.2712, 0.0001));
    expect(row.locationName, 'Oakland, California');
  });

  test('v16: resolved location columns default to null', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final id = await db.into(db.riskAssessments).insert(
          RiskAssessmentsCompanion.insert(
            targetDate: DateTime.utc(2026, 7, 21),
            horizon: 'today',
            score: 10,
            band: 'low',
            computedAt: DateTime.utc(2026, 7, 21, 23),
            configVersion: 1,
            contributorsJson: '[]',
          ),
        );
    final row = await (db.select(db.riskAssessments)
          ..where((t) => t.id.equals(id)))
        .getSingle();
    expect(row.resolvedLat, isNull);
    expect(row.resolvedLon, isNull);
    expect(row.locationName, isNull);
  });

  test('backfillAssessmentLocations copies coords from covering snapshot', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    // Snapshot covering 2026-07-20, fetched close to the assessment's compute.
    await db.into(db.weatherSnapshots).insert(WeatherSnapshotsCompanion.insert(
          fetchedAt: DateTime.utc(2026, 7, 20, 22),
          lat: 40.7128,
          lon: -74.0060,
          forecastJson: '{}',
          coverageStart: Value(DateTime.utc(2026, 7, 18)),
          coverageEnd: Value(DateTime.utc(2026, 7, 22)),
        ));
    // Far snapshot that also covers the day but fetched days earlier.
    await db.into(db.weatherSnapshots).insert(WeatherSnapshotsCompanion.insert(
          fetchedAt: DateTime.utc(2026, 7, 10, 0),
          lat: 1.0,
          lon: 2.0,
          forecastJson: '{}',
          coverageStart: Value(DateTime.utc(2026, 7, 5)),
          coverageEnd: Value(DateTime.utc(2026, 7, 25)),
        ));

    final id = await db.into(db.riskAssessments).insert(
          RiskAssessmentsCompanion.insert(
            targetDate: DateTime.utc(2026, 7, 20),
            horizon: 'today',
            score: 22,
            band: 'low',
            computedAt: DateTime.utc(2026, 7, 20, 23),
            configVersion: 1,
            contributorsJson: '[]',
          ),
        );

    final updated = await db.backfillAssessmentLocations();
    expect(updated, 1);

    final row = await (db.select(db.riskAssessments)
          ..where((t) => t.id.equals(id)))
        .getSingle();
    expect(row.resolvedLat, closeTo(40.7128, 0.0001)); // closest-fetch wins
    expect(row.locationName, isNull);
  });

  test('backfillAssessmentLocations leaves uncovered days null', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final id = await db.into(db.riskAssessments).insert(
          RiskAssessmentsCompanion.insert(
            targetDate: DateTime.utc(2026, 7, 20),
            horizon: 'today',
            score: 5,
            band: 'low',
            computedAt: DateTime.utc(2026, 7, 20, 23),
            configVersion: 1,
            contributorsJson: '[]',
          ),
        );
    final updated = await db.backfillAssessmentLocations();
    expect(updated, 0);
    final row = await (db.select(db.riskAssessments)
          ..where((t) => t.id.equals(id)))
        .getSingle();
    expect(row.resolvedLat, isNull);
  });

  test('backfill falls back to nearest fetch within window when none covers',
      () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    // No coverage window, but fetched ~1 day from the assessment's compute.
    await db.into(db.weatherSnapshots).insert(WeatherSnapshotsCompanion.insert(
          fetchedAt: DateTime.utc(2026, 7, 21, 12),
          lat: 40.6609,
          lon: -73.9613,
          forecastJson: '{}',
        ));

    final id = await db.into(db.riskAssessments).insert(
          RiskAssessmentsCompanion.insert(
            targetDate: DateTime.utc(2026, 7, 20),
            horizon: 'today',
            score: 22,
            band: 'low',
            computedAt: DateTime.utc(2026, 7, 20, 23),
            configVersion: 1,
            contributorsJson: '[]',
          ),
        );

    final updated = await db.backfillAssessmentLocations();
    expect(updated, 1);
    final row = await (db.select(db.riskAssessments)
          ..where((t) => t.id.equals(id)))
        .getSingle();
    expect(row.resolvedLat, closeTo(40.6609, 0.0001));
  });

  test('backfill ignores fetches outside the nearest window', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    // Only snapshot is 10 days from the assessment's compute — too far.
    await db.into(db.weatherSnapshots).insert(WeatherSnapshotsCompanion.insert(
          fetchedAt: DateTime.utc(2026, 7, 10, 12),
          lat: 40.6609,
          lon: -73.9613,
          forecastJson: '{}',
        ));

    final id = await db.into(db.riskAssessments).insert(
          RiskAssessmentsCompanion.insert(
            targetDate: DateTime.utc(2026, 7, 20),
            horizon: 'today',
            score: 22,
            band: 'low',
            computedAt: DateTime.utc(2026, 7, 20, 23),
            configVersion: 1,
            contributorsJson: '[]',
          ),
        );

    final updated = await db.backfillAssessmentLocations();
    expect(updated, 0);
    final row = await (db.select(db.riskAssessments)
          ..where((t) => t.id.equals(id)))
        .getSingle();
    expect(row.resolvedLat, isNull);
  });
}
