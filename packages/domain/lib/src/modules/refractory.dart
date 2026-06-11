import '../config/rules_config.dart';
import '../engine/trigger_module.dart';
import '../types/data_requirement.dart';
import '../types/evaluation_context.dart';
import '../types/trigger_signal.dart';

class RefractoryModule implements TriggerModule {
  @override
  String get id => 'refractory';
  @override
  Set<DataRequirement> get requires => {DataRequirement.attackHistory};
  @override
  Duration get leadTime => const Duration(hours: 24);

  @override
  TriggerSignal evaluate(EvaluationContext ctx, ModuleParams params) {
    if (ctx.recentAttacks.isEmpty) {
      return TriggerSignal.zero(
        moduleId: id,
        reason: 'No attack history',
        missing: DataRequirement.attackHistory,
      );
    }
    final suppressionHours = params.getInt('suppression_hours', 48);
    final reboundUntilHours = suppressionHours + 48;

    // Most recent attack
    final sorted = [...ctx.recentAttacks]
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    final last = sorted.first;
    final hoursSince = ctx.now.difference(last.startedAt).inHours;

    if (hoursSince < suppressionHours) {
      return TriggerSignal(
        moduleId: id,
        weight: 0,
        confidence: 1.0,
        explanation: 'Refractory after recent attack',
      );
    }
    if (hoursSince < reboundUntilHours) {
      // Small rebound bump centered between suppression and rebound end.
      final t = ((hoursSince - suppressionHours) / 48).clamp(0.0, 1.0);
      final bell = 4 * t * (1 - t); // peak at t=0.5
      return TriggerSignal(
        moduleId: id,
        weight: params.weightMax * bell,
        confidence: 1.0,
        explanation: 'Post-attack rebound window',
      );
    }
    return TriggerSignal(
      moduleId: id,
      weight: 0,
      confidence: 1.0,
      explanation: 'No recent attacks',
    );
  }
}
