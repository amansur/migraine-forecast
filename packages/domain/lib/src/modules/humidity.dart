import '../config/rules_config.dart';
import '../engine/trigger_module.dart';
import '../engine/window_direction.dart';
import '../types/data_requirement.dart';
import '../types/evaluation_context.dart';
import '../types/trigger_signal.dart';

class HumidityModule implements TriggerModule {
  @override
  String get id => 'humidity';
  @override
  Set<DataRequirement> get requires => {DataRequirement.weatherHumidity};
  @override
  Duration get leadTime => const Duration(hours: 24);

  @override
  TriggerSignal evaluate(EvaluationContext ctx, ModuleParams params) {
    if (ctx.weather == null || ctx.weather!.samples.isEmpty) {
      return TriggerSignal.zero(
        moduleId: id,
        reason: 'No weather data',
        missing: DataRequirement.weatherHumidity,
      );
    }
    final threshold = params.getDouble('humidity_pct', 60);
    final direction = directionFor(ctx);
    final (start, end) = windowFor(ctx, const Duration(hours: 24));
    final maxHumidity = ctx.weather!.maxHumidityInWindow(start, end);
    if (maxHumidity == null) {
      return TriggerSignal.zero(
        moduleId: id,
        reason: 'Insufficient weather samples',
        missing: DataRequirement.weatherHumidity,
      );
    }
    final trend = ctx.weather!.humidityTrendInWindow(start, end);
    // Magnitude only; the verb (rose/fell/rising/falling) carries the sign.
    final magnitude = trend == null ? null : trend.abs().round();
    final maxStr = maxHumidity.toStringAsFixed(0);
    final explanation = switch (direction) {
      WindowDirection.past => trend == null
          ? 'Humidity $maxStr% in last 24h'
          : trend >= 0
              ? 'Humidity $maxStr%, rose $magnitude% in last 24h'
              : 'Humidity $maxStr%, fell $magnitude% in last 24h',
      WindowDirection.future => trend == null
          ? 'Humidity reaching $maxStr% over next 24h'
          : trend >= 0
              ? 'Humidity reaching $maxStr%, rising $magnitude% over next 24h'
              : 'Humidity reaching $maxStr%, falling $magnitude% over next 24h',
    };
    if (maxHumidity <= threshold) {
      return TriggerSignal(moduleId: id, weight: 0, confidence: 1.0, explanation: explanation);
    }
    return TriggerSignal(moduleId: id, weight: params.weightMax, confidence: 1.0, explanation: explanation);
  }
}
