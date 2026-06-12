import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('AirQualityModule', () {
    final module = AirQualityModule();
    const params = ModuleParams(
      enabled: true,
      weightMax: 10,
      params: {'pm25_threshold': 35.0},
    );
    final now = DateTime.utc(2026, 6, 10, 6);
    final todayTarget = DateTime.utc(2026, 6, 10);
    final tomorrowTarget = DateTime.utc(2026, 6, 11);

    EvaluationContext withAQ(
      List<AirQualitySample> samples, {
      DateTime? targetDate,
    }) =>
        EvaluationContext(
          now: now,
          targetDate: targetDate ?? todayTarget,
          airQuality: AirQualitySeries(samples: samples),
          baselines: BaselineSnapshot.empty,
        );

    test('no AQ data -> zero confidence', () {
      final s = module.evaluate(
        EvaluationContext(now: now, targetDate: todayTarget, baselines: BaselineSnapshot.empty),
        params,
      );
      expect(s.confidence, 0);
    });

    test('today (past): below threshold -> no weight, past tense', () {
      final s = module.evaluate(
        withAQ([AirQualitySample(at: now.subtract(const Duration(hours: 6)), pm25: 20)]),
        params,
      );
      expect(s.weight, 0);
      expect(s.explanation, contains('in last 24h'));
    });

    test('today (past): above threshold -> weight, past-tense peaked string', () {
      final s = module.evaluate(
        withAQ([AirQualitySample(at: now.subtract(const Duration(hours: 6)), pm25: 70)]),
        params,
      );
      expect(s.weight, 10);
      expect(s.explanation, contains('peaked'));
      expect(s.explanation, contains('in last 24h'));
    });

    test('tomorrow (future): reads forecast samples and uses future-tense string', () {
      final s = module.evaluate(
        withAQ(
          [AirQualitySample(at: now.add(const Duration(hours: 18)), pm25: 70)],
          targetDate: tomorrowTarget,
        ),
        params,
      );
      expect(s.weight, 10);
      expect(s.explanation, contains('forecast to reach'));
      expect(s.explanation, contains('over next 24h'));
    });
  });
}
