import 'package:domain/domain.dart';

class WeightSuggestion {
  final String moduleId;
  final double recommendedOverride;
  final String rationale;
  final CorrelationResult source;
  const WeightSuggestion({
    required this.moduleId,
    required this.recommendedOverride,
    required this.rationale,
    required this.source,
  });
}

class SuggestionEngine {
  final Duration dismissalCooldown;
  const SuggestionEngine({this.dismissalCooldown = const Duration(days: 14)});

  List<WeightSuggestion> suggestionsFor({
    required List<CorrelationResult> results,
    required Map<String, double> currentOverrides,
    required Map<String, DateTime> dismissedAt,
    required DateTime now,
  }) {
    final out = <WeightSuggestion>[];
    for (final r in results) {
      if (r.classification != CorrelationClassification.personalHit &&
          r.classification != CorrelationClassification.personalMiss) {
        continue;
      }
      final current = currentOverrides[r.moduleId] ?? 0.0;
      final delta =
          r.classification == CorrelationClassification.personalHit ? 1.0 : -1.0;
      final recommended = (current + delta).clamp(-2.0, 2.0).toDouble();
      if (recommended == current) continue;
      final dismissed = dismissedAt[r.moduleId];
      if (dismissed != null && now.difference(dismissed) < dismissalCooldown) {
        continue;
      }

      final rationale =
          r.classification == CorrelationClassification.personalHit
              ? 'Migraines followed ${(r.firedAttackRate.point * 100).round()}% of days when this trigger fired '
                  '(vs ${(r.notFiredAttackRate.point * 100).round()}% baseline).'
              : 'Migraines occurred on ${(r.firedAttackRate.point * 100).round()}% of days when this trigger fired '
                  '(vs ${(r.notFiredAttackRate.point * 100).round()}% baseline) — weaker than baseline.';

      out.add(WeightSuggestion(
        moduleId: r.moduleId,
        recommendedOverride: recommended,
        rationale: rationale,
        source: r,
      ));
    }
    return out;
  }
}
