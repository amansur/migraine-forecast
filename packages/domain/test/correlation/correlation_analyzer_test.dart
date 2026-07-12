import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('CorrelationAnalyzer', () {
    final analyzer = const CorrelationAnalyzer();

    test('refuses to produce a result with too few attacks', () {
      final input = const Cohort(
        exposureId: 'pressure_drop',
        daysFiredWithAttack: 1,
        daysFiredTotal: 5,
        daysNotFiredWithAttack: 0,
        daysNotFiredTotal: 30,
      );
      final result = analyzer.analyze(input, minAttacks: 3);
      expect(result.classification, CorrelationClassification.insufficientData);
    });

    test('clear positive correlation produces a hit', () {
      final input = const Cohort(
        exposureId: 'pressure_drop',
        daysFiredWithAttack: 7,        // module fired, attack happened
        daysFiredTotal: 10,            // 70% attack rate when fired
        daysNotFiredWithAttack: 2,
        daysNotFiredTotal: 50,         // 4% attack rate when not fired
      );
      final result = analyzer.analyze(input, minAttacks: 3);
      expect(result.classification, CorrelationClassification.personalHit);
      expect(result.firedAttackRate.point, closeTo(0.7, 0.01));
      expect(result.notFiredAttackRate.point, closeTo(0.04, 0.01));
      expect(result.lift.point, greaterThan(0.5));
      expect(result.lift.low, greaterThan(0));  // CI excludes 0
    });

    test('clear negative correlation produces a miss', () {
      final input = const Cohort(
        exposureId: 'humidity_temp_swing',
        daysFiredWithAttack: 0,
        daysFiredTotal: 20,            // 0% attack rate when fired
        daysNotFiredWithAttack: 8,
        daysNotFiredTotal: 40,         // 20% attack rate when not fired
      );
      final result = analyzer.analyze(input, minAttacks: 3);
      expect(result.classification, CorrelationClassification.personalMiss);
    });

    test('ambiguous correlation produces inconclusive', () {
      final input = const Cohort(
        exposureId: 'caffeine',
        daysFiredWithAttack: 3,
        daysFiredTotal: 10,            // 30%
        daysNotFiredWithAttack: 7,
        daysNotFiredTotal: 30,         // 23%
      );
      final result = analyzer.analyze(input, minAttacks: 3);
      expect(result.classification, CorrelationClassification.inconclusive);
    });
  });
}
