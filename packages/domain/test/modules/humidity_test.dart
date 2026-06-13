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

    test('today (past): full weight above threshold, past-tense string', () {
      final samples = [
        WeatherSample(at: now.subtract(const Duration(hours: 23)), pressureMsl: 1015, temperatureC: 20, humidityPct: 70),
        WeatherSample(at: now, pressureMsl: 1015, temperatureC: 20, humidityPct: 75),
      ];
      final s = module.evaluate(withSamples(samples), params);
      expect(s.weight, 6);
      expect(s.explanation, contains('rose'));
      expect(s.explanation, contains('in last 24h'));
    });

    test('today (past): zero weight at or below threshold', () {
      final samples = [
        WeatherSample(at: now.subtract(const Duration(hours: 23)), pressureMsl: 1015, temperatureC: 20, humidityPct: 55),
        WeatherSample(at: now, pressureMsl: 1015, temperatureC: 20, humidityPct: 60),
      ];
      final s = module.evaluate(withSamples(samples), params);
      expect(s.weight, 0);
    });

    test('tomorrow (future): reads forecast, uses future tense with signed delta', () {
      // Tomorrow window is [tomorrow midnight, day-after midnight].
      final samples = [
        // Today samples — outside the tomorrow window.
        WeatherSample(at: now, pressureMsl: 1015, temperatureC: 20, humidityPct: 50),
        // Tomorrow forecast samples.
        WeatherSample(at: tomorrowTarget.add(const Duration(hours: 6)), pressureMsl: 1015, temperatureC: 20, humidityPct: 65),
        WeatherSample(at: tomorrowTarget.add(const Duration(hours: 18)), pressureMsl: 1015, temperatureC: 20, humidityPct: 85),
      ];
      final s = module.evaluate(withSamples(samples, targetDate: tomorrowTarget), params);
      expect(s.weight, 6);
      expect(s.explanation, contains('reaching 85%'));
      expect(s.explanation, contains('rising +20%'));
      expect(s.explanation, contains('over next 24h'));
    });

    test('tomorrow (future): falling trend keeps its sign', () {
      final samples = [
        WeatherSample(at: tomorrowTarget.add(const Duration(hours: 2)), pressureMsl: 1015, temperatureC: 20, humidityPct: 85),
        WeatherSample(at: tomorrowTarget.add(const Duration(hours: 20)), pressureMsl: 1015, temperatureC: 20, humidityPct: 65),
      ];
      final s = module.evaluate(withSamples(samples, targetDate: tomorrowTarget), params);
      expect(s.explanation, contains('falling -20%'));
    });

    test('today (past): falling trend renders "fell -N%"', () {
      final samples = [
        WeatherSample(at: now.subtract(const Duration(hours: 23)), pressureMsl: 1015, temperatureC: 20, humidityPct: 75),
        WeatherSample(at: now, pressureMsl: 1015, temperatureC: 20, humidityPct: 65),
      ];
      final s = module.evaluate(withSamples(samples), params);
      expect(s.explanation, contains('fell -10%'));
    });

    test('today (past): flat trend renders "stayed flat"', () {
      final samples = [
        WeatherSample(at: now.subtract(const Duration(hours: 23)), pressureMsl: 1015, temperatureC: 20, humidityPct: 65),
        WeatherSample(at: now, pressureMsl: 1015, temperatureC: 20, humidityPct: 65),
      ];
      final s = module.evaluate(withSamples(samples), params);
      expect(s.explanation, contains('stayed flat at 65%'));
      expect(s.explanation, contains('in last 24h'));
    });

    test('tomorrow (future): flat trend renders "staying flat"', () {
      final samples = [
        WeatherSample(at: tomorrowTarget.add(const Duration(hours: 2)), pressureMsl: 1015, temperatureC: 20, humidityPct: 70),
        WeatherSample(at: tomorrowTarget.add(const Duration(hours: 20)), pressureMsl: 1015, temperatureC: 20, humidityPct: 70),
      ];
      final s = module.evaluate(withSamples(samples, targetDate: tomorrowTarget), params);
      expect(s.explanation, contains('staying flat at 70%'));
      expect(s.explanation, contains('over next 24h'));
    });
  });
}
