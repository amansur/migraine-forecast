import '../config/rules_config.dart';
import '../engine/trigger_module.dart';
import '../engine/window_direction.dart';
import '../types/data_requirement.dart';
import '../types/evaluation_context.dart';
import '../types/trigger_signal.dart';

class PressureDropModule implements TriggerModule {
  @override
  String get id => 'pressure_drop';

  @override
  Set<DataRequirement> get requires => {DataRequirement.weatherPressure};

  @override
  Duration get leadTime => const Duration(hours: 48);

  @override
  TriggerSignal evaluate(EvaluationContext ctx, ModuleParams params) {
    if (ctx.weather == null || ctx.weather!.samples.length < 2) {
      return TriggerSignal.zero(
        moduleId: id,
        reason: 'No weather data',
        missing: DataRequirement.weatherPressure,
      );
    }
    final thresholdHpa = params.getDouble('threshold_hpa', 5);
    final lookaheadHours = params.getInt('lookahead_hours', 24);
    final direction = directionFor(ctx);
    final (start, end) = windowFor(ctx, Duration(hours: lookaheadHours));
    final drop = ctx.weather!.maxPressureDropInWindow(start, end);
    if (drop == null) {
      return TriggerSignal.zero(
        moduleId: id,
        reason: 'Insufficient weather samples',
        missing: DataRequirement.weatherPressure,
      );
    }
    if (drop <= 0) {
      return TriggerSignal(
        moduleId: id,
        weight: 0,
        confidence: 1.0,
        explanation: 'Pressure stable',
      );
    }
    final saturationHpa = thresholdHpa * 2.0;
    final t = ((drop - thresholdHpa) / (saturationHpa - thresholdHpa)).clamp(0.0, 1.0);
    final rampedT = drop < thresholdHpa
        ? (drop / thresholdHpa) * 0.5
        : 0.5 + t * 0.5;
    final weight = (params.weightMax * rampedT).clamp(0.0, params.weightMax);
    final dropStr = drop.toStringAsFixed(1);
    final explanation = switch (direction) {
      WindowDirection.past => 'Pressure dropped $dropStr hPa in last ${lookaheadHours}h',
      WindowDirection.future => 'Pressure dropping $dropStr hPa over next ${lookaheadHours}h',
    };
    return TriggerSignal(
      moduleId: id,
      weight: weight,
      confidence: 1.0,
      explanation: explanation,
    );
  }
}
