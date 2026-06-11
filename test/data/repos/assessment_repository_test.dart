import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_weatherr/data/database.dart' hide RiskAssessment;
import 'package:migraine_weatherr/data/repos/assessment_repository.dart';

void main() {
  late AppDatabase db;
  late AssessmentRepository repo;
  setUp(() {
    db = AppDatabase.memory();
    repo = AssessmentRepository(db);
  });
  tearDown(() => db.close());

  RiskAssessment makeAss({int score = 50, RiskBand band = RiskBand.high, DateTime? date}) => RiskAssessment(
        score: score,
        band: band,
        contributors: [
          TriggerSignal(
            moduleId: 'pressure_drop',
            weight: 18,
            confidence: 1.0,
            explanation: 'Pressure dropping 12 hPa',
          ),
        ],
        computedAt: DateTime.utc(2026, 6, 10, 6),
        configVersion: 1,
        targetDate: date ?? DateTime.utc(2026, 6, 10),
        horizon: RiskHorizon.today,
      );

  test('save then look up by date+horizon', () async {
    final id = await repo.save(makeAss());
    expect(id, isPositive);
    final latest = await repo.latestForDate(
      target: DateTime.utc(2026, 6, 10),
      horizon: RiskHorizon.today,
    );
    expect(latest?.score, 50);
    expect(latest?.contributors.first.moduleId, 'pressure_drop');
  });

  test('activeAt returns the most recent assessment at or before the given time', () async {
    await repo.save(makeAss(score: 30));
    await repo.save(makeAss(score: 60).copyWithComputedAt(DateTime.utc(2026, 6, 10, 18)));
    final active = await repo.activeAt(DateTime.utc(2026, 6, 10, 20));
    expect(active?.score, 60);
  });
}

extension on RiskAssessment {
  RiskAssessment copyWithComputedAt(DateTime t) => RiskAssessment(
        score: score,
        band: band,
        contributors: contributors,
        computedAt: t,
        configVersion: configVersion,
        targetDate: targetDate,
        horizon: horizon,
      );
}
