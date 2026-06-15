import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/data/database.dart'
    hide JournalEntry, WeatherSnapshot, RiskAssessment, Attack;
import 'package:migraine_forecast/data/repos/location_overrides_repo.dart';
import 'package:migraine_forecast/data/sources/location_source.dart';

void main() {
  late AppDatabase db;
  late LocationOverridesRepo repo;

  setUp(() {
    db = AppDatabase.memory();
    repo = LocationOverridesRepo(db);
  });

  tearDown(() => db.close());

  final day1 = DateTime.utc(2026, 6, 1);
  final day2 = DateTime.utc(2026, 6, 2);
  const loc1 = UserLocation(lat: 40.7128, lon: -74.0060);
  const loc2 = UserLocation(lat: 34.0522, lon: -118.2437);

  test('forDay returns null when no override is set', () async {
    expect(await repo.forDay(day1), isNull);
  });

  test('set and forDay round-trip', () async {
    await repo.set(day1, loc1, 'New York, US');
    final result = await repo.forDay(day1);
    expect(result, isNotNull);
    expect(result!.lat, closeTo(40.7128, 0.0001));
    expect(result.lon, closeTo(-74.0060, 0.0001));
  });

  test('set overwrites an existing override for the same day', () async {
    await repo.set(day1, loc1, 'New York, US');
    await repo.set(day1, loc2, 'Los Angeles, US');
    final result = await repo.forDay(day1);
    expect(result!.lat, closeTo(34.0522, 0.0001));
    expect(result.lon, closeTo(-118.2437, 0.0001));
  });

  test('forDay normalises to UTC midnight', () async {
    // Pass a non-midnight DateTime for the same day — should still hit the row.
    await repo.set(day1, loc1, 'New York, US');
    final noon = DateTime.utc(2026, 6, 1, 12, 30);
    final result = await repo.forDay(noon);
    expect(result, isNotNull);
  });

  test('clear removes the override', () async {
    await repo.set(day1, loc1, 'New York, US');
    await repo.clear(day1);
    expect(await repo.forDay(day1), isNull);
  });

  test('clear is a no-op when no override exists', () async {
    await expectLater(repo.clear(day1), completes);
  });

  test('watchAll emits current overrides and updates on change', () async {
    await repo.set(day1, loc1, 'New York, US');
    await repo.set(day2, loc2, 'Los Angeles, US');

    final map = await repo.watchAll().first;
    expect(map.keys, containsAll([day1, day2]));
    expect(map[day1]!.lat, closeTo(40.7128, 0.0001));
    expect(map[day2]!.lat, closeTo(34.0522, 0.0001));
  });

  test('watchAll emits empty map when no overrides set', () async {
    final map = await repo.watchAll().first;
    expect(map, isEmpty);
  });
}
