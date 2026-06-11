import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_weatherr/data/database.dart' hide Attack, JournalEntry, WeatherSnapshot, RiskAssessment;
import 'package:migraine_weatherr/data/repos/assessment_repository.dart';
import 'package:migraine_weatherr/state/last_refresh_provider.dart';
import 'package:migraine_weatherr/state/providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('returns null when no assessments saved', () async {
    final db = AppDatabase.memory();
    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
    ]);
    addTearDown(container.dispose);
    addTearDown(db.close);
    final last = await container.read(lastRefreshAtProvider.future);
    expect(last, isNull);
  });

  test('returns the latest computedAt across all assessments', () async {
    final db = AppDatabase.memory();
    final repo = AssessmentRepository(db);
    final t1 = DateTime.utc(2026, 6, 10, 6);
    final t2 = DateTime.utc(2026, 6, 11, 6);
    await repo.save(RiskAssessment(
      score: 30,
      band: RiskBand.moderate,
      contributors: const [],
      computedAt: t1,
      configVersion: 1,
      targetDate: DateTime.utc(2026, 6, 10),
      horizon: RiskHorizon.today,
    ));
    await repo.save(RiskAssessment(
      score: 60,
      band: RiskBand.high,
      contributors: const [],
      computedAt: t2,
      configVersion: 1,
      targetDate: DateTime.utc(2026, 6, 11),
      horizon: RiskHorizon.today,
    ));

    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
    ]);
    addTearDown(container.dispose);
    addTearDown(db.close);
    final last = await container.read(lastRefreshAtProvider.future);
    expect(last, t2);
  });
}
