import '../config/rules_config.dart';
import '../engine/trigger_module.dart';
import '../types/data_requirement.dart';
import '../types/evaluation_context.dart';
import '../types/journal.dart';
import '../types/trigger_signal.dart';

class HydrationModule implements TriggerModule {
  @override
  String get id => 'hydration';
  @override
  Set<DataRequirement> get requires => {DataRequirement.journalHydration};
  @override
  Duration get leadTime => const Duration(hours: 6);

  @override
  TriggerSignal evaluate(EvaluationContext ctx, ModuleParams params) {
    final todayStart = DateTime.utc(ctx.now.year, ctx.now.month, ctx.now.day);
    final entries = ctx.recentJournal
        .where((e) => e.kind == JournalKind.hydration && !e.at.isBefore(todayStart))
        .toList();
    if (entries.isEmpty) {
      return TriggerSignal.zero(
        moduleId: id,
        reason: 'No hydration log today',
        missing: DataRequirement.journalHydration,
      );
    }
    final totalLiters = entries.fold<double>(
      0,
      (acc, e) => acc + ((e.payload['liters'] as num?)?.toDouble() ?? 0),
    );
    final minLiters = params.getDouble('min_liters', 1.5);
    if (totalLiters >= minLiters) {
      return TriggerSignal(
        moduleId: id,
        weight: 0,
        confidence: 1.0,
        explanation: 'Hydration ${totalLiters.toStringAsFixed(1)} L',
      );
    }
    final deficitT = ((minLiters - totalLiters) / minLiters).clamp(0.0, 1.0);
    double weight = params.weightMax * deficitT;
    // Amplify in hot weather (>28°C max temp last 24h).
    double tempMax = 0;
    if (ctx.weather != null && ctx.weather!.samples.isNotEmpty) {
      tempMax = ctx.weather!.samples
          .where((s) => !s.at.isBefore(ctx.now.subtract(const Duration(hours: 24))))
          .map((s) => s.temperatureC)
          .fold<double>(0, (a, b) => a > b ? a : b);
    }
    if (tempMax > 28) {
      weight *= 1.25;
    }
    return TriggerSignal(
      moduleId: id,
      weight: weight.clamp(0.0, params.weightMax),
      confidence: 1.0,
      explanation: 'Low hydration (${totalLiters.toStringAsFixed(1)} L)',
    );
  }
}
