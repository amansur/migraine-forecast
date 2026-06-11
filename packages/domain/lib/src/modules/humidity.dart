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
    final maxHumidity = ctx.weather!.maxHumidityFrom(
      ctx.now.subtract(const Duration(hours: 24)),
      const Duration(hours: 48),
    );
    if (maxHumidity == null) {
      return TriggerSignal.zero(
        moduleId: id,
        reason: 'Insufficient weather samples',
        missing: DataRequirement.weatherHumidity,
      );
    }
    final trend = ctx.weather!.humidityTrendInLast(const Duration(hours: 24));
    final delta = trend == null
        ? ''
        : trend >= 0
            ? ' (+${trend.round()}%)'
            : ' (${trend.round()}%)';
    final direction = trend == null ? '' : trend > 0 ? ', rising' : ', falling';
    final explanation = 'Humidity ${maxHumidity.toStringAsFixed(0)}%$delta$direction';
    if (maxHumidity <= threshold) {
      return TriggerSignal(moduleId: id, weight: 0, confidence: 1.0, explanation: explanation);
    }
    return TriggerSignal(moduleId: id, weight: params.weightMax, confidence: 1.0, explanation: explanation);
  }
}
