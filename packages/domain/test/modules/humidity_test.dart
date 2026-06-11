import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('HumidityModule', () {
    final module = HumidityModule();
    const params = ModuleParams(
      enabled: true,
      weightMax: 6,
      params: {'humidity_pct': 60},
    );
    final now = DateTime.utc(2026, 6, 10, 6);
    final targetDate = DateTime.utc(2026, 6, 10);

    EvaluationContext withSamples(List<WeatherSample> samples) => EvaluationContext(
          now: now,
          targetDate: targetDate,
          weather: WeatherSeries(samples: samples),
          baselines: BaselineSnapshot.empty,
        );

    test('no weather -> zero confidence', () {
      final s = module.evaluate(
        EvaluationContext(now: now, targetDate: targetDate, baselines: BaselineSnapshot.empty),
        params,
      );
      expect(s.confidence, 0);
    });

    test('full weight above threshold', () {
      final samples = [
        WeatherSample(at: now.subtract(const Duration(hours: 23)), pressureMsl: 1015, temperatureC: 20, humidityPct: 70),
        WeatherSample(at: now, pressureMsl: 1015, temperatureC: 20, humidityPct: 75),
      ];
      final s = module.evaluate(withSamples(samples), params);
      expect(s.weight, 6);
    });

    test('zero weight at or below threshold', () {
      final samples = [
        WeatherSample(at: now.subtract(const Duration(hours: 23)), pressureMsl: 1015, temperatureC: 20, humidityPct: 55),
        WeatherSample(at: now, pressureMsl: 1015, temperatureC: 20, humidityPct: 60),
      ];
      final s = module.evaluate(withSamples(samples), params);
      expect(s.weight, 0);
    });
  });
}
