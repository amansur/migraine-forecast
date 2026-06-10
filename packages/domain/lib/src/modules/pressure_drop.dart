import '../config/rules_config.dart';
import '../engine/trigger_module.dart';
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
    final lookahead = Duration(hours: params.getInt('lookahead_hours', 48));
    final drop = ctx.weather!.maxPressureDropOver(const Duration(hours: 24));
    if (drop == null || drop <= 0) {
      return TriggerSignal(
        moduleId: id,
        weight: 0,
        confidence: 1.0,
        explanation: 'Pressure stable',
      );
    }
    // Linear ramp from threshold to 2x threshold; saturates at weight_max.
    final saturationHpa = thresholdHpa * 2.0;
    final t = ((drop - thresholdHpa) / (saturationHpa - thresholdHpa)).clamp(0.0, 1.0);
    // Below threshold: half-weight ramp to handle borderline cases.
    final rampedT = drop < thresholdHpa
        ? (drop / thresholdHpa) * 0.5
        : 0.5 + t * 0.5;
    final weight = (params.weightMax * rampedT).clamp(0.0, params.weightMax);
    return TriggerSignal(
      moduleId: id,
      weight: weight,
      confidence: 1.0,
      explanation: 'Pressure dropping ${drop.toStringAsFixed(1)} hPa over next ${lookahead.inHours}h',
    );
  }
}
