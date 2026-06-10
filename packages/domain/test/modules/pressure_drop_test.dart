import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('PressureDropModule', () {
    final module = PressureDropModule();
    const params = ModuleParams(
      enabled: true,
      weightMax: 18,
      params: {'threshold_hpa': 5, 'lookahead_hours': 48},
    );
    final now = DateTime.utc(2026, 6, 10, 6);
    final targetDate = DateTime.utc(2026, 6, 10);

    EvaluationContext withWeather(List<WeatherSample> samples) => EvaluationContext(
          now: now,
          targetDate: targetDate,
          weather: WeatherSeries(samples: samples),
          baselines: BaselineSnapshot.empty,
        );

    test('zero confidence when no weather', () {
      final ctx = EvaluationContext(
        now: now,
        targetDate: targetDate,
        baselines: BaselineSnapshot.empty,
      );
      final s = module.evaluate(ctx, params);
      expect(s.confidence, 0);
      expect(s.missing, DataRequirement.weatherPressure);
    });

    test('no signal when drop below threshold', () {
      final samples = [
        WeatherSample(at: now, pressureMsl: 1015, temperatureC: 20, humidityPct: 50),
        WeatherSample(at: now.add(Duration(hours: 24)), pressureMsl: 1013, temperatureC: 20, humidityPct: 50),
      ];
      final s = module.evaluate(withWeather(samples), params);
      expect(s.weight, lessThan(9.0)); // half-ramp under threshold
      expect(s.confidence, 1.0);
    });

    test('proportional weight at threshold', () {
      final samples = [
        WeatherSample(at: now, pressureMsl: 1015, temperatureC: 20, humidityPct: 50),
        WeatherSample(at: now.add(Duration(hours: 24)), pressureMsl: 1010, temperatureC: 20, humidityPct: 50),
      ];
      // 5 hPa drop = at threshold -> weight at half of max (9.0 with weightMax=18)
      final s = module.evaluate(withWeather(samples), params);
      expect(s.weight, closeTo(9.0, 0.5));
    });

    test('saturates at weight_max for large drops', () {
      final samples = [
        WeatherSample(at: now, pressureMsl: 1020, temperatureC: 20, humidityPct: 50),
        WeatherSample(at: now.add(Duration(hours: 18)), pressureMsl: 1005, temperatureC: 20, humidityPct: 50),
      ];
      final s = module.evaluate(withWeather(samples), params);
      expect(s.weight, 18);
      expect(s.explanation, contains('hPa'));
    });
  });
}
