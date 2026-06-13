import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_weatherr/data/database.dart' hide Attack, JournalEntry, WeatherSnapshot, RiskAssessment, PeriodDaySeverity;

void main() {
  test('schema v4 adds Attacks.inProgress and RiskAssessments.backfilled with false defaults', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    expect(db.schemaVersion, 4);

    final attackId = await db.into(db.attacks).insert(
          AttacksCompanion.insert(
            startedAt: DateTime.utc(2026, 6, 1, 12),
            severity: 5,
          ),
        );
    final attack = await (db.select(db.attacks)..where((t) => t.id.equals(attackId))).getSingle();
    expect(attack.inProgress, isFalse);

    final assId = await db.into(db.riskAssessments).insert(
          RiskAssessmentsCompanion.insert(
            targetDate: DateTime.utc(2026, 6, 1),
            horizon: 'today',
            score: 0,
            band: 'low',
            computedAt: DateTime.utc(2026, 6, 1, 12),
            configVersion: 1,
            contributorsJson: '[]',
          ),
        );
    final ass = await (db.select(db.riskAssessments)..where((t) => t.id.equals(assId))).getSingle();
    expect(ass.backfilled, isFalse);
  });

  test('Attacks.inProgress is writable', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    final id = await db.into(db.attacks).insert(
          AttacksCompanion.insert(
            startedAt: DateTime.utc(2026, 6, 1, 12),
            severity: 5,
            inProgress: const Value(true),
          ),
        );
    final row = await (db.select(db.attacks)..where((t) => t.id.equals(id))).getSingle();
    expect(row.inProgress, isTrue);
  });

  test('schema v4 creates Periods and PeriodDaySeverities tables', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    final pid = await db.into(db.periods).insert(
          PeriodsCompanion.insert(
            startedAt: DateTime.utc(2026, 6, 10),
            baselineSeverity: 5,
          ),
        );
    expect(pid, isPositive);

    await db.into(db.periodDaySeverities).insert(
          PeriodDaySeveritiesCompanion.insert(
            day: DateTime.utc(2026, 6, 11),
            severity: 7,
          ),
        );
    final overrides = await db.select(db.periodDaySeverities).get();
    expect(overrides, hasLength(1));
    expect(overrides.first.severity, 7);
  });
}
