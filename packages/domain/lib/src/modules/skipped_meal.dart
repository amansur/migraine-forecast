import '../config/rules_config.dart';
import '../engine/trigger_module.dart';
import '../types/data_requirement.dart';
import '../types/evaluation_context.dart';
import '../types/journal.dart';
import '../types/trigger_signal.dart';

/// Fasting / missed meals are among the most frequently self-reported triggers
/// (Kelman 2007, Cephalalgia — reported by ~57% of patients; Martin & Vij
/// 2016 review). One skipped meal ramps to 60% of weight_max; two or more
/// saturate.
class SkippedMealModule implements TriggerModule {
  @override
  String get id => 'skipped_meals';
  @override
  Set<DataRequirement> get requires => {DataRequirement.journalMeals};
  @override
  Duration get leadTime => const Duration(hours: 12);

  @override
  TriggerSignal evaluate(EvaluationContext ctx, ModuleParams params) {
    final lookback = Duration(hours: params.getInt('lookback_hours', 24));
    final earliest = ctx.now.subtract(lookback);
    final any = ctx.recentJournal.any((e) => e.kind == JournalKind.skippedMeal);
    if (!any) {
      return TriggerSignal.zero(
          moduleId: id,
          reason: 'No meals log',
          missing: DataRequirement.journalMeals);
    }
    final count = ctx.recentJournal
        .where((e) => e.kind == JournalKind.skippedMeal && !e.at.isBefore(earliest))
        .length;
    if (count == 0) {
      return TriggerSignal(
          moduleId: id,
          weight: 0,
          confidence: 1.0,
          explanation: 'No skipped meals in last ${lookback.inHours}h');
    }
    final weight = params.weightMax * (count == 1 ? 0.6 : 1.0);
    return TriggerSignal(
        moduleId: id,
        weight: weight,
        confidence: 1.0,
        explanation:
            '$count skipped meal${count == 1 ? '' : 's'} in last ${lookback.inHours}h');
  }
}
