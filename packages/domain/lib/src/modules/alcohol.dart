import '../config/rules_config.dart';
import '../engine/trigger_module.dart';
import '../types/data_requirement.dart';
import '../types/evaluation_context.dart';
import '../types/journal.dart';
import '../types/trigger_signal.dart';

class AlcoholModule implements TriggerModule {
  @override
  String get id => 'alcohol';
  @override
  Set<DataRequirement> get requires => {DataRequirement.journalAlcohol};
  @override
  Duration get leadTime => const Duration(hours: 12);

  @override
  TriggerSignal evaluate(EvaluationContext ctx, ModuleParams params) {
    final lookback = Duration(hours: params.getInt('lookback_hours', 24));
    final earliest = ctx.now.subtract(lookback);

    // Check if any alcohol entries exist at all
    final anyAlcoholEntries = ctx.recentJournal
        .where((e) => e.kind == JournalKind.alcohol)
        .isNotEmpty;

    if (!anyAlcoholEntries) {
      return TriggerSignal.zero(
        moduleId: id,
        reason: 'No alcohol log',
        missing: DataRequirement.journalAlcohol,
      );
    }

    // Get entries within lookback window
    final relevant = ctx.recentJournal
        .where((e) => e.kind == JournalKind.alcohol && !e.at.isBefore(earliest))
        .toList();

    // If no entries within lookback, return zero weight with full confidence
    if (relevant.isEmpty) {
      return TriggerSignal(
        moduleId: id,
        weight: 0,
        confidence: 1.0,
        explanation: 'No alcohol in last ${lookback.inHours}h',
      );
    }

    final totalUnits = relevant.fold<double>(
      0,
      (acc, e) => acc + ((e.payload['units'] as num?)?.toDouble() ?? 0),
    );

    if (totalUnits <= 0) {
      return TriggerSignal(
        moduleId: id,
        weight: 0,
        confidence: 1.0,
        explanation: 'No alcohol in last ${lookback.inHours}h',
      );
    }
    // 1 unit = ramp start; 3 units = saturation.
    final t = ((totalUnits - 1) / 2).clamp(0.0, 1.0);
    final weight = params.weightMax * (0.4 + 0.6 * t);
    return TriggerSignal(
      moduleId: id,
      weight: weight,
      confidence: 1.0,
      explanation: '${totalUnits.toStringAsFixed(1)} alcohol units in last ${lookback.inHours}h',
    );
  }
}
