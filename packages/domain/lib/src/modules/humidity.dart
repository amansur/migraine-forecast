import '../config/rules_config.dart';
import '../engine/trigger_module.dart';
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
    final anchor = direction == WindowDirection.past ? ctx.now : ctx.targetDate;
    const window = Duration(hours: 24);
    final maxHumidity = ctx.weather!.maxHumidityAround(anchor, window, now: ctx.now);
    if (maxHumidity == null) {
      return TriggerSignal.zero(
        moduleId: id,
        reason: 'Insufficient weather samples',
        missing: DataRequirement.weatherHumidity,
      );
    }
    final trend = ctx.weather!.humidityTrendAround(anchor, window, now: ctx.now);
    final maxStr = maxHumidity.toStringAsFixed(0);
    final rounded = trend?.round();
    final delta = rounded == null ? null : (rounded >= 0 ? '+$rounded%' : '$rounded%');
    final explanation = switch (direction) {
      WindowDirection.past => switch (rounded) {
        null => 'Humidity $maxStr% in last 24h',
        0 => 'Humidity stayed flat at $maxStr% in last 24h',
        > 0 => 'Humidity $maxStr%, rose $delta in last 24h',
        _ => 'Humidity $maxStr%, fell $delta in last 24h',
      },
      WindowDirection.future => switch (rounded) {
        null => 'Humidity reaching $maxStr% over next 24h',
        0 => 'Humidity staying flat at $maxStr% over next 24h',
        > 0 => 'Humidity reaching $maxStr%, rising $delta over next 24h',
        _ => 'Humidity reaching $maxStr%, falling $delta over next 24h',
      },
    };
    if (maxHumidity <= threshold) {
      return TriggerSignal(moduleId: id, weight: 0, confidence: 1.0, explanation: explanation);
    }
    return TriggerSignal(moduleId: id, weight: params.weightMax, confidence: 1.0, explanation: explanation);
  }
}
