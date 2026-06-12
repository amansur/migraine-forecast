import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('CaffeineModule', () {
    final module = CaffeineModule();
    const params = ModuleParams(
      enabled: true,
      weightMax: 8,
      params: {'delta_mg_threshold': 100},
    );
    final now = DateTime.utc(2026, 6, 10, 6);
    final target = DateTime.utc(2026, 6, 10);

    EvaluationContext build({
      required List<JournalEntry> entries,
      double? baselineMg,
    }) =>
        EvaluationContext(
          now: now,
          targetDate: target,
          recentJournal: entries,
          baselines: BaselineSnapshot(caffeineDailyMg: baselineMg),
        );

    test('no caffeine baseline AND no log -> zero confidence', () {
      final s = module.evaluate(build(entries: const []), params);
      expect(s.confidence, 0);
    });

    test('today caffeine well below baseline (withdrawal) -> weight', () {
      final s = module.evaluate(
        build(
          entries: [
            JournalEntry(
              at: now.subtract(const Duration(hours: 3)),
              kind: JournalKind.caffeine,
              payload: {'mg': 50},
            ),
          ],
          baselineMg: 200,
        ),
        params,
      );
      expect(s.weight, greaterThan(0));
    });

    test('today caffeine near baseline -> no weight', () {
      final s = module.evaluate(
        build(
          entries: [
            JournalEntry(
              at: now.subtract(const Duration(hours: 3)),
              kind: JournalKind.caffeine,
              payload: {'mg': 180},
            ),
          ],
          baselineMg: 200,
        ),
        params,
      );
      expect(s.weight, 0);
    });
  });
}
