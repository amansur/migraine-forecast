import 'package:equatable/equatable.dart';

import 'wilson_interval.dart';

enum CorrelationClassification {
  personalHit,
  personalMiss,
  inconclusive,
  insufficientData,
}

/// A 2×2 contingency table for any day-level exposure (a trigger module
/// firing, a weekday, a pair of modules firing together, …) vs attack days.
class Cohort extends Equatable {
  final String exposureId;
  final int daysFiredWithAttack;
  final int daysFiredTotal;
  final int daysNotFiredWithAttack;
  final int daysNotFiredTotal;
  const Cohort({
    required this.exposureId,
    required this.daysFiredWithAttack,
    required this.daysFiredTotal,
    required this.daysNotFiredWithAttack,
    required this.daysNotFiredTotal,
  });

  int get totalAttacks => daysFiredWithAttack + daysNotFiredWithAttack;
  int get totalDays => daysFiredTotal + daysNotFiredTotal;

  @override
  List<Object?> get props => [
        exposureId,
        daysFiredWithAttack,
        daysFiredTotal,
        daysNotFiredWithAttack,
        daysNotFiredTotal,
      ];
}

class CorrelationResult extends Equatable {
  final String exposureId;
  final CorrelationClassification classification;
  final WilsonInterval firedAttackRate;
  final WilsonInterval notFiredAttackRate;
  final LiftInterval lift;
  final int totalAttacks;
  const CorrelationResult({
    required this.exposureId,
    required this.classification,
    required this.firedAttackRate,
    required this.notFiredAttackRate,
    required this.lift,
    required this.totalAttacks,
  });

  @override
  List<Object?> get props =>
      [exposureId, classification, firedAttackRate, notFiredAttackRate, lift, totalAttacks];
}

class CorrelationAnalyzer {
  const CorrelationAnalyzer();

  CorrelationResult analyze(Cohort c, {int minAttacks = 3}) {
    final fired = WilsonInterval.compute(
      successes: c.daysFiredWithAttack,
      trials: c.daysFiredTotal,
    );
    final notFired = WilsonInterval.compute(
      successes: c.daysNotFiredWithAttack,
      trials: c.daysNotFiredTotal,
    );
    final lift = WilsonInterval.differenceLift(fired, notFired);

    CorrelationClassification cls;
    if (c.totalAttacks < minAttacks || c.totalDays < 14) {
      cls = CorrelationClassification.insufficientData;
    } else if (lift.low > 0 &&
        c.daysFiredWithAttack >= minAttacks &&
        fired.point >= 2 * notFired.point) {
      cls = CorrelationClassification.personalHit;
    } else if (lift.high < 0 && c.daysNotFiredWithAttack >= minAttacks) {
      cls = CorrelationClassification.personalMiss;
    } else {
      cls = CorrelationClassification.inconclusive;
    }

    return CorrelationResult(
      exposureId: c.exposureId,
      classification: cls,
      firedAttackRate: fired,
      notFiredAttackRate: notFired,
      lift: lift,
      totalAttacks: c.totalAttacks,
    );
  }
}
