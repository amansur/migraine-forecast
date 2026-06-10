import '../config/rules_config.dart';
import '../types/data_requirement.dart';
import '../types/evaluation_context.dart';
import '../types/trigger_signal.dart';

abstract class TriggerModule {
  String get id;
  Set<DataRequirement> get requires;
  Duration get leadTime;

  /// Evaluate this trigger against the given context using the module's params.
  /// Must not throw — return a zero-confidence signal on missing data.
  TriggerSignal evaluate(EvaluationContext ctx, ModuleParams params);
}
