import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('RefractoryModule', () {
    final module = RefractoryModule();
    const params = ModuleParams(
      enabled: true,
      weightMax: 6,
      params: {'suppression_hours': 48},
    );
    final now = DateTime.utc(2026, 6, 10, 6);
    final target = DateTime.utc(2026, 6, 10);

    EvaluationContext withAttacks(List<Attack> attacks) => EvaluationContext(
          now: now,
          targetDate: target,
          recentAttacks: attacks,
          baselines: BaselineSnapshot.empty,
        );

    test('no attacks (no history) -> zero confidence, onboarding signal', () {
      final s = module.evaluate(withAttacks(const []), params);
      expect(s.weight, 0);
      expect(s.confidence, 0);
      expect(s.missing, DataRequirement.attackHistory);
    });

    test('attack within suppression window -> weight 0', () {
      // Refractory means risk is LOWER right after an attack. We model that as 0 contribution.
      final s = module.evaluate(
        withAttacks([Attack(startedAt: now.subtract(Duration(hours: 12)), severity: 6)]),
        params,
      );
      expect(s.weight, 0);
      expect(s.explanation, contains('Refractory'));
    });

    test('attack just outside window -> small positive (rebound)', () {
      final s = module.evaluate(
        withAttacks([Attack(startedAt: now.subtract(Duration(hours: 60)), severity: 6)]),
        params,
      );
      expect(s.weight, greaterThan(0));
      expect(s.weight, lessThanOrEqualTo(6));
    });

    test('attack long ago -> no contribution', () {
      final s = module.evaluate(
        withAttacks([Attack(startedAt: now.subtract(Duration(days: 30)), severity: 6)]),
        params,
      );
      expect(s.weight, 0);
    });
  });
}
