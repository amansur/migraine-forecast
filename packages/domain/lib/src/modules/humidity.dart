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
    final window = const Duration(hours: 24);
    final direction = directionFor(ctx);
    final (start, end) = switch (direction) {
      WindowDirection.past => (ctx.now.subtract(window), ctx.now),
      WindowDirection.future => (ctx.now, ctx.targetDate.add(window)),
    };
    final maxHumidity = ctx.weather!.maxHumidityInWindow(start, end);
    if (maxHumidity == null) {
      return TriggerSignal.zero(
        moduleId: id,
        reason: 'Insufficient weather samples',
        missing: DataRequirement.weatherHumidity,
      );
    }
    final trend = ctx.weather!.humidityTrendInWindow(start, end);
    final delta = trend == null
        ? ''
        : trend >= 0
            ? ' +${trend.round()}%'
            : ' ${trend.round()}%';
    final risingFalling = trend == null ? '' : trend > 0 ? 'rising' : 'falling';
    final maxStr = maxHumidity.toStringAsFixed(0);
    final explanation = switch (direction) {
      WindowDirection.past => trend == null
          ? 'Humidity $maxStr% in last 24h'
          : trend >= 0
              ? 'Humidity $maxStr%, rose$delta in last 24h'
              : 'Humidity $maxStr%, fell$delta in last 24h',
      WindowDirection.future => trend == null
          ? 'Humidity reaching $maxStr% over next 24h'
          : 'Humidity reaching $maxStr%, $risingFalling$delta over next 24h',
    };
    if (maxHumidity <= threshold) {
      return TriggerSignal(moduleId: id, weight: 0, confidence: 1.0, explanation: explanation);
    }
    return TriggerSignal(moduleId: id, weight: params.weightMax, confidence: 1.0, explanation: explanation);
  }
}
