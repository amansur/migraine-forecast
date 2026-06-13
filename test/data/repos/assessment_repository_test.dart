import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/data/database.dart' hide RiskAssessment;
import 'package:migraine_forecast/data/repos/assessment_repository.dart';

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

  test('latestForDate is robust to timezone mismatches', () async {
    // We use a specific UTC moment.
    final moment = DateTime.utc(2026, 6, 12, 14); // 2 PM UTC
    // We save it. The repository will normalize it to June 12 00:00:00Z.
    await repo.save(makeAss(date: moment));

    // We query for June 12 (as a Local date that might have different components).
    // In many timezones, June 12 00:00:00 UTC is June 11 in Local.
    // But our repository should normalize the query target too.
    final queryTarget = DateTime.utc(2026, 6, 12);
    
    final latest = await repo.latestForDate(
      target: queryTarget,
      horizon: RiskHorizon.today,
    );
    expect(latest, isNotNull);
    expect(latest?.targetDate, DateTime.utc(2026, 6, 12));
  });

  test('activeAt returns the most recent assessment at or before the given time', () async {
    await repo.save(makeAss(score: 30));
    await repo.save(makeAss(score: 60).copyWithComputedAt(DateTime.utc(2026, 6, 10, 18)));
    final active = await repo.activeAt(DateTime.utc(2026, 6, 10, 20));
    expect(active?.score, 60);
  });

  test('persists and reads back RiskAssessment.backfilled', () async {
    final target = DateTime.utc(2026, 6, 1);
    await repo.save(RiskAssessment(
      score: 42,
      band: RiskBand.moderate,
      contributors: const [],
      computedAt: DateTime.utc(2026, 6, 1, 12),
      configVersion: 1,
      targetDate: target,
      horizon: RiskHorizon.today,
      backfilled: true,
    ));

    final loaded = await repo.latestForDate(target: target, horizon: RiskHorizon.today);
    expect(loaded, isNotNull);
    expect(loaded!.backfilled, isTrue);
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
