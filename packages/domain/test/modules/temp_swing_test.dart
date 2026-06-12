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
    final todayTarget = DateTime.utc(2026, 6, 10);
    final tomorrowTarget = DateTime.utc(2026, 6, 11);

    EvaluationContext withSamples(
      List<WeatherSample> samples, {
      DateTime? targetDate,
    }) =>
        EvaluationContext(
          now: now,
          targetDate: targetDate ?? todayTarget,
          weather: WeatherSeries(samples: samples),
          baselines: BaselineSnapshot.empty,
        );

    test('no weather -> zero confidence', () {
      final s = module.evaluate(
        EvaluationContext(now: now, targetDate: todayTarget, baselines: BaselineSnapshot.empty),
        params,
      );
      expect(s.confidence, 0);
    });

    test('today (past): full weight when swing meets threshold, past tense', () {
      final samples = [
        WeatherSample(at: now.subtract(const Duration(hours: 23)), pressureMsl: 1015, temperatureC: 15, humidityPct: 50),
        WeatherSample(at: now, pressureMsl: 1015, temperatureC: 22, humidityPct: 50),
      ];
      final s = module.evaluate(withSamples(samples), params);
      expect(s.weight, 6);
      expect(s.explanation, contains('Temperature swung'));
      expect(s.explanation, contains('in last 24h'));
      expect(s.explanation, contains('warming'));
    });

    test('today (past): zero weight when swing below threshold', () {
      final samples = [
        WeatherSample(at: now.subtract(const Duration(hours: 23)), pressureMsl: 1015, temperatureC: 20, humidityPct: 50),
        WeatherSample(at: now, pressureMsl: 1015, temperatureC: 22, humidityPct: 50),
      ];
      final s = module.evaluate(withSamples(samples), params);
      expect(s.weight, 0);
    });

    test('tomorrow (future): reads forecast samples and uses future tense', () {
      final samples = [
        WeatherSample(at: now, pressureMsl: 1015, temperatureC: 25, humidityPct: 50),
        WeatherSample(at: now.add(const Duration(hours: 18)), pressureMsl: 1015, temperatureC: 18, humidityPct: 50),
        WeatherSample(at: now.add(const Duration(hours: 30)), pressureMsl: 1015, temperatureC: 17, humidityPct: 50),
      ];
      final s = module.evaluate(withSamples(samples, targetDate: tomorrowTarget), params);
      expect(s.explanation, contains('Temperature swing'));
      expect(s.explanation, contains('expected over next 24h'));
      expect(s.explanation, contains('cooling'));
    });

    test('reports temperature as missing data, not humidity', () {
      final s = module.evaluate(
        EvaluationContext(now: now, targetDate: todayTarget, baselines: BaselineSnapshot.empty),
        params,
      );
      expect(s.missing, DataRequirement.weatherTemperature);
    });
  });
}
