import 'correlation_analyzer.dart';
import 'day_record.dart';
import 'exposure.dart';

class InteractionResult {
  final String idA;
  final String idB;
  final CorrelationResult pair;
  final double singleLiftA;
  final double singleLiftB;
  const InteractionResult({
    required this.idA,
    required this.idB,
    required this.pair,
    required this.singleLiftA,
    required this.singleLiftB,
  });
}

/// Pairwise "A and B fired the same day" exposures. Deliberately conservative:
/// support floors + the pair must be a personalHit AND its lift CI's lower
/// bound must clear BOTH single lift points — otherwise "A + B" surfaces
/// whenever A is a strong trigger and B is noise (the pair being a random
/// subsample of A's days beats A's point ~half the time). At most
/// [maxResults] are returned — this is pattern-surfacing, not hypothesis
/// testing across dozens of comparisons.
List<InteractionResult> analyzeInteractions(
  List<DayRecord> days,
  List<String> moduleIds, {
  int minSingleFiredDays = 10,
  int minPairFiredDays = 7,
  int maxResults = 3,
}) {
  const analyzer = CorrelationAnalyzer();
  final singles = <String, CorrelationResult>{};
  for (final id in moduleIds) {
    final c = buildCohort(days, Exposure.moduleFired(id));
    if (c.daysFiredTotal >= minSingleFiredDays) singles[id] = analyzer.analyze(c);
  }
  final ids = singles.keys.toList();
  final out = <InteractionResult>[];
  for (var i = 0; i < ids.length; i++) {
    for (var j = i + 1; j < ids.length; j++) {
      final cohort = buildCohort(days,
          Exposure.both(Exposure.moduleFired(ids[i]), Exposure.moduleFired(ids[j])));
      if (cohort.daysFiredTotal < minPairFiredDays) continue;
      final pair = analyzer.analyze(cohort);
      if (pair.classification != CorrelationClassification.personalHit) continue;
      final la = singles[ids[i]]!.lift.point;
      final lb = singles[ids[j]]!.lift.point;
      if (pair.lift.low <= la || pair.lift.low <= lb) continue;
      out.add(InteractionResult(
          idA: ids[i], idB: ids[j], pair: pair, singleLiftA: la, singleLiftB: lb));
    }
  }
  out.sort((a, b) => b.pair.lift.point.compareTo(a.pair.lift.point));
  return out.take(maxResults).toList();
}
