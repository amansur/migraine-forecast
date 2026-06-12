import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('PressureDropModule', () {
    final module = PressureDropModule();
    const params = ModuleParams(
      enabled: true,
      weightMax: 18,
      params: {'threshold_hpa': 5, 'lookahead_hours': 24},
    );
    final now = DateTime.utc(2026, 6, 10, 6);
    final todayTarget = DateTime.utc(2026, 6, 10);
    final tomorrowTarget = DateTime.utc(2026, 6, 11);

    EvaluationContext withWeather(
      List<WeatherSample> samples, {
      DateTime? targetDate,
    }) =>
        EvaluationContext(
          now: now,
          targetDate: targetDate ?? todayTarget,
          weather: WeatherSeries(samples: samples),
          baselines: BaselineSnapshot.empty,
        );

    test('zero confidence when no weather', () {
      final ctx = EvaluationContext(
        now: now,
        targetDate: todayTarget,
        baselines: BaselineSnapshot.empty,
      );
      final s = module.evaluate(ctx, params);
      expect(s.confidence, 0);
      expect(s.missing, DataRequirement.weatherPressure);
    });

    test('today: reads past 24h window relative to now', () {
      final samples = [
        WeatherSample(at: now.subtract(const Duration(hours: 24)), pressureMsl: 1015, temperatureC: 20, humidityPct: 50),
        WeatherSample(at: now.subtract(const Duration(hours: 12)), pressureMsl: 1010, temperatureC: 20, humidityPct: 50),
        WeatherSample(at: now, pressureMsl: 1008, temperatureC: 20, humidityPct: 50),
        // forecast samples should be ignored for today
        WeatherSample(at: now.add(const Duration(hours: 12)), pressureMsl: 990, temperatureC: 20, humidityPct: 50),
      ];
      final s = module.evaluate(withWeather(samples), params);
      // past 24h drop: 1015 -> 1008 = 7 hPa (not 1015 -> 990)
      expect(s.explanation, 'Pressure dropped 7.0 hPa in last 24h');
    });

    test('tomorrow: reads forecast samples and uses future tense', () {
      final samples = [
        WeatherSample(at: now.subtract(const Duration(hours: 12)), pressureMsl: 1015, temperatureC: 20, humidityPct: 50),
        WeatherSample(at: now, pressureMsl: 1014, temperatureC: 20, humidityPct: 50),
        WeatherSample(at: now.add(const Duration(hours: 18)), pressureMsl: 1005, temperatureC: 20, humidityPct: 50),
        WeatherSample(at: now.add(const Duration(hours: 30)), pressureMsl: 1000, temperatureC: 20, humidityPct: 50),
      ];
      final s = module.evaluate(withWeather(samples, targetDate: tomorrowTarget), params);
      expect(s.explanation, contains('over next 24h'));
      expect(s.explanation, startsWith('Pressure dropping'));
      expect(s.weight, greaterThan(0));
    });

    test('lookahead_hours param drives both window and label', () {
      const params48 = ModuleParams(
        enabled: true,
        weightMax: 18,
        params: {'threshold_hpa': 5, 'lookahead_hours': 48},
      );
      final samples = [
        // 36h ago, then 24h ago — a 10 hPa drop within 12h, but only visible
        // when the outer window extends 36h back.
        WeatherSample(at: now.subtract(const Duration(hours: 36)), pressureMsl: 1020, temperatureC: 20, humidityPct: 50),
        WeatherSample(at: now.subtract(const Duration(hours: 24)), pressureMsl: 1010, temperatureC: 20, humidityPct: 50),
        WeatherSample(at: now, pressureMsl: 1010, temperatureC: 20, humidityPct: 50),
      ];
      final s = module.evaluate(withWeather(samples), params48);
      expect(s.explanation, contains('in last 48h'));
      expect(s.weight, greaterThan(0));
    });

    test('saturates at weight_max for large drops', () {
      final samples = [
        WeatherSample(at: now.subtract(const Duration(hours: 24)), pressureMsl: 1020, temperatureC: 20, humidityPct: 50),
        WeatherSample(at: now.subtract(const Duration(hours: 6)), pressureMsl: 1005, temperatureC: 20, humidityPct: 50),
        WeatherSample(at: now, pressureMsl: 1005, temperatureC: 20, humidityPct: 50),
      ];
      final s = module.evaluate(withWeather(samples), params);
      expect(s.weight, 18);
      expect(s.explanation, contains('hPa'));
    });
  });
}
