import '../config/rules_config.dart';
import '../types/evaluation_context.dart';
import '../types/risk_assessment.dart';
import '../types/trigger_signal.dart';
import 'trigger_module.dart';

class RiskEngine {
  final List<TriggerModule> modules;
  final DateTime Function() clock;

  RiskEngine({required this.modules, DateTime Function()? clock})
      : clock = clock ?? DateTime.now;

  RiskAssessment evaluate(
    EvaluationContext ctx,
    RulesConfig config, {
    required RiskHorizon horizon,
  }) {
    final signals = <TriggerSignal>[];
    for (final m in modules) {
      final params = config.modules[m.id];
      if (params == null || !params.enabled) continue;

      TriggerSignal raw;
      try {
        raw = m.evaluate(ctx, params);
      } catch (_) {
        signals.add(TriggerSignal.zero(moduleId: m.id, reason: 'module error'));
        continue;
      }

      // Apply user flags + weight override.
      final flagged = ctx.userFlags.isFlagged(m.id);
      final flagMultiplier = flagged ? 1.0 : config.unflaggedConfidenceMultiplier;
      final override = ctx.userFlags.overrideFor(m.id); // -2..+2
      final weightScale = (1.0 + 0.1 * override).clamp(0.5, 1.5);

      signals.add(
        TriggerSignal(
          moduleId: raw.moduleId,
          weight: raw.weight * weightScale,
          confidence: raw.confidence * flagMultiplier,
          explanation: raw.explanation,
          missing: raw.missing,
        ),
      );
    }

    // Sum contributions, clamp to 0..100.
    final total = signals.fold<double>(0, (acc, s) => acc + s.contribution);
    final score = total.clamp(0.0, 100.0).round();

    // Sort contributors by contribution desc for the UI.
    final sorted = [...signals]
      ..sort((a, b) => b.contribution.compareTo(a.contribution));

    return RiskAssessment(
      score: score,
      band: config.bands.bandFor(score),
      contributors: sorted,
      computedAt: clock(),
      configVersion: config.version,
      targetDate: ctx.targetDate,
      horizon: horizon,
    );
  }
}
