import 'package:domain/domain.dart';
import 'package:test/test.dart';

WeatherSample sample(int hour, {double? gust}) => WeatherSample(
    at: DateTime.utc(2026, 7, 9, hour),
    pressureMsl: 1013,
    temperatureC: 20,
    humidityPct: 50,
    windGustKph: gust);

void main() {
  final now = DateTime.utc(2026, 7, 9, 20);
  final target = DateTime.utc(2026, 7, 9);
  const params = ModuleParams(enabled: true, weightMax: 10, params: {
    'gust_threshold_kmh': 45.0,
    'gust_saturation_kmh': 75.0,
    'lookahead_hours': 24,
  });
  EvaluationContext ctx(List<WeatherSample> samples) => EvaluationContext(
      now: now,
      targetDate: target,
      weather: WeatherSeries(samples: samples),
      baselines: BaselineSnapshot.empty);
  final m = WindModule();

  test('gusts below threshold → weight 0, full confidence', () {
    final s = m.evaluate(ctx([sample(8, gust: 20), sample(12, gust: 30)]), params);
    expect(s.weight, 0);
    expect(s.confidence, 1.0);
  });

  test('gusts at saturation → full weight', () {
    final s = m.evaluate(ctx([sample(8, gust: 80)]), params);
    expect(s.weight, 10.0);
    expect(s.explanation, contains('80'));
  });

  test('midpoint gust ramps linearly', () {
    final s = m.evaluate(ctx([sample(8, gust: 60)]), params); // (60-45)/(75-45)=0.5
    expect(s.weight, closeTo(5.0, 1e-9));
  });

  test('samples without wind data (old cache) → zero-confidence missing signal', () {
    final s = m.evaluate(ctx([sample(8), sample(12)]), params);
    expect(s.weight * s.confidence, 0);
    expect(s.missing, DataRequirement.weatherWind);
  });

  test('no weather at all → zero-confidence missing signal', () {
    final s = m.evaluate(
        EvaluationContext(
            now: now, targetDate: target, baselines: BaselineSnapshot.empty),
        params);
    expect(s.weight * s.confidence, 0);
    expect(s.missing, DataRequirement.weatherWind);
  });
}
