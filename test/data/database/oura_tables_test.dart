import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:migraine_forecast/data/database.dart';

void main() {
  group('Oura Database Tables', () {
    test('OuraSleep table has correct schema', () async {
      final db = AppDatabase.memory();

      // Query to check table exists
      final query = await db.customSelect(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='oura_sleep'",
      ).get();

      expect(query.isNotEmpty, true);
      await db.close();
    });

    test('OuraActivity table has correct schema', () async {
      final db = AppDatabase.memory();

      final query = await db.customSelect(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='oura_activity'",
      ).get();

      expect(query.isNotEmpty, true);
      await db.close();
    });

    test('OuraReadiness table has correct schema', () async {
      final db = AppDatabase.memory();

      final query = await db.customSelect(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='oura_readiness'",
      ).get();

      expect(query.isNotEmpty, true);
      await db.close();
    });

    test('OuraSleep table has all required columns', () async {
      final db = AppDatabase.memory();

      final query = await db.customSelect(
        "PRAGMA table_info(oura_sleep)",
      ).get();

      final columnNames = query.map((row) => row.read<String>('name')).toList();

      expect(columnNames, containsAll([
        'id',
        'day',
        'sleep_score',
        'lowest_heart_rate',
        'restless_periods',
        'average_heart_rate',
        'average_hrv',
        'fetched_at',
      ]));
      await db.close();
    });

    test('OuraActivity table has all required columns', () async {
      final db = AppDatabase.memory();

      final query = await db.customSelect(
        "PRAGMA table_info(oura_activity)",
      ).get();

      final columnNames = query.map((row) => row.read<String>('name')).toList();

      expect(columnNames, containsAll([
        'id',
        'day',
        'activity_score',
        'fetched_at',
      ]));
      await db.close();
    });

    test('OuraReadiness table has all required columns', () async {
      final db = AppDatabase.memory();

      final query = await db.customSelect(
        "PRAGMA table_info(oura_readiness)",
      ).get();

      final columnNames = query.map((row) => row.read<String>('name')).toList();

      expect(columnNames, containsAll([
        'id',
        'day',
        'readiness_score',
        'temperature_deviation',
        'fetched_at',
      ]));
      await db.close();
    });

    test('Can insert and query OuraSleep data', () async {
      final db = AppDatabase.memory();

      final now = DateTime.now();
      await db.into(db.ouraSleep).insert(
            OuraSleepCompanion(
              id: const Value('sleep-123'),
              day: Value(now),
              sleepScore: const Value(82),
              lowestHeartRate: const Value(48),
              restlessPeriods: const Value(2),
              fetchedAt: Value(now),
            ),
          );

      final records = await db.select(db.ouraSleep).get();

      expect(records.length, 1);
      expect(records.first.sleepScore, 82);
      expect(records.first.lowestHeartRate, 48);
      await db.close();
    });

    test('Can insert and query OuraActivity data', () async {
      final db = AppDatabase.memory();

      final now = DateTime.now();
      await db.into(db.ouraActivity).insert(
            OuraActivityCompanion(
              id: const Value('activity-123'),
              day: Value(now),
              activityScore: const Value(85),
              fetchedAt: Value(now),
            ),
          );

      final records = await db.select(db.ouraActivity).get();

      expect(records.length, 1);
      expect(records.first.activityScore, 85);
      await db.close();
    });

    test('Can insert and query OuraReadiness data', () async {
      final db = AppDatabase.memory();

      final now = DateTime.now();
      await db.into(db.ouraReadiness).insert(
            OuraReadinessCompanion(
              id: const Value('readiness-123'),
              day: Value(now),
              readinessScore: const Value(78),
              temperatureDeviation: const Value(-0.2),
              fetchedAt: Value(now),
            ),
          );

      final records = await db.select(db.ouraReadiness).get();

      expect(records.length, 1);
      expect(records.first.readinessScore, 78);
      expect(records.first.temperatureDeviation, -0.2);
      await db.close();
    });
  });
}
