import '../config/rules_config.dart';
import '../engine/trigger_module.dart';
import '../types/data_requirement.dart';
import '../types/evaluation_context.dart';
import '../types/trigger_signal.dart';

class SleepDeficitModule implements TriggerModule {
  @override
  String get id => 'sleep_deficit';
  @override
  Set<DataRequirement> get requires => {DataRequirement.healthSleep};
  @override
  Duration get leadTime => const Duration(hours: 24);

  @override
  TriggerSignal evaluate(EvaluationContext ctx, ModuleParams params) {
    final health = ctx.health;
    if (health == null || health.recentSleep.isEmpty) {
      return TriggerSignal.zero(
        moduleId: id,
        reason: 'No sleep data',
        missing: DataRequirement.healthSleep,
      );
    }
    final hoursThreshold = params.getDouble('hours_threshold', 6);
    final efficiencyThreshold = params.getDouble('efficiency_threshold', 0.85);
    final typicalHour = params.getDouble('typical_sleep_start_hour', 22);

    final last = health.recentSleep.first;
    final hours = last.totalSleep.inMinutes / 60.0;

    double weight = 0;
    final reasons = <String>[];

    // 1. Hours deficit
    if (hours < hoursThreshold) {
      final deficitT =
          ((hoursThreshold - hours) / hoursThreshold).clamp(0.0, 1.0);
      weight += params.weightMax * 0.5 * deficitT;
      reasons.add('${hours.toStringAsFixed(1)}h sleep');
    }

    // 2. Efficiency deficit
    if (last.efficiency < efficiencyThreshold) {
      final effT = ((efficiencyThreshold - last.efficiency) / efficiencyThreshold)
          .clamp(0.0, 1.0);
      weight += params.weightMax * 0.25 * effT;
      reasons.add('${(last.efficiency * 100).round()}% efficiency');
    }

    // 3. Schedule shift
    final startHour = last.sleepStart.toUtc().hour.toDouble();
    final shift = (startHour - typicalHour).abs();
    if (shift > 2) {
      weight += params.weightMax * 0.25 * ((shift - 2) / 4).clamp(0.0, 1.0);
      reasons.add('schedule shift ${shift.toStringAsFixed(0)}h');
    }

    final hasBaseline = ctx.baselines.sleepMedian7d != null;
    return TriggerSignal(
      moduleId: id,
      weight: weight.clamp(0.0, params.weightMax),
      confidence: hasBaseline ? 1.0 : 0.5,
      explanation: reasons.isEmpty ? 'Sleep on track' : reasons.join(', '),
    );
  }
}
