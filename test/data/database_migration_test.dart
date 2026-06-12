import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_weatherr/data/database.dart' hide Attack, JournalEntry, WeatherSnapshot, RiskAssessment;

void main() {
  test('schema v3 adds Attacks.inProgress and RiskAssessments.backfilled with false defaults', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    expect(db.schemaVersion, 3);

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
}
