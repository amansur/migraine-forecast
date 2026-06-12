import '../config/rules_config.dart';
import '../engine/trigger_module.dart';
import '../engine/window_direction.dart';
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
    final window = const Duration(hours: 24);
    final direction = directionFor(ctx);
    final (start, end) = switch (direction) {
      WindowDirection.past => (ctx.now.subtract(window), ctx.now),
      WindowDirection.future => (ctx.now, ctx.targetDate.add(window)),
    };
    final swing = ctx.weather!.tempSwingInWindow(start, end);
    if (swing == null) {
      return TriggerSignal.zero(
        moduleId: id,
        reason: 'Insufficient weather samples',
        missing: DataRequirement.weatherTemperature,
      );
    }
    final trend = ctx.weather!.tempTrendInWindow(start, end);
    final dirWord = trend == null ? '' : trend > 0 ? ', warming' : ', cooling';
    final swingStr = swing.round();
    final explanation = switch (direction) {
      WindowDirection.past => 'Temp swung $swingStr°ΔC in last 24h$dirWord',
      WindowDirection.future => 'Temp swing $swingStr°ΔC expected over next 24h$dirWord',
    };
    if (swing < threshold) {
      return TriggerSignal(moduleId: id, weight: 0, confidence: 1.0, explanation: explanation);
    }
    return TriggerSignal(moduleId: id, weight: params.weightMax, confidence: 1.0, explanation: explanation);
  }
}
