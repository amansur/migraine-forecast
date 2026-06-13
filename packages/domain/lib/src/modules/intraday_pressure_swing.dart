import '../config/rules_config.dart';
import '../engine/trigger_module.dart';
import '../types/data_requirement.dart';
import '../types/evaluation_context.dart';
import '../types/trigger_signal.dart';

class IntradayPressureSwingModule implements TriggerModule {
  @override
  String get id => 'intraday_pressure_swing';

  @override
  Set<DataRequirement> get requires => {DataRequirement.weatherPressure};

  @override
  Duration get leadTime => const Duration(hours: 48);

  @override
  TriggerSignal evaluate(EvaluationContext ctx, ModuleParams params) {
    if (ctx.weather == null) {
      return TriggerSignal.zero(
        moduleId: id,
        reason: 'No weather data',
        missing: DataRequirement.weatherPressure,
      );
    }
    final threshold = params.getDouble('threshold_volatility_hpa', 10.0);
    final lookbackHours = params.getInt('lookback_hours', 24);
    final direction = directionFor(ctx);
    final anchor = direction == WindowDirection.past ? ctx.now : ctx.targetDate;
    final volatility = ctx.weather!.hourlyPressureVolatilityAround(
      anchor,
      Duration(hours: lookbackHours),
      now: ctx.now,
    );
    if (volatility == null) {
      return TriggerSignal.zero(
        moduleId: id,
        reason: 'Insufficient weather samples',
        missing: DataRequirement.weatherPressure,
      );
    }
    final swingStr = volatility.toStringAsFixed(1);
    final explanation = switch (direction) {
      WindowDirection.past =>
        'Pressure swung $swingStr hPa (accumulated) in last ${lookbackHours}h',
      WindowDirection.future =>
        'Pressure may swing $swingStr hPa (accumulated) over next ${lookbackHours}h',
    };
    final saturation = threshold * 2.0;
    final t = ((volatility - threshold) / (saturation - threshold)).clamp(0.0, 1.0);
    final weight = (params.weightMax * t).clamp(0.0, params.weightMax);
    return TriggerSignal(
      moduleId: id,
      weight: weight,
      confidence: 1.0,
      explanation: explanation,
    );
  }
}
