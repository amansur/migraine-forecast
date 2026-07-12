import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  final now = DateTime.utc(2026, 7, 9, 18);
  final target = DateTime.utc(2026, 7, 9);
  const params = ModuleParams(
      enabled: true, weightMax: 10, params: {'lookback_hours': 24});
  EvaluationContext ctx(List<JournalEntry> journal) => EvaluationContext(
      now: now,
      targetDate: target,
      recentJournal: journal,
      baselines: BaselineSnapshot.empty);
  final m = SkippedMealModule();

  test('module id and requirement', () {
    expect(m.id, 'skipped_meals');
    expect(m.requires, {DataRequirement.journalMeals});
  });

  test('no meal entries ever → zero-confidence with missing requirement', () {
    final s = m.evaluate(ctx(const []), params);
    expect(s.weight * s.confidence, 0);
    expect(s.missing, DataRequirement.journalMeals);
  });

  test('one skipped meal in lookback → 60% of weightMax', () {
    final s = m.evaluate(
        ctx([
          JournalEntry(
              at: now.subtract(const Duration(hours: 3)),
              kind: JournalKind.skippedMeal,
              payload: const {'meal': 'lunch'}),
        ]),
        params);
    expect(s.weight, closeTo(6.0, 1e-9));
    expect(s.confidence, 1.0);
  });

  test('two or more skipped meals → full weightMax', () {
    final s = m.evaluate(
        ctx([
          JournalEntry(
              at: now.subtract(const Duration(hours: 3)),
              kind: JournalKind.skippedMeal,
              payload: const {'meal': 'lunch'}),
          JournalEntry(
              at: now.subtract(const Duration(hours: 9)),
              kind: JournalKind.skippedMeal,
              payload: const {'meal': 'breakfast'}),
        ]),
        params);
    expect(s.weight, 10.0);
  });

  test('entries exist but none in lookback → weight 0, confidence 1', () {
    final s = m.evaluate(
        ctx([
          JournalEntry(
              at: now.subtract(const Duration(days: 5)),
              kind: JournalKind.skippedMeal,
              payload: const {'meal': 'dinner'}),
        ]),
        params);
    expect(s.weight, 0);
    expect(s.confidence, 1.0);
  });
}
