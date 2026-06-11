import '../config/rules_config.dart';
import '../engine/trigger_module.dart';
import '../types/data_requirement.dart';
import '../types/evaluation_context.dart';
import '../types/trigger_signal.dart';

class HumidityTempSwingModule implements TriggerModule {
  @override
  String get id => 'humidity_temp_swing';
  @override
  Set<DataRequirement> get requires =>
      {DataRequirement.weatherHumidity};
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
    final humidityPct = params.getDouble('humidity_pct', 60);
    final tempDeltaC = params.getDouble('temp_delta_c', 5);
    final maxHumidity = ctx.weather!.maxHumidityFrom(
      ctx.now.subtract(const Duration(hours: 24)),
      const Duration(hours: 48),
    );
    final swing = ctx.weather!.tempSwingInLast(const Duration(hours: 24));
    if (maxHumidity == null || swing == null) {
      return TriggerSignal.zero(
        moduleId: id,
        reason: 'Insufficient weather samples',
        missing: DataRequirement.weatherHumidity,
      );
    }
    final trend = ctx.weather!.tempTrendInLast(const Duration(hours: 24));
    final direction = trend == null ? '' : trend > 0 ? ', warming' : ', cooling';
    final humidOk = maxHumidity > humidityPct;
    final swingOk = swing >= tempDeltaC;
    if (!humidOk || !swingOk) {
      return TriggerSignal(
        moduleId: id,
        weight: 0,
        confidence: 1.0,
        explanation: 'Humidity ${maxHumidity.toStringAsFixed(0)}%, 24h swing ${swing.toStringAsFixed(1)}°ΔC$direction',
      );
    }
    return TriggerSignal(
      moduleId: id,
      weight: params.weightMax,
      confidence: 1.0,
      explanation:
          'Humid (${maxHumidity.toStringAsFixed(0)}%), 24h swing ${swing.toStringAsFixed(1)}°ΔC$direction',
    );
  }
}
