import 'dart:io';
import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  test('engine produces a sensible high-risk assessment from bundled config + realistic context', () {
    // Load the bundled config from the repo (test relative path).
    final cfgText = File('../../assets/rules_config_v1.json').readAsStringSync();
    final cfg = RulesConfigLoader.parse(cfgText);

    final engine = RiskEngine(modules: [
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
    ]);

    final now = DateTime.utc(2026, 6, 10, 6);
    final target = DateTime.utc(2026, 6, 10);
    final lastNight = DateTime.utc(2026, 6, 9);

    final ctx = EvaluationContext(
      now: now,
      targetDate: target,
      weather: WeatherSeries(samples: [
        // Past 24h: pressure drop + warm humid drift; target = today so the
        // engine reads [now - 24h, now].
        WeatherSample(at: now.subtract(const Duration(hours: 24)), pressureMsl: 1020, temperatureC: 18, humidityPct: 50),
        WeatherSample(at: now, pressureMsl: 1008, temperatureC: 19, humidityPct: 55),
      ]),
      health: HealthMetrics(
        source: DataSource.manual,
        recentSleep: [
          SleepRecord(
            night: lastNight,
            totalSleep: const Duration(hours: 4, minutes: 30),
            efficiency: 0.78,
            sleepStart: lastNight.add(const Duration(hours: 25)),
          ),
        ],
        recentHrv: [HrvSample(at: now, rmssdMs: 30)],
      ),
      recentJournal: [
        JournalEntry(at: now.subtract(const Duration(hours: 8)), kind: JournalKind.alcohol, payload: {'units': 3.0}),
        JournalEntry(at: now.subtract(const Duration(hours: 4)), kind: JournalKind.stress, payload: {'rating': 5}),
      ],
      baselines: const BaselineSnapshot(
        sleepMedian7d: Duration(hours: 7),
        hrvRmssdBaseline14d: 50,
      ),
      userFlags: const UserTriggerFlags(
        flaggedModuleIds: {'pressure_drop', 'sleep_deficit', 'alcohol', 'stress', 'hrv_letdown'},
      ),
    );

    final ass = engine.evaluate(ctx, cfg, horizon: RiskHorizon.today);
    // Band is the load-bearing assertion (high = 50..75). Score gate is a sanity
    // check that the engine is summing several adverse signals, not just one.
    expect(ass.score, greaterThan(50));
    expect(ass.band, anyOf(RiskBand.high, RiskBand.veryHigh));
    expect(ass.contributors.first.contribution, greaterThan(0));
    expect(ass.configVersion, 3);
  });

  test('empty context with no permissions yields onboarding assessment', () {
    final cfgText = File('../../assets/rules_config_v1.json').readAsStringSync();
    final cfg = RulesConfigLoader.parse(cfgText);

    final engine = RiskEngine(modules: [
      PressureDropModule(),
      SleepDeficitModule(),
      HrvLetdownModule(),
      AlcoholModule(),
      CaffeineModule(),
      StressModule(),
      HydrationModule(),
    ]);

    final now = DateTime.utc(2026, 6, 10);
    final ass = engine.evaluate(
      EvaluationContext(now: now, targetDate: now, baselines: BaselineSnapshot.empty),
      cfg,
      horizon: RiskHorizon.today,
    );
    expect(ass.isOnboarding, isTrue);
    expect(ass.score, 0);
  });
}
