import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('StressModule', () {
    final module = StressModule();
    const params = ModuleParams(enabled: true, weightMax: 12);
    final now = DateTime.utc(2026, 6, 10, 6);
    final target = DateTime.utc(2026, 6, 10);

    EvaluationContext withEntries(List<JournalEntry> entries) => EvaluationContext(
          now: now,
          targetDate: target,
          recentJournal: entries,
          baselines: BaselineSnapshot.empty,
        );

    test('no stress entries -> zero confidence', () {
      expect(module.evaluate(withEntries(const []), params).confidence, 0);
    });

    test('high stress rating -> high weight', () {
      final s = module.evaluate(
        withEntries([
          JournalEntry(
            at: now.subtract(const Duration(hours: 4)),
            kind: JournalKind.stress,
            payload: {'rating': 5},
          ),
        ]),
        params,
      );
      expect(s.weight, closeTo(8.4, 0.5)); // 12 * 0.7 = 8.4 at rating 5
    });

    test('low stress rating -> no weight', () {
      final s = module.evaluate(
        withEntries([
          JournalEntry(
            at: now.subtract(const Duration(hours: 4)),
            kind: JournalKind.stress,
            payload: {'rating': 1},
          ),
        ]),
        params,
      );
      expect(s.weight, 0);
    });

    test('let-down: sudden drop from high to low yields weight', () {
      final s = module.evaluate(
        withEntries([
          // ordered earliest first; module sorts internally
          JournalEntry(at: now.subtract(const Duration(hours: 30)), kind: JournalKind.stress, payload: {'rating': 5}),
          JournalEntry(at: now.subtract(const Duration(hours: 24)), kind: JournalKind.stress, payload: {'rating': 5}),
          JournalEntry(at: now.subtract(const Duration(hours: 4)), kind: JournalKind.stress, payload: {'rating': 2}),
        ]),
        params,
      );
      // Current low (2) overrides direct contribution, but let-down adds.
      expect(s.weight, greaterThan(0));
      expect(s.explanation.toLowerCase(), contains('let-down'));
    });
  });
}
