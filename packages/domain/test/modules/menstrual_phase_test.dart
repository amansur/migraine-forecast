import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('MenstrualPhaseModule', () {
    final module = MenstrualPhaseModule();
    const params = ModuleParams(
      enabled: true,
      weightMax: 20,
      params: {'window_days': [-2, 3]},
    );
    final target = DateTime.utc(2026, 6, 10);

    EvaluationContext withCycles(List<MenstrualEvent> history) => EvaluationContext(
          now: target,
          targetDate: target,
          health: HealthMetrics(source: DataSource.manual, menstrualHistory: history),
          baselines: BaselineSnapshot.empty,
        );

    test('no history -> zero confidence', () {
      final s = module.evaluate(
        EvaluationContext(now: target, targetDate: target, baselines: BaselineSnapshot.empty),
        params,
      );
      expect(s.confidence, 0);
    });

    test('inside perimenstrual window -> full weight', () {
      // Cycle onset two days from target -> day -2
      final history = [
        MenstrualEvent(onsetDate: target.add(const Duration(days: 2))),
        MenstrualEvent(onsetDate: target.subtract(const Duration(days: 26))),
        MenstrualEvent(onsetDate: target.subtract(const Duration(days: 54))),
      ];
      final s = module.evaluate(withCycles(history), params);
      expect(s.weight, 20);
    });

    test('outside window -> no weight', () {
      final history = [
        MenstrualEvent(onsetDate: target.add(const Duration(days: 14))),
        MenstrualEvent(onsetDate: target.subtract(const Duration(days: 14))),
      ];
      final s = module.evaluate(withCycles(history), params);
      expect(s.weight, 0);
    });

    test('irregular cycles reduce confidence', () {
      final history = [
        MenstrualEvent(onsetDate: target.subtract(const Duration(days: 2))),
        MenstrualEvent(onsetDate: target.subtract(const Duration(days: 26))),
        MenstrualEvent(onsetDate: target.subtract(const Duration(days: 60))), // long gap
        MenstrualEvent(onsetDate: target.subtract(const Duration(days: 85))),
        MenstrualEvent(onsetDate: target.subtract(const Duration(days: 115))),
        MenstrualEvent(onsetDate: target.subtract(const Duration(days: 140))),
        MenstrualEvent(onsetDate: target.subtract(const Duration(days: 200))),
      ];
      final s = module.evaluate(withCycles(history), params);
      expect(s.confidence, lessThan(1.0));
    });
  });
}
