import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/services/suggestion_engine.dart';

CorrelationResult _hit(String moduleId) => CorrelationResult(
      exposureId: moduleId,
      classification: CorrelationClassification.personalHit,
      firedAttackRate: WilsonInterval.compute(successes: 7, trials: 10),
      notFiredAttackRate: WilsonInterval.compute(successes: 2, trials: 50),
      lift: WilsonInterval.differenceLift(
        WilsonInterval.compute(successes: 7, trials: 10),
        WilsonInterval.compute(successes: 2, trials: 50),
      ),
      totalAttacks: 9,
    );

CorrelationResult _miss(String moduleId) => CorrelationResult(
      exposureId: moduleId,
      classification: CorrelationClassification.personalMiss,
      firedAttackRate: WilsonInterval.compute(successes: 0, trials: 20),
      notFiredAttackRate: WilsonInterval.compute(successes: 8, trials: 40),
      lift: WilsonInterval.differenceLift(
        WilsonInterval.compute(successes: 0, trials: 20),
        WilsonInterval.compute(successes: 8, trials: 40),
      ),
      totalAttacks: 8,
    );

CorrelationResult _none(String moduleId) => CorrelationResult(
      exposureId: moduleId,
      classification: CorrelationClassification.inconclusive,
      firedAttackRate: WilsonInterval.compute(successes: 3, trials: 10),
      notFiredAttackRate: WilsonInterval.compute(successes: 4, trials: 20),
      lift: WilsonInterval.differenceLift(
        WilsonInterval.compute(successes: 3, trials: 10),
        WilsonInterval.compute(successes: 4, trials: 20),
      ),
      totalAttacks: 7,
    );

void main() {
  const engine = SuggestionEngine();

  test('hits with no existing override suggest +1', () {
    final out = engine.suggestionsFor(
      results: [_hit('pressure_drop')],
      currentOverrides: const {},
      dismissedAt: const {},
      now: DateTime.utc(2026, 6, 11),
    );
    expect(out, hasLength(1));
    expect(out.first.moduleId, 'pressure_drop');
    expect(out.first.recommendedOverride, 1.0);
  });

  test('misses suggest -1', () {
    final out = engine.suggestionsFor(
      results: [_miss('humidity_temp_swing')],
      currentOverrides: const {},
      dismissedAt: const {},
      now: DateTime.utc(2026, 6, 11),
    );
    expect(out, hasLength(1));
    expect(out.first.recommendedOverride, -1.0);
  });

  test('already maxed override produces no suggestion', () {
    final out = engine.suggestionsFor(
      results: [_hit('pressure_drop')],
      currentOverrides: const {'pressure_drop': 2.0},
      dismissedAt: const {},
      now: DateTime.utc(2026, 6, 11),
    );
    expect(out, isEmpty);
  });

  test('recently dismissed suggestion is suppressed for 14 days', () {
    final out = engine.suggestionsFor(
      results: [_hit('pressure_drop')],
      currentOverrides: const {},
      dismissedAt: {'pressure_drop': DateTime.utc(2026, 6, 1)},
      now: DateTime.utc(2026, 6, 10),
    );
    expect(out, isEmpty);

    final later = engine.suggestionsFor(
      results: [_hit('pressure_drop')],
      currentOverrides: const {},
      dismissedAt: {'pressure_drop': DateTime.utc(2026, 6, 1)},
      now: DateTime.utc(2026, 6, 20),
    );
    expect(later, hasLength(1));
  });

  test('inconclusive results never suggest', () {
    final out = engine.suggestionsFor(
      results: [_none('caffeine')],
      currentOverrides: const {},
      dismissedAt: const {},
      now: DateTime.utc(2026, 6, 11),
    );
    expect(out, isEmpty);
  });
}
