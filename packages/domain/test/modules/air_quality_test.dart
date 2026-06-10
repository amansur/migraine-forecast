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
    final target = DateTime.utc(2026, 6, 10);

    EvaluationContext withAQ(List<AirQualitySample> samples) => EvaluationContext(
          now: now,
          targetDate: target,
          airQuality: AirQualitySeries(samples: samples),
          baselines: BaselineSnapshot.empty,
        );

    test('no AQ data -> zero confidence', () {
      final s = module.evaluate(
        EvaluationContext(now: now, targetDate: target, baselines: BaselineSnapshot.empty),
        params,
      );
      expect(s.confidence, 0);
    });

    test('below threshold -> no weight', () {
      final s = module.evaluate(
        withAQ([AirQualitySample(at: now, pm25: 20)]),
        params,
      );
      expect(s.weight, 0);
    });

    test('above threshold -> proportional weight, saturating at 2x', () {
      final s = module.evaluate(
        withAQ([AirQualitySample(at: now, pm25: 70)]), // 2x threshold
        params,
      );
      expect(s.weight, 10);
    });
  });
}
