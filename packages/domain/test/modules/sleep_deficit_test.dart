import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('SleepDeficitModule', () {
    final module = SleepDeficitModule();
    const params = ModuleParams(
      enabled: true,
      weightMax: 20,
      params: {'hours_threshold': 6, 'efficiency_threshold': 0.85, 'baseline_days': 7},
    );
    final now = DateTime.utc(2026, 6, 10, 6);
    final target = DateTime.utc(2026, 6, 10);
    final lastNight = DateTime.utc(2026, 6, 9);

    EvaluationContext withSleep(List<SleepRecord> recent, {Duration? baseline}) => EvaluationContext(
          now: now,
          targetDate: target,
          health: HealthMetrics(recentSleep: recent),
          baselines: BaselineSnapshot(sleepMedian7d: baseline),
        );

    test('no health -> zero confidence', () {
      final s = module.evaluate(
        EvaluationContext(now: now, targetDate: target, baselines: BaselineSnapshot.empty),
        params,
      );
      expect(s.confidence, 0);
      expect(s.missing, DataRequirement.healthSleep);
    });

    test('low total sleep triggers weight', () {
      final s = module.evaluate(
        withSleep([
          SleepRecord(
            night: lastNight,
            totalSleep: const Duration(hours: 4, minutes: 30),
            efficiency: 0.9,
            sleepStart: lastNight.add(const Duration(hours: 22)),
          ),
        ], baseline: const Duration(hours: 7)),
        params,
      );
      expect(s.weight, greaterThan(2.0));
      expect(s.confidence, 1.0);
    });

    test('low efficiency contributes', () {
      final s = module.evaluate(
        withSleep([
          SleepRecord(
            night: lastNight,
            totalSleep: const Duration(hours: 7),
            efficiency: 0.7,
            sleepStart: lastNight.add(const Duration(hours: 22)),
          ),
        ], baseline: const Duration(hours: 7)),
        params,
      );
      expect(s.weight, greaterThan(0));
    });

    test('schedule shift >2h contributes', () {
      final s = module.evaluate(
        withSleep([
          SleepRecord(
            night: lastNight,
            totalSleep: const Duration(hours: 7),
            efficiency: 0.9,
            sleepStart: lastNight.add(const Duration(hours: 25)), // 1am vs typical 10pm = 3h shift
          ),
        ], baseline: const Duration(hours: 7)),
        const ModuleParams(
          enabled: true,
          weightMax: 20,
          params: {
            'hours_threshold': 6,
            'efficiency_threshold': 0.85,
            'baseline_days': 7,
            'typical_sleep_start_hour': 22,
          },
        ),
      );
      expect(s.weight, greaterThan(0));
    });

    test('cold-start confidence when no baseline', () {
      final s = module.evaluate(
        withSleep([
          SleepRecord(
            night: lastNight,
            totalSleep: const Duration(hours: 5),
            efficiency: 0.9,
            sleepStart: lastNight.add(const Duration(hours: 22)),
          ),
        ]),
        params,
      );
      expect(s.confidence, 0.5);
    });
  });
}
