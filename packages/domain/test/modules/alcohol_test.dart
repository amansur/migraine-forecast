import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('AlcoholModule', () {
    final module = AlcoholModule();
    const params = ModuleParams(
      enabled: true,
      weightMax: 12,
      params: {'lookback_hours': 24},
    );
    final now = DateTime.utc(2026, 6, 10, 6);
    final target = DateTime.utc(2026, 6, 10);

    EvaluationContext withJournal(List<JournalEntry> entries) => EvaluationContext(
          now: now,
          targetDate: target,
          recentJournal: entries,
          baselines: BaselineSnapshot.empty,
        );

    test('no journal entries -> zero confidence (missing data)', () {
      final s = module.evaluate(withJournal(const []), params);
      expect(s.confidence, 0);
      expect(s.missing, DataRequirement.journalAlcohol);
    });

    test('alcohol entry within lookback -> proportional to units', () {
      final s = module.evaluate(
        withJournal([
          JournalEntry(
            at: now.subtract(const Duration(hours: 6)),
            kind: JournalKind.alcohol,
            payload: {'units': 2.0},
          ),
        ]),
        params,
      );
      expect(s.weight, greaterThan(0));
      expect(s.confidence, 1.0);
    });

    test('alcohol older than lookback -> zero weight, full confidence', () {
      final s = module.evaluate(
        withJournal([
          JournalEntry(
            at: now.subtract(const Duration(hours: 36)),
            kind: JournalKind.alcohol,
            payload: {'units': 4.0},
          ),
        ]),
        params,
      );
      expect(s.weight, 0);
      expect(s.confidence, 1.0);
    });

    test('explicit "none" entry within lookback -> zero, full confidence', () {
      final s = module.evaluate(
        withJournal([
          JournalEntry(
            at: now.subtract(const Duration(hours: 6)),
            kind: JournalKind.alcohol,
            payload: {'units': 0.0},
          ),
        ]),
        params,
      );
      expect(s.weight, 0);
      expect(s.confidence, 1.0);
    });
  });
}
