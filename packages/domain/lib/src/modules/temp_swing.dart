import '../config/rules_config.dart';
import '../engine/trigger_module.dart';
import '../types/data_requirement.dart';
import '../types/evaluation_context.dart';
import '../types/trigger_signal.dart';

class TempSwingModule implements TriggerModule {
  @override
  String get id => 'temp_swing';
  @override
  Set<DataRequirement> get requires => {DataRequirement.weatherTemperature};
  @override
  Duration get leadTime => const Duration(hours: 24);

  @override
  TriggerSignal evaluate(EvaluationContext ctx, ModuleParams params) {
    if (ctx.weather == null || ctx.weather!.samples.isEmpty) {
      return TriggerSignal.zero(
        moduleId: id,
        reason: 'No weather data',
        missing: DataRequirement.weatherTemperature,
      );
    }
    final threshold = params.getDouble('temp_delta_c', 5);
    final swing = ctx.weather!.tempSwingInLast(const Duration(hours: 24));
    if (swing == null) {
      return TriggerSignal.zero(
        moduleId: id,
        reason: 'Insufficient weather samples',
        missing: DataRequirement.weatherTemperature,
      );
    }
    final trend = ctx.weather!.tempTrendInLast(const Duration(hours: 24));
    final direction = trend == null ? '' : trend > 0 ? ', warming' : ', cooling';
    final explanation = 'Temp swing ${swing.round()}°ΔC over 24h$direction';
    if (swing < threshold) {
      return TriggerSignal(moduleId: id, weight: 0, confidence: 1.0, explanation: explanation);
    }
    return TriggerSignal(moduleId: id, weight: params.weightMax, confidence: 1.0, explanation: explanation);
  }
}
