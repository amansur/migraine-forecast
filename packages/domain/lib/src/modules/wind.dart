import '../config/rules_config.dart';
import '../engine/trigger_module.dart';
import '../types/data_requirement.dart';
import '../types/evaluation_context.dart';
import '../types/trigger_signal.dart';

/// Chinook/foehn-type wind events raise migraine probability in susceptible
/// patients (Cooke, Rose & Becker 2000, Neurology 54:302 — high-wind chinook
/// days). Fires on peak gusts in the day's window; threshold/saturation are
/// config params.
class WindModule implements TriggerModule {
  @override
  String get id => 'wind';
  @override
  Set<DataRequirement> get requires => {DataRequirement.weatherWind};
  @override
  Duration get leadTime => const Duration(hours: 24);

  @override
  TriggerSignal evaluate(EvaluationContext ctx, ModuleParams params) {
    if (ctx.weather == null || ctx.weather!.samples.isEmpty) {
      return TriggerSignal.zero(
          moduleId: id,
          reason: 'No weather data',
          missing: DataRequirement.weatherWind);
    }
    final threshold = params.getDouble('gust_threshold_kmh', 45);
    final saturation = params.getDouble('gust_saturation_kmh', 75);
    final window = Duration(hours: params.getInt('lookahead_hours', 24));
    final direction = directionFor(ctx);
    final anchor = direction == WindowDirection.past ? ctx.now : ctx.targetDate;
    final gust = ctx.weather!.maxWindGustAround(anchor, window, now: ctx.now);
    if (gust == null) {
      // Cached series predating the wind columns — treat as missing, not calm.
      return TriggerSignal.zero(
          moduleId: id,
          reason: 'No wind data',
          missing: DataRequirement.weatherWind);
    }
    if (gust < threshold) {
      return TriggerSignal(
          moduleId: id,
          weight: 0,
          confidence: 1.0,
          explanation: 'Winds calm (gusts ${gust.round()} km/h)');
    }
    final t = ((gust - threshold) / (saturation - threshold)).clamp(0.0, 1.0);
    final verb = direction == WindowDirection.past ? 'gusting' : 'forecast to gust';
    return TriggerSignal(
        moduleId: id,
        weight: params.weightMax * t,
        confidence: 1.0,
        explanation: 'Wind $verb ${gust.round()} km/h');
  }
}
