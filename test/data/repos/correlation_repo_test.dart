import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/data/database.dart' hide Attack, JournalEntry, WeatherSnapshot, RiskAssessment;
import 'package:migraine_forecast/data/repos/correlation_repo.dart';

void main() {
  late AppDatabase db;
  late CorrelationRepo repo;
  setUp(() {
    db = AppDatabase.memory();
    repo = CorrelationRepo(db);
  });
  tearDown(() => db.close());

  Future<void> insertAssessment({
    required DateTime targetDate,
    required Map<String, double> contributions,
    DateTime? computedAt,
  }) async {
    final contributors = contributions.entries
        .map((e) => {
              'moduleId': e.key,
              'weight': e.value,
              'confidence': 1.0,
              'explanation': '${e.key} test',
            })
        .toList();
    await db.into(db.riskAssessments).insert(
          RiskAssessmentsCompanion.insert(
            targetDate: targetDate,
            horizon: 'today',
            score: contributions.values.fold(0.0, (a, b) => a + b).round(),
            band: 'high',
            computedAt: computedAt ?? targetDate,
            configVersion: 1,
            contributorsJson: jsonEncode(contributors),
          ),
        );
  }

  Future<void> insertAttack(DateTime startedAt) async {
    await db.into(db.attacks).insert(
          AttacksCompanion.insert(
            startedAt: startedAt,
            endedAt: const Value.absent(),
            severity: 5,
            notes: const Value.absent(),
            riskAssessmentId: const Value.absent(),
          ),
        );
  }

  test('cohorts split fired vs not-fired days correctly', () async {
    // 5 days where pressure_drop fired, 3 of which had attacks.
    for (var i = 0; i < 5; i++) {
      final day = DateTime.utc(2026, 6, 1 + i);
      await insertAssessment(targetDate: day, contributions: {'pressure_drop': 10.0});
      // Local noon: attacks bin by local calendar day (matching assessment keys).
      if (i < 3) await insertAttack(DateTime(2026, 6, 1 + i, 12));
    }
    // 10 days where pressure_drop did NOT fire, 1 of which had an attack.
    for (var i = 0; i < 10; i++) {
      final day = DateTime.utc(2026, 6, 6 + i);
      await insertAssessment(targetDate: day, contributions: {'sleep_deficit': 5.0});
      if (i == 0) await insertAttack(DateTime(2026, 6, 6 + i, 12));
    }

    final cohorts = await repo.buildCohorts(
      windowStart: DateTime.utc(2026, 6, 1),
      windowEnd: DateTime.utc(2026, 6, 16),
      moduleIds: const ['pressure_drop', 'sleep_deficit'],
    );

    final pd = cohorts.firstWhere((c) => c.exposureId == 'pressure_drop');
    expect(pd.daysFiredTotal, 5);
    expect(pd.daysFiredWithAttack, 3);
    expect(pd.daysNotFiredTotal, 10);
    expect(pd.daysNotFiredWithAttack, 1);

    final sd = cohorts.firstWhere((c) => c.exposureId == 'sleep_deficit');
    expect(sd.daysFiredTotal, 10);
    expect(sd.daysFiredWithAttack, 1);
  });

  test('returns empty list when no assessments in window', () async {
    final cohorts = await repo.buildCohorts(
      windowStart: DateTime.utc(2026, 6, 1),
      windowEnd: DateTime.utc(2026, 6, 30),
      moduleIds: const ['pressure_drop'],
    );
    final pd = cohorts.firstWhere((c) => c.exposureId == 'pressure_drop');
    expect(pd.totalDays, 0);
  });
}
