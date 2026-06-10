import 'package:domain/domain.dart';
import 'package:test/test.dart';

/// Helper module: returns a fixed signal regardless of context.
class _FixedModule implements TriggerModule {
  @override
  final String id;
  final TriggerSignal signal;
  _FixedModule(this.id, this.signal);
  @override
  Set<DataRequirement> get requires => const {};
  @override
  Duration get leadTime => const Duration(hours: 24);
  @override
  TriggerSignal evaluate(EvaluationContext ctx, ModuleParams params) => signal;
}

class _ThrowingModule implements TriggerModule {
  @override
  final String id = 'oops';
  @override
  Set<DataRequirement> get requires => const {};
  @override
  Duration get leadTime => const Duration(hours: 24);
  @override
  TriggerSignal evaluate(EvaluationContext ctx, ModuleParams params) {
    throw StateError('boom');
  }
}

EvaluationContext _ctx({UserTriggerFlags flags = const UserTriggerFlags()}) =>
    EvaluationContext(
      now: DateTime.utc(2026, 6, 10, 6),
      targetDate: DateTime.utc(2026, 6, 10),
      userFlags: flags,
      baselines: BaselineSnapshot.empty,
    );

RulesConfig _cfg(Map<String, ModuleParams> modules) => RulesConfig(
      version: 1,
      modules: modules,
      bands: const ScoreBands(low: 25, moderate: 50, high: 75),
      unflaggedConfidenceMultiplier: 0.6,
    );

void main() {
  group('RiskEngine', () {
    test('sums contributions and clamps score to 0..100', () {
      final modules = [
        _FixedModule('a', TriggerSignal(moduleId: 'a', weight: 40, confidence: 1.0, explanation: 'a')),
        _FixedModule('b', TriggerSignal(moduleId: 'b', weight: 80, confidence: 1.0, explanation: 'b')),
      ];
      final cfg = _cfg({
        'a': const ModuleParams(enabled: true, weightMax: 40),
        'b': const ModuleParams(enabled: true, weightMax: 80),
      });
      final engine = RiskEngine(modules: modules);
      final ass = engine.evaluate(
        _ctx(flags: const UserTriggerFlags(flaggedModuleIds: {'a', 'b'})),
        cfg,
        horizon: RiskHorizon.today,
      );
      expect(ass.score, 100); // 40 + 80 = 120, clamped
      expect(ass.band, RiskBand.veryHigh);
      expect(ass.contributors.first.moduleId, 'b'); // sorted by contribution
    });

    test('disabled modules contribute nothing', () {
      final modules = [
        _FixedModule('a', TriggerSignal(moduleId: 'a', weight: 30, confidence: 1.0, explanation: 'a')),
      ];
      final cfg = _cfg({
        'a': const ModuleParams(enabled: false, weightMax: 30),
      });
      final engine = RiskEngine(modules: modules);
      final ass = engine.evaluate(_ctx(), cfg, horizon: RiskHorizon.today);
      expect(ass.score, 0);
    });

    test('unflagged trigger gets confidence multiplier', () {
      final modules = [
        _FixedModule('a', TriggerSignal(moduleId: 'a', weight: 50, confidence: 1.0, explanation: 'a')),
      ];
      final cfg = _cfg({
        'a': const ModuleParams(enabled: true, weightMax: 50),
      });
      final engine = RiskEngine(modules: modules);
      // No flags: confidence multiplied by 0.6 -> contribution 30
      final ass = engine.evaluate(_ctx(), cfg, horizon: RiskHorizon.today);
      expect(ass.score, 30);
      // Flagged: full 50
      final ass2 = engine.evaluate(
        _ctx(flags: const UserTriggerFlags(flaggedModuleIds: {'a'})),
        cfg,
        horizon: RiskHorizon.today,
      );
      expect(ass2.score, 50);
    });

    test('weight override adjusts contribution (+1 -> +10%)', () {
      // Override semantics: each +1 adds 10% of weight_max, clamped to weight_max bounds.
      final modules = [
        _FixedModule('a', TriggerSignal(moduleId: 'a', weight: 20, confidence: 1.0, explanation: 'a')),
      ];
      final cfg = _cfg({
        'a': const ModuleParams(enabled: true, weightMax: 20),
      });
      final engine = RiskEngine(modules: modules);
      final flags = const UserTriggerFlags(
        flaggedModuleIds: {'a'},
        weightOverrides: {'a': 2.0},
      );
      // Module reports weight 20; override scales by (1 + 0.1 * 2) = 1.2 -> 24.
      final ass = engine.evaluate(_ctx(flags: flags), cfg, horizon: RiskHorizon.today);
      expect(ass.score, 24);
    });

    test('isolated module failures do not break refresh', () {
      final modules = [
        _ThrowingModule(),
        _FixedModule('b', TriggerSignal(moduleId: 'b', weight: 30, confidence: 1.0, explanation: 'b')),
      ];
      final cfg = _cfg({
        'oops': const ModuleParams(enabled: true, weightMax: 10),
        'b': const ModuleParams(enabled: true, weightMax: 30),
      });
      final engine = RiskEngine(modules: modules);
      final ass = engine.evaluate(_ctx(flags: const UserTriggerFlags(flaggedModuleIds: {'oops', 'b'})), cfg, horizon: RiskHorizon.today);
      // 'oops' contributes zero (caught); 'b' contributes 30.
      expect(ass.score, 30);
      // The failed module is recorded as a zero-confidence contributor.
      expect(ass.contributors.any((c) => c.moduleId == 'oops' && c.confidence == 0), isTrue);
    });

    test('all-zero confidence flags the assessment as onboarding', () {
      final modules = [
        _FixedModule('a', TriggerSignal.zero(moduleId: 'a', reason: 'no data')),
        _FixedModule('b', TriggerSignal.zero(moduleId: 'b', reason: 'no data')),
      ];
      final cfg = _cfg({
        'a': const ModuleParams(enabled: true, weightMax: 10),
        'b': const ModuleParams(enabled: true, weightMax: 10),
      });
      final engine = RiskEngine(modules: modules);
      final ass = engine.evaluate(_ctx(), cfg, horizon: RiskHorizon.today);
      expect(ass.isOnboarding, isTrue);
      expect(ass.score, 0);
    });
  });
}
