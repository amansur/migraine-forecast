import 'dart:math';
import '../config/rules_config.dart';
import '../engine/trigger_module.dart';
import '../types/data_requirement.dart';
import '../types/evaluation_context.dart';
import '../types/trigger_signal.dart';

class MenstrualPhaseModule implements TriggerModule {
  @override
  String get id => 'menstrual_phase';
  @override
  Set<DataRequirement> get requires => {DataRequirement.healthMenstrual};
  @override
  Duration get leadTime => const Duration(days: 5);

  @override
  TriggerSignal evaluate(EvaluationContext ctx, ModuleParams params) {
    final history = ctx.health?.menstrualHistory ?? const [];
    if (history.isEmpty) {
      return TriggerSignal.zero(
        moduleId: id,
        reason: 'No cycle data',
        missing: DataRequirement.healthMenstrual,
      );
    }
    final windowRaw = params.params['window_days'];
    final List<int> window = (windowRaw is List)
        ? windowRaw.map((e) => (e as num).toInt()).toList()
        : const [-2, 3];

    // Predict next/most-recent onset.
    final sortedOnsets = [...history.map((e) => e.onsetDate)]..sort();
    int? avgCycleDays;
    double cycleStdDev = 0;
    if (sortedOnsets.length >= 2) {
      final diffs = <int>[];
      for (var i = 1; i < sortedOnsets.length; i++) {
        diffs.add(sortedOnsets[i].difference(sortedOnsets[i - 1]).inDays);
      }
      avgCycleDays = (diffs.reduce((a, b) => a + b) / diffs.length).round();
      final mean = avgCycleDays.toDouble();
      final variance = diffs.map((d) => pow(d - mean, 2)).reduce((a, b) => a + b) / diffs.length;
      cycleStdDev = sqrt(variance);
    }

    // Nearest predicted onset to targetDate.
    DateTime predictedOnset = sortedOnsets.last;
    if (avgCycleDays != null) {
      while (predictedOnset.isBefore(ctx.targetDate.subtract(const Duration(days: 14)))) {
        predictedOnset = predictedOnset.add(Duration(days: avgCycleDays));
      }
    }

    final dayOffset = ctx.targetDate.difference(predictedOnset).inDays;
    final inWindow = dayOffset >= window[0] && dayOffset <= window[1];

    double confidence = 1.0;
    if (sortedOnsets.length < 3) {
      confidence = 0.6;
    } else if (cycleStdDev > 5) {
      confidence = 0.5;
    }

    return TriggerSignal(
      moduleId: id,
      weight: inWindow ? params.weightMax : 0,
      confidence: confidence,
      explanation: inWindow
          ? 'Perimenstrual window (day ${dayOffset >= 0 ? '+' : ''}$dayOffset)'
          : 'Outside perimenstrual window',
    );
  }
}
