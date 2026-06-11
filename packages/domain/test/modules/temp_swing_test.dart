import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('TempSwingModule', () {
    final module = TempSwingModule();
    const params = ModuleParams(
      enabled: true,
      weightMax: 6,
      params: {'temp_delta_c': 5},
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

    test('full weight when swing meets threshold', () {
      final samples = [
        WeatherSample(at: now.subtract(const Duration(hours: 23)), pressureMsl: 1015, temperatureC: 15, humidityPct: 50),
        WeatherSample(at: now, pressureMsl: 1015, temperatureC: 22, humidityPct: 50),
      ];
      final s = module.evaluate(withSamples(samples), params);
      expect(s.weight, 6);
    });

    test('zero weight when swing below threshold', () {
      final samples = [
        WeatherSample(at: now.subtract(const Duration(hours: 23)), pressureMsl: 1015, temperatureC: 20, humidityPct: 50),
        WeatherSample(at: now, pressureMsl: 1015, temperatureC: 22, humidityPct: 50),
      ];
      final s = module.evaluate(withSamples(samples), params);
      expect(s.weight, 0);
    });

    test('reports temperature as missing data, not humidity', () {
      final s = module.evaluate(
        EvaluationContext(now: now, targetDate: targetDate, baselines: BaselineSnapshot.empty),
        params,
      );
      expect(s.missing, DataRequirement.weatherTemperature);
    });
  });
}
