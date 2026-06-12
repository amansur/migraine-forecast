import '../config/rules_config.dart';
import '../engine/trigger_module.dart';
import '../engine/window_direction.dart';
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
    final direction = directionFor(ctx);
    final (start, end) = windowFor(ctx, const Duration(hours: 24));
    final maxPm25 = aq.maxPm25InWindow(start, end);
    if (maxPm25 == null) {
      return TriggerSignal.zero(
        moduleId: id,
        reason: 'No AQ samples in window',
        missing: DataRequirement.weatherAirQuality,
      );
    }
    final valStr = maxPm25.toStringAsFixed(0);
    if (maxPm25 < threshold) {
      final okExplanation = switch (direction) {
        WindowDirection.past => 'Air quality OK (PM2.5 $valStr in last 24h)',
        WindowDirection.future => 'Air quality OK (PM2.5 $valStr over next 24h)',
      };
      return TriggerSignal(
        moduleId: id,
        weight: 0,
        confidence: 1.0,
        explanation: okExplanation,
      );
    }
    final saturation = threshold * 2;
    final t = ((maxPm25 - threshold) / (saturation - threshold)).clamp(0.0, 1.0);
    final explanation = switch (direction) {
      WindowDirection.past => 'PM2.5 peaked at $valStr µg/m³ in last 24h',
      WindowDirection.future => 'PM2.5 forecast to reach $valStr µg/m³ over next 24h',
    };
    return TriggerSignal(
      moduleId: id,
      weight: params.weightMax * t,
      confidence: 1.0,
      explanation: explanation,
    );
  }
}
