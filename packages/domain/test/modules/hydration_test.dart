import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('HydrationModule', () {
    final module = HydrationModule();
    const params = ModuleParams(
      enabled: true,
      weightMax: 8,
      params: {'min_liters': 1.5},
    );
    final now = DateTime.utc(2026, 6, 10, 18);
    final target = DateTime.utc(2026, 6, 10);

    EvaluationContext build({
      required List<JournalEntry> entries,
      WeatherSeries? weather,
    }) =>
        EvaluationContext(
          now: now,
          targetDate: target,
          recentJournal: entries,
          weather: weather,
          baselines: BaselineSnapshot.empty,
        );

    test('no entries -> zero confidence', () {
      final s = module.evaluate(build(entries: const []), params);
      expect(s.confidence, 0);
    });

    test('entries meeting threshold -> no weight', () {
      final s = module.evaluate(
        build(entries: [
          JournalEntry(
            at: now.subtract(Duration(hours: 2)),
            kind: JournalKind.hydration,
            payload: {'liters': 2.0},
          ),
        ]),
        params,
      );
      expect(s.weight, 0);
    });

    test('low intake -> proportional weight', () {
      final s = module.evaluate(
        build(entries: [
          JournalEntry(
            at: now.subtract(Duration(hours: 2)),
            kind: JournalKind.hydration,
            payload: {'liters': 0.5},
          ),
        ]),
        params,
      );
      expect(s.weight, greaterThan(0));
    });

    test('hot weather amplifies signal', () {
      final hotSamples = [
        WeatherSample(at: now.subtract(Duration(hours: 6)), pressureMsl: 1015, temperatureC: 32, humidityPct: 30),
        WeatherSample(at: now, pressureMsl: 1015, temperatureC: 33, humidityPct: 30),
      ];
      final mildSamples = [
        WeatherSample(at: now.subtract(Duration(hours: 6)), pressureMsl: 1015, temperatureC: 18, humidityPct: 50),
        WeatherSample(at: now, pressureMsl: 1015, temperatureC: 19, humidityPct: 50),
      ];
      final hot = module.evaluate(
        build(
          entries: [
            JournalEntry(at: now.subtract(Duration(hours: 2)), kind: JournalKind.hydration, payload: {'liters': 1.0}),
          ],
          weather: WeatherSeries(samples: hotSamples),
        ),
        params,
      );
      final mild = module.evaluate(
        build(
          entries: [
            JournalEntry(at: now.subtract(Duration(hours: 2)), kind: JournalKind.hydration, payload: {'liters': 1.0}),
          ],
          weather: WeatherSeries(samples: mildSamples),
        ),
        params,
      );
      expect(hot.weight, greaterThan(mild.weight));
    });
  });
}
