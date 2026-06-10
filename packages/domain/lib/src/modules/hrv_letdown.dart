import '../config/rules_config.dart';
import '../engine/trigger_module.dart';
import '../types/data_requirement.dart';
import '../types/evaluation_context.dart';
import '../types/trigger_signal.dart';

class HrvLetdownModule implements TriggerModule {
  @override
  String get id => 'hrv_letdown';
  @override
  Set<DataRequirement> get requires => {DataRequirement.healthHrv};
  @override
  Duration get leadTime => const Duration(hours: 18);

  @override
  TriggerSignal evaluate(EvaluationContext ctx, ModuleParams params) {
    final health = ctx.health;
    if (health == null || health.recentHrv.isEmpty) {
      return TriggerSignal.zero(
        moduleId: id,
        reason: 'No HRV data',
        missing: DataRequirement.healthHrv,
      );
    }
    final dropPct = params.getDouble('drop_pct', 20);
    final baseline = ctx.baselines.hrvRmssdBaseline14d;
    final recent = health.recentHrv.first.rmssdMs;
    if (baseline == null) {
      return TriggerSignal(
        moduleId: id,
        weight: 0,
        confidence: 0.5,
        explanation: 'HRV baseline still calibrating',
      );
    }
    if (recent >= baseline) {
      return TriggerSignal(
        moduleId: id,
        weight: 0,
        confidence: 1.0,
        explanation: 'HRV within range',
      );
    }
    final pctDrop = ((baseline - recent) / baseline) * 100;
    if (pctDrop < dropPct) {
      return TriggerSignal(
        moduleId: id,
        weight: 0,
        confidence: 1.0,
        explanation: 'HRV ${recent.toStringAsFixed(0)} vs baseline ${baseline.toStringAsFixed(0)}',
      );
    }
    final saturation = dropPct * 2;
    final t = ((pctDrop - dropPct) / (saturation - dropPct)).clamp(0.0, 1.0);
    return TriggerSignal(
      moduleId: id,
      weight: params.weightMax * t,
      confidence: 1.0,
      explanation: 'HRV down ${pctDrop.toStringAsFixed(0)}% from baseline',
    );
  }
}
