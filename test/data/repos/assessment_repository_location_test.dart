import 'package:drift/native.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/data/database.dart' hide RiskAssessment;
import 'package:migraine_forecast/data/repos/assessment_repository.dart';

void main() {
  test('save persists resolved location and reload returns it', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = AssessmentRepository(db);

    await repo.save(RiskAssessment(
      score: 22,
      band: RiskBand.low,
      contributors: const [],
      computedAt: DateTime.utc(2026, 7, 20, 23),
      configVersion: 1,
      targetDate: DateTime.utc(2026, 7, 20),
      horizon: RiskHorizon.today,
      resolvedLat: 37.8044,
      resolvedLon: -122.2712,
      locationName: 'Oakland, California',
    ));

    final row = await db.select(db.riskAssessments).getSingle();
    expect(row.resolvedLat, closeTo(37.8044, 0.0001));
    expect(row.resolvedLon, closeTo(-122.2712, 0.0001));
    expect(row.locationName, 'Oakland, California');
  });
}
