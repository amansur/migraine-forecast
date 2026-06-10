import '../config/rules_config.dart';
import '../engine/trigger_module.dart';
import '../types/data_requirement.dart';
import '../types/evaluation_context.dart';
import '../types/journal.dart';
import '../types/trigger_signal.dart';

class CaffeineModule implements TriggerModule {
  @override
  String get id => 'caffeine';
  @override
  Set<DataRequirement> get requires => {DataRequirement.journalCaffeine};
  @override
  Duration get leadTime => const Duration(hours: 24);

  @override
  TriggerSignal evaluate(EvaluationContext ctx, ModuleParams params) {
    final baseline = ctx.baselines.caffeineDailyMg;
    final caffEntries = ctx.recentJournal.where((e) => e.kind == JournalKind.caffeine);
    if (baseline == null && caffEntries.isEmpty) {
      return TriggerSignal.zero(
        moduleId: id,
        reason: 'No caffeine baseline yet',
        missing: DataRequirement.journalCaffeine,
      );
    }
    if (baseline == null) {
      // Have some entries but no baseline yet.
      return TriggerSignal(
        moduleId: id,
        weight: 0,
        confidence: 0.5,
        explanation: 'Caffeine baseline calibrating',
      );
    }
    final todayStart = DateTime.utc(ctx.now.year, ctx.now.month, ctx.now.day);
    final todayMg = caffEntries
        .where((e) => !e.at.isBefore(todayStart))
        .fold<double>(0, (acc, e) => acc + ((e.payload['mg'] as num?)?.toDouble() ?? 0));
    final delta = baseline - todayMg; // positive = withdrawal
    final threshold = params.getDouble('delta_mg_threshold', 100);
    if (delta < threshold) {
      return TriggerSignal(
        moduleId: id,
        weight: 0,
        confidence: 1.0,
        explanation: 'Caffeine ${todayMg.round()}mg vs baseline ${baseline.round()}mg',
      );
    }
    final saturation = threshold * 2;
    final t = ((delta - threshold) / (saturation - threshold)).clamp(0.0, 1.0);
    return TriggerSignal(
      moduleId: id,
      weight: params.weightMax * t,
      confidence: 1.0,
      explanation: 'Caffeine ${delta.round()}mg below baseline',
    );
  }
}
