import '../config/rules_config.dart';
import '../engine/trigger_module.dart';
import '../types/data_requirement.dart';
import '../types/evaluation_context.dart';
import '../types/trigger_signal.dart';

class AirQualityModule implements TriggerModule {
  @override
  String get id => 'air_quality';
  @override
  Set<DataRequirement> get requires => {DataRequirement.weatherAirQuality};
  @override
  Duration get leadTime => const Duration(hours: 24);

  @override
  TriggerSignal evaluate(EvaluationContext ctx, ModuleParams params) {
    final aq = ctx.airQuality;
    if (aq == null || aq.samples.isEmpty) {
      return TriggerSignal.zero(
        moduleId: id,
        reason: 'No air quality data',
        missing: DataRequirement.weatherAirQuality,
      );
    }
    final threshold = params.getDouble('pm25_threshold', 35);
    final maxPm25 = aq.maxPm25From(ctx.now, const Duration(hours: 24));
    if (maxPm25 == null) {
      return TriggerSignal.zero(
        moduleId: id,
        reason: 'No upcoming AQ samples',
        missing: DataRequirement.weatherAirQuality,
      );
    }
    if (maxPm25 < threshold) {
      return TriggerSignal(
        moduleId: id,
        weight: 0,
        confidence: 1.0,
        explanation: 'Air quality OK (PM2.5 ${maxPm25.toStringAsFixed(0)})',
      );
    }
    final saturation = threshold * 2;
    final t = ((maxPm25 - threshold) / (saturation - threshold)).clamp(0.0, 1.0);
    return TriggerSignal(
      moduleId: id,
      weight: params.weightMax * t,
      confidence: 1.0,
      explanation: 'High PM2.5 (${maxPm25.toStringAsFixed(0)} µg/m³)',
    );
  }
}
