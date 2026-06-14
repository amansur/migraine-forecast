import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('IntradayPressureSwingModule', () {
    final module = IntradayPressureSwingModule();
    const params = ModuleParams(
      enabled: true,
      weightMax: 12,
      params: {'threshold_volatility_hpa': 10.0, 'lookback_hours': 24},
    );
    final now = DateTime.utc(2026, 6, 10, 6);
    final todayTarget = DateTime.utc(2026, 6, 10);

    EvaluationContext withWeather(List<WeatherSample> samples) => EvaluationContext(
          now: now,
          targetDate: todayTarget,
          weather: WeatherSeries(samples: samples),
          baselines: BaselineSnapshot.empty,
        );

    test('null weather returns data-not-met signal', () {
      final ctx = EvaluationContext(
        now: now,
        targetDate: todayTarget,
        baselines: BaselineSnapshot.empty,
      );
      final s = module.evaluate(ctx, params);
      expect(s.confidence, 0);
      expect(s.missing, DataRequirement.weatherPressure);
    });

    test('below threshold yields weight 0', () {
      // volatility = 5 hPa, threshold = 10 => score 0
      final samples = [
        WeatherSample(at: now.subtract(const Duration(hours: 8)), pressureMsl: 1010, temperatureC: 20, humidityPct: 50),
        WeatherSample(at: now.subtract(const Duration(hours: 4)), pressureMsl: 1013, temperatureC: 20, humidityPct: 50),
        WeatherSample(at: now, pressureMsl: 1015, temperatureC: 20, humidityPct: 50),
      ];
      final s = module.evaluate(withWeather(samples), params);
      expect(s.weight, 0);
    });

    test('at 2x threshold yields weight_max', () {
      // volatility = 20 hPa = 2 * threshold => t = 1.0 => weight = 12
      final samples = [
        WeatherSample(at: now.subtract(const Duration(hours: 8)), pressureMsl: 1010, temperatureC: 20, humidityPct: 50),
        WeatherSample(at: now.subtract(const Duration(hours: 4)), pressureMsl: 1000, temperatureC: 20, humidityPct: 50),
        WeatherSample(at: now, pressureMsl: 1010, temperatureC: 20, humidityPct: 50),
      ];
      // volatility = |1000-1010| + |1010-1000| = 10 + 10 = 20
      final s = module.evaluate(withWeather(samples), params);
      expect(s.weight, closeTo(12.0, 0.01));
    });

    test('linear interpolation between threshold and 2x threshold', () {
      // volatility = 15 hPa, threshold = 10, saturation = 20
      // t = (15 - 10) / (20 - 10) = 0.5 => weight = 12 * 0.5 = 6
      final samples = [
        WeatherSample(at: now.subtract(const Duration(hours: 12)), pressureMsl: 1010, temperatureC: 20, humidityPct: 50),
        WeatherSample(at: now.subtract(const Duration(hours: 6)), pressureMsl: 1002.5, temperatureC: 20, humidityPct: 50),
        WeatherSample(at: now, pressureMsl: 1010, temperatureC: 20, humidityPct: 50),
      ];
      // volatility = 7.5 + 7.5 = 15
      final s = module.evaluate(withWeather(samples), params);
      expect(s.weight, closeTo(6.0, 0.01));
    });

    test('explanation mentions accumulated swing and hours', () {
      final samples = [
        WeatherSample(at: now.subtract(const Duration(hours: 12)), pressureMsl: 1010, temperatureC: 20, humidityPct: 50),
        WeatherSample(at: now, pressureMsl: 1022.4, temperatureC: 20, humidityPct: 50),
      ];
      final s = module.evaluate(withWeather(samples), params);
      expect(s.explanation, contains('hPa (accumulated)'));
      expect(s.explanation, contains('24h'));
    });

    test('insufficient samples (single sample) returns data-not-met signal', () {
      final samples = [
        WeatherSample(at: now, pressureMsl: 1013, temperatureC: 20, humidityPct: 50),
      ];
      final s = module.evaluate(withWeather(samples), params);
      expect(s.confidence, 0);
      expect(s.missing, DataRequirement.weatherPressure);
    });
  });
}
