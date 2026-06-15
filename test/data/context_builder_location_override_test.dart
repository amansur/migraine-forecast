/// Tests that ContextBuilder resolves the effective location from
/// LocationOverridesRepo before falling back to the live LocationSource.
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/data/context_builder.dart';
import 'package:migraine_forecast/data/database.dart'
    hide JournalEntry, WeatherSnapshot, RiskAssessment;
import 'package:migraine_forecast/data/repos/baseline_snapshot_builder.dart';
import 'package:migraine_forecast/data/repos/location_overrides_repo.dart';
import 'package:migraine_forecast/data/sources/drift_journal_source.dart';
import 'package:migraine_forecast/data/sources/fake_health_source.dart';
import 'package:migraine_forecast/data/sources/location_source.dart';
import 'package:migraine_forecast/data/sources/open_meteo/open_meteo_parser.dart';
import 'package:migraine_forecast/data/sources/weather_source.dart';

// ---------------------------------------------------------------------------
// Stubs
// ---------------------------------------------------------------------------

class _StubWeatherSource implements WeatherSource {
  @override
  Future<void> primeArchive({required double lat, required double lon, required DateTime startDate, required DateTime endDate}) async {}

  final List<_FetchCall> calls = [];
  @override
  Future<WeatherSnapshot> fetch({
    required double lat,
    required double lon,
    required DateTime now,
    bool forceRefresh = false,
    int? pastDays,
  }) async {
    calls.add(_FetchCall(lat: lat, lon: lon, now: now));
    final weather = OpenMeteoParser.parseForecast(
        '{"hourly": {"time": ["2026-06-01T06:00"], "pressure_msl": [1012], '
        '"temperature_2m": [20], "relative_humidity_2m": [55]}}');
    return WeatherSnapshot(
      weather: weather,
      airQuality: const AirQualitySeries(samples: []),
      fetchedAt: now,
    );
  }
}

class _FetchCall {
  final double lat;
  final double lon;
  final DateTime now;
  const _FetchCall({required this.lat, required this.lon, required this.now});
}

class _NoFlagsRepo implements UserTriggerFlagsRepo {
  @override
  Future<UserTriggerFlags> load() async => const UserTriggerFlags();
  @override
  Future<void> save(UserTriggerFlags flags) async {}
}

class _TrackingLocationSource implements LocationSource {
  final UserLocation _loc;
  int callCount = 0;
  _TrackingLocationSource(this._loc);
  @override
  Future<UserLocation?> current() async {
    callCount++;
    return _loc;
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late AppDatabase db;
  late LocationOverridesRepo overridesRepo;

  setUp(() {
    db = AppDatabase.memory();
    overridesRepo = LocationOverridesRepo(db);
  });

  tearDown(() => db.close());

  test('uses override location when one is set for target day', () async {
    const overrideLoc = UserLocation(lat: 51.5074, lon: -0.1278); // London
    const liveLoc = UserLocation(lat: 40.7128, lon: -74.0060);    // New York
    final target = DateTime.utc(2026, 6, 1);

    await overridesRepo.set(target, overrideLoc, 'London, UK');

    final weather = _StubWeatherSource();
    final location = _TrackingLocationSource(liveLoc);

    final builder = ContextBuilder(
      weather: weather,
      health: FakeHealthSource(),
      journal: DriftJournalSource(db),
      location: location,
      flagsRepo: _NoFlagsRepo(),
      baselineBuilder: const BaselineSnapshotBuilder(BaselineStore()),
      db: db,
      locationOverrides: overridesRepo,
    );

    await builder.build(now: target, target: target);

    // Weather should have been fetched with the override's coordinates,
    // not the live location's.
    expect(weather.calls, hasLength(1));
    expect(weather.calls.single.lat, closeTo(51.5074, 0.0001));
    expect(weather.calls.single.lon, closeTo(-0.1278, 0.0001));

    // LocationSource.current() should NOT have been called (override took priority).
    expect(location.callCount, 0);
  });

  test('falls back to live location when no override exists', () async {
    const liveLoc = UserLocation(lat: 40.7128, lon: -74.0060);
    final target = DateTime.utc(2026, 6, 1);

    final weather = _StubWeatherSource();
    final location = _TrackingLocationSource(liveLoc);

    final builder = ContextBuilder(
      weather: weather,
      health: FakeHealthSource(),
      journal: DriftJournalSource(db),
      location: location,
      flagsRepo: _NoFlagsRepo(),
      baselineBuilder: const BaselineSnapshotBuilder(BaselineStore()),
      db: db,
      locationOverrides: overridesRepo,
    );

    await builder.build(now: target, target: target);

    // Weather should use the live location's coordinates.
    expect(weather.calls, hasLength(1));
    expect(weather.calls.single.lat, closeTo(40.7128, 0.0001));
    expect(weather.calls.single.lon, closeTo(-74.0060, 0.0001));

    // LocationSource.current() should have been called exactly once.
    expect(location.callCount, 1);
  });

  test('weather fetch uses target day as now parameter', () async {
    const liveLoc = UserLocation(lat: 40.7128, lon: -74.0060);
    final target = DateTime.utc(2026, 1, 15);

    final weather = _StubWeatherSource();

    final builder = ContextBuilder(
      weather: weather,
      health: FakeHealthSource(),
      journal: DriftJournalSource(db),
      location: _TrackingLocationSource(liveLoc),
      flagsRepo: _NoFlagsRepo(),
      baselineBuilder: const BaselineSnapshotBuilder(BaselineStore()),
      db: db,
      locationOverrides: overridesRepo,
    );

    await builder.build(now: DateTime.utc(2026, 1, 20), target: target);

    // The fetch's `now` parameter should be the target day, not wall-clock now.
    expect(weather.calls, hasLength(1));
    expect(weather.calls.single.now, equals(target));
  });
}
