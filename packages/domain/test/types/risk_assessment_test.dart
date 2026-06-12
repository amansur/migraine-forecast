import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('RiskAssessment', () {
    test('bands map score to band correctly', () {
      const bands = ScoreBands(low: 25, moderate: 50, high: 75);
      expect(bands.bandFor(10), RiskBand.low);
      expect(bands.bandFor(30), RiskBand.moderate);
      expect(bands.bandFor(60), RiskBand.high);
      expect(bands.bandFor(90), RiskBand.veryHigh);
      expect(bands.bandFor(25), RiskBand.moderate); // boundary inclusive on lower
    });

    test('isOnboarding when all contributors have zero confidence', () {
      final ass = RiskAssessment(
        score: 0,
        band: RiskBand.low,
        contributors: [
          TriggerSignal.zero(moduleId: 'x', reason: 'no data'),
          TriggerSignal.zero(moduleId: 'y', reason: 'no data'),
        ],
        computedAt: DateTime.utc(2026, 6, 10),
        configVersion: 1,
        targetDate: DateTime.utc(2026, 6, 10),
        horizon: RiskHorizon.today,
      );
      expect(ass.isOnboarding, isTrue);
    });

    test('backfilled defaults to false', () {
      final ass = RiskAssessment(
        score: 10,
        band: RiskBand.low,
        contributors: const [],
        computedAt: DateTime.utc(2026, 6, 1, 12),
        configVersion: 1,
        targetDate: DateTime.utc(2026, 6, 1),
        horizon: RiskHorizon.today,
      );
      expect(ass.backfilled, isFalse);
    });

    test('backfilled flag is settable and included in equality', () {
      final base = RiskAssessment(
        score: 0,
        band: RiskBand.low,
        contributors: const [],
        computedAt: DateTime.utc(2026, 6, 1, 12),
        configVersion: 1,
        targetDate: DateTime.utc(2026, 6, 1),
        horizon: RiskHorizon.today,
      );
      final backfilled = RiskAssessment(
        score: 0,
        band: RiskBand.low,
        contributors: const [],
        computedAt: DateTime.utc(2026, 6, 1, 12),
        configVersion: 1,
        targetDate: DateTime.utc(2026, 6, 1),
        horizon: RiskHorizon.today,
        backfilled: true,
      );
      expect(backfilled.backfilled, isTrue);
      expect(backfilled, isNot(equals(base)));
    });
  });
}
