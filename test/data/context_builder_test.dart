import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/data/context_builder.dart';
import 'package:migraine_forecast/data/database.dart' hide JournalEntry, WeatherSnapshot;
import 'package:migraine_forecast/data/repos/baseline_snapshot_builder.dart';
import 'package:migraine_forecast/data/sources/drift_journal_source.dart';
import 'package:migraine_forecast/data/sources/fake_health_source.dart';
import 'package:migraine_forecast/data/sources/manual_location_source.dart';
import 'package:migraine_forecast/data/sources/open_meteo/open_meteo_parser.dart';
import 'package:migraine_forecast/data/sources/weather_source.dart';

class _StubWeatherSource implements WeatherSource {
  final WeatherSnapshot snap;
  _StubWeatherSource(this.snap);
  @override
  Future<WeatherSnapshot> fetch({required double lat, required double lon, required DateTime now, bool forceRefresh = false, int? pastDays}) async => snap;
}

class _NoFlagsRepo implements UserTriggerFlagsRepo {
  @override
  Future<UserTriggerFlags> load() async => const UserTriggerFlags();
  @override
  Future<void> save(UserTriggerFlags flags) async {}
}

void main() {
  test('builds an EvaluationContext from all adapters', () async {
    final db = AppDatabase.memory();
    addTearDown(db.close);
    final journal = DriftJournalSource(db);
    await journal.addEntry(JournalEntry(
      at: DateTime.utc(2026, 6, 10, 2),
      kind: JournalKind.stress,
      payload: const {'rating': 5},
    ));

    final weather = OpenMeteoParser.parseForecast('{"hourly": {"time": ["2026-06-10T06:00"], "pressure_msl": [1012], "temperature_2m": [20], "relative_humidity_2m": [55]}}');
    const aq = AirQualitySeries(samples: []);
    final stubWeather = _StubWeatherSource(
      WeatherSnapshot(weather: weather, airQuality: aq, fetchedAt: DateTime.utc(2026, 6, 10, 6)),
    );

    final health = FakeHealthSource();
    final location = ManualLocationSource();
    await location.set(lat: 40.7, lon: -74.0);
    final flagsRepo = _NoFlagsRepo();

    final builder = ContextBuilder(
      weather: stubWeather,
      health: health,
      journal: journal,
      location: location,
      flagsRepo: flagsRepo,
      baselineBuilder: const BaselineSnapshotBuilder(BaselineStore()),
      db: db,
    );

    final ctx = await builder.build(
      now: DateTime.utc(2026, 6, 10, 6),
      target: DateTime.utc(2026, 6, 10),
    );

    expect(ctx.weather, isNotNull);
    expect(ctx.recentJournal, hasLength(1));
    expect(ctx.userFlags.flaggedModuleIds, isEmpty);
  });
}
