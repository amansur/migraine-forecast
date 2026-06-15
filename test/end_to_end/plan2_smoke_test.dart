import 'package:domain/domain.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/data/context_builder.dart';
import 'package:migraine_forecast/data/database.dart' hide Attack, JournalEntry, WeatherSnapshot, RiskAssessment;
import 'package:migraine_forecast/data/repos/assessment_repository.dart';
import 'package:migraine_forecast/data/repos/baseline_snapshot_builder.dart';
import 'package:migraine_forecast/data/sources/drift_journal_source.dart';
import 'package:migraine_forecast/data/sources/fake_health_source.dart';
import 'package:migraine_forecast/data/sources/manual_location_source.dart';
import 'package:migraine_forecast/data/sources/open_meteo/open_meteo_parser.dart';
import 'package:migraine_forecast/data/sources/weather_source.dart';

class _StubWeather implements WeatherSource {
  final WeatherSnapshot snap;
  _StubWeather(this.snap);
  @override
  Future<WeatherSnapshot> fetch({required double lat, required double lon, required DateTime now, bool forceRefresh = false, int? pastDays}) async => snap;
}

class _MemFlagsRepo implements UserTriggerFlagsRepo {
  UserTriggerFlags _f = const UserTriggerFlags();
  @override
  Future<UserTriggerFlags> load() async => _f;
  @override
  Future<void> save(UserTriggerFlags flags) async => _f = flags;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('full pipeline: adapters → context → engine → save assessment', () async {
    final db = AppDatabase.memory();
    addTearDown(db.close);
    final journal = DriftJournalSource(db);

    // Stress entry today (high rating → direct contribution)
    await journal.addEntry(JournalEntry(
      at: DateTime.utc(2026, 6, 10, 2),
      kind: JournalKind.stress,
      payload: const {'rating': 5},
    ));
    // Alcohol entry within 24h window
    await journal.addEntry(JournalEntry(
      at: DateTime.utc(2026, 6, 9, 22),
      kind: JournalKind.alcohol,
      payload: const {'units': 3.0},
    ));
    // Low hydration entry today to trigger hydration module
    await journal.addEntry(JournalEntry(
      at: DateTime.utc(2026, 6, 10, 5),
      kind: JournalKind.hydration,
      payload: const {'liters': 0.3},
    ));
    // Caffeine baseline: 7 days of typical intake (200 mg/day each), no caffeine today
    for (int d = 7; d >= 1; d--) {
      await journal.addEntry(JournalEntry(
        at: DateTime.utc(2026, 6, 10 - d, 8),
        kind: JournalKind.caffeine,
        payload: const {'mg': 200.0},
      ));
    }

    final fxText = await rootBundle.loadString('test/data/sources/fixtures/open_meteo/forecast_pressure_drop.json');
    final forecast = OpenMeteoParser.parseForecast(fxText);
    // The fixture's first sample is at 2026-06-10 06:00 (==now). The today-scoring
    // path now reads [now-24h, now], so prepend the same drop pattern shifted
    // back 24h to represent recent history.
    final pastSamples = [
      WeatherSample(at: DateTime.utc(2026, 6, 9, 6), pressureMsl: 1020, temperatureC: 18, humidityPct: 50),
      WeatherSample(at: DateTime.utc(2026, 6, 9, 12), pressureMsl: 1017, temperatureC: 21, humidityPct: 58),
      WeatherSample(at: DateTime.utc(2026, 6, 9, 18), pressureMsl: 1013, temperatureC: 24.5, humidityPct: 65),
      WeatherSample(at: DateTime.utc(2026, 6, 10, 0), pressureMsl: 1009, temperatureC: 23, humidityPct: 72),
    ];
    final weather = WeatherSeries(samples: [...pastSamples, ...forecast.samples]);
    final stubWeather = _StubWeather(
      WeatherSnapshot(weather: weather, airQuality: const AirQualitySeries(samples: []), fetchedAt: DateTime.utc(2026, 6, 10, 6)),
    );

    // 10 HRV samples at ~55 ms baseline; current reading is 30 ms (45% drop → max letdown)
    final now = DateTime.utc(2026, 6, 10, 6);
    final baselineHrvSamples = List.generate(
      10,
      (i) => HrvSample(at: now.subtract(Duration(hours: (i + 1) * 24)), rmssdMs: 55.0),
    );
    final health = FakeHealthSource()
      ..sleep = [
        // Three nights to establish a median baseline (minSamples = 3)
        SleepRecord(
          night: DateTime.utc(2026, 6, 9),
          totalSleep: const Duration(hours: 4, minutes: 30),
          efficiency: 0.78,
          sleepStart: DateTime.utc(2026, 6, 10, 1),
        ),
        SleepRecord(
          night: DateTime.utc(2026, 6, 8),
          totalSleep: const Duration(hours: 4, minutes: 45),
          efficiency: 0.80,
          sleepStart: DateTime.utc(2026, 6, 9, 1),
        ),
        SleepRecord(
          night: DateTime.utc(2026, 6, 7),
          totalSleep: const Duration(hours: 5),
          efficiency: 0.82,
          sleepStart: DateTime.utc(2026, 6, 8, 1),
        ),
      ]
      ..hrv = [
        // Current reading (low) followed by 10-day baseline readings
        HrvSample(at: DateTime.utc(2026, 6, 10, 6), rmssdMs: 30),
        ...baselineHrvSamples,
      ];

    final location = ManualLocationSource();
    await location.set(lat: 40.7, lon: -74.0);

    final flagsRepo = _MemFlagsRepo();
    await flagsRepo.save(const UserTriggerFlags(
      flaggedModuleIds: {
        'pressure_drop',
        'humidity',
        'temp_swing',
        'sleep_deficit',
        'alcohol',
        'stress',
        'hrv_letdown',
        'hydration',
        'caffeine',
      },
    ));

    final builder = ContextBuilder(
      weather: stubWeather,
      health: health,
      journal: journal,
      location: location,
      flagsRepo: flagsRepo,
      baselineBuilder: const BaselineSnapshotBuilder(BaselineStore()),
      db: db,
    );

    final cfgText = await rootBundle.loadString('assets/rules_config_v1.json');
    final cfg = RulesConfigLoader.parse(cfgText);
    final engine = RiskEngine(
      clock: () => DateTime.utc(2026, 6, 10, 6),
      modules: [
      PressureDropModule(),
      HumidityModule(),
      TempSwingModule(),
      AirQualityModule(),
      SleepDeficitModule(),
      HrvLetdownModule(),
      MenstrualPhaseModule(),
      RefractoryModule(),
      AlcoholModule(),
      CaffeineModule(),
      StressModule(),
      HydrationModule(),
    ],
    );

    final ctx = await builder.build(
      now: DateTime.utc(2026, 6, 10, 6),
      target: DateTime.utc(2026, 6, 10),
    );
    final ass = engine.evaluate(ctx, cfg, horizon: RiskHorizon.today);
    expect(ass.band, anyOf(RiskBand.high, RiskBand.veryHigh));

    final repo = AssessmentRepository(db);
    final id = await repo.save(ass);
    expect(id, isPositive);
    final reloaded = await repo.activeAt(DateTime.utc(2026, 6, 10, 6, 1));
    expect(reloaded?.score, ass.score);
  });
}
