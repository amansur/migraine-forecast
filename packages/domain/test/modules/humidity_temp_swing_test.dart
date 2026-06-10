import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('HumidityTempSwingModule', () {
    final module = HumidityTempSwingModule();
    const params = ModuleParams(
      enabled: true,
      weightMax: 10,
      params: {'humidity_pct': 60, 'temp_delta_c': 5},
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

    test('full weight when both conditions met', () {
      final samples = [
        WeatherSample(at: now.subtract(Duration(hours: 23)), pressureMsl: 1015, temperatureC: 15, humidityPct: 70),
        WeatherSample(at: now, pressureMsl: 1015, temperatureC: 22, humidityPct: 70),
      ];
      final s = module.evaluate(withSamples(samples), params);
      expect(s.weight, 10);
    });

    test('no weight if humidity below threshold', () {
      final samples = [
        WeatherSample(at: now.subtract(Duration(hours: 23)), pressureMsl: 1015, temperatureC: 15, humidityPct: 40),
        WeatherSample(at: now, pressureMsl: 1015, temperatureC: 22, humidityPct: 40),
      ];
      final s = module.evaluate(withSamples(samples), params);
      expect(s.weight, 0);
    });

    test('no weight if temp swing below threshold', () {
      final samples = [
        WeatherSample(at: now.subtract(Duration(hours: 23)), pressureMsl: 1015, temperatureC: 20, humidityPct: 70),
        WeatherSample(at: now, pressureMsl: 1015, temperatureC: 22, humidityPct: 70),
      ];
      final s = module.evaluate(withSamples(samples), params);
      expect(s.weight, 0);
    });
  });
}
