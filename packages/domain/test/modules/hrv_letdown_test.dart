import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('HrvLetdownModule', () {
    final module = HrvLetdownModule();
    const params = ModuleParams(
      enabled: true,
      weightMax: 12,
      params: {'drop_pct': 20, 'baseline_days': 14},
    );
    final now = DateTime.utc(2026, 6, 10, 6);
    final target = DateTime.utc(2026, 6, 10);

    EvaluationContext withHrv(List<HrvSample> recent, {double? baseline}) => EvaluationContext(
          now: now,
          targetDate: target,
          health: HealthMetrics(recentHrv: recent),
          baselines: BaselineSnapshot(hrvRmssdBaseline14d: baseline),
        );

    test('no HRV -> zero confidence', () {
      final s = module.evaluate(
        EvaluationContext(now: now, targetDate: target, baselines: BaselineSnapshot.empty),
        params,
      );
      expect(s.confidence, 0);
    });

    test('no baseline yet -> cold start confidence', () {
      final s = module.evaluate(
        withHrv([HrvSample(at: now, rmssdMs: 40)]),
        params,
      );
      expect(s.confidence, 0.5);
    });

    test('drop ≥ threshold triggers weight', () {
      final s = module.evaluate(
        withHrv([HrvSample(at: now, rmssdMs: 35)], baseline: 50),
        params,
      );
      // 30% drop, threshold 20%, saturate at 40%. t=(30-20)/(40-20)=0.5 -> weight=6
      expect(s.weight, closeTo(6.0, 0.1));
    });

    test('no signal when recent ≥ baseline', () {
      final s = module.evaluate(
        withHrv([HrvSample(at: now, rmssdMs: 55)], baseline: 50),
        params,
      );
      expect(s.weight, 0);
    });
  });
}
