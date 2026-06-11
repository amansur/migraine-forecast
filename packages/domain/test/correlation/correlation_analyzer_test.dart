import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('CorrelationAnalyzer', () {
    final analyzer = const CorrelationAnalyzer();

    test('refuses to produce a result with too few attacks', () {
      final input = ModuleCohort(
        moduleId: 'pressure_drop',
        daysFiredWithAttack: 1,
        daysFiredTotal: 5,
        daysNotFiredWithAttack: 0,
        daysNotFiredTotal: 30,
      );
      final result = analyzer.analyze(input, minAttacks: 3);
      expect(result.classification, CorrelationClassification.insufficientData);
    });

    test('clear positive correlation produces a hit', () {
      final input = ModuleCohort(
        moduleId: 'pressure_drop',
        daysFiredWithAttack: 7,
        daysFiredTotal: 10,
        daysNotFiredWithAttack: 2,
        daysNotFiredTotal: 50,
      );
      final result = analyzer.analyze(input, minAttacks: 3);
      expect(result.classification, CorrelationClassification.personalHit);
      expect(result.firedAttackRate.point, closeTo(0.7, 0.01));
      expect(result.notFiredAttackRate.point, closeTo(0.04, 0.01));
      expect(result.lift.point, greaterThan(0.5));
      expect(result.lift.low, greaterThan(0));
    });

    test('clear negative correlation produces a miss', () {
      final input = ModuleCohort(
        moduleId: 'humidity_temp_swing',
        daysFiredWithAttack: 0,
        daysFiredTotal: 20,
        daysNotFiredWithAttack: 8,
        daysNotFiredTotal: 40,
      );
      final result = analyzer.analyze(input, minAttacks: 3);
      expect(result.classification, CorrelationClassification.personalMiss);
    });

    test('ambiguous correlation produces inconclusive', () {
      final input = ModuleCohort(
        moduleId: 'caffeine',
        daysFiredWithAttack: 3,
        daysFiredTotal: 10,
        daysNotFiredWithAttack: 7,
        daysNotFiredTotal: 30,
      );
      final result = analyzer.analyze(input, minAttacks: 3);
      expect(result.classification, CorrelationClassification.inconclusive);
    });
  });
}
