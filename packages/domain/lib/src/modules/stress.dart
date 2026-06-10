import '../config/rules_config.dart';
import '../engine/trigger_module.dart';
import '../types/data_requirement.dart';
import '../types/evaluation_context.dart';
import '../types/journal.dart';
import '../types/trigger_signal.dart';

class StressModule implements TriggerModule {
  @override
  String get id => 'stress';
  @override
  Set<DataRequirement> get requires => {DataRequirement.journalStress};
  @override
  Duration get leadTime => const Duration(hours: 12);

  @override
  TriggerSignal evaluate(EvaluationContext ctx, ModuleParams params) {
    final stress = ctx.recentJournal
        .where((e) => e.kind == JournalKind.stress)
        .toList()
      ..sort((a, b) => a.at.compareTo(b.at));
    if (stress.isEmpty) {
      return TriggerSignal.zero(
        moduleId: id,
        reason: 'No stress log',
        missing: DataRequirement.journalStress,
      );
    }
    final last = stress.last;
    final rating = ((last.payload['rating'] as num?)?.toInt() ?? 0).clamp(1, 5);
    // Direct contribution: linear from rating 3 to 5.
    final directT = ((rating - 3) / 2).clamp(0.0, 1.0).toDouble();
    double weight = params.weightMax * 0.7 * directT;
    final reasons = <String>[];
    if (rating >= 4) reasons.add('high stress');

    // Let-down detection: prior 24-48h had high stress (≥4) AND current ≤2.
    final cutoff = ctx.now.subtract(const Duration(hours: 48));
    final earlier = stress
        .where((e) => e.at.isBefore(ctx.now.subtract(const Duration(hours: 6))) &&
            !e.at.isBefore(cutoff))
        .toList();
    final earlierWasHigh = earlier.any(
      (e) => ((e.payload['rating'] as num?)?.toInt() ?? 0) >= 4,
    );
    if (rating <= 2 && earlierWasHigh) {
      weight += params.weightMax * 0.3;
      reasons.add('let-down');
    }
    return TriggerSignal(
      moduleId: id,
      weight: weight.clamp(0.0, params.weightMax),
      confidence: 1.0,
      explanation: reasons.isEmpty ? 'Stress rating $rating/5' : reasons.join(', '),
    );
  }
}
