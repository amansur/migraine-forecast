import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_weatherr/data/database.dart' hide Attack, JournalEntry;
import 'package:migraine_weatherr/data/sources/drift_journal_source.dart';

void main() {
  late AppDatabase db;
  late DriftJournalSource source;

  setUp(() {
    db = AppDatabase.memory();
    source = DriftJournalSource(db);
  });
  tearDown(() => db.close());

  test('round-trips a journal entry', () async {
    final entry = JournalEntry(
      at: DateTime.utc(2026, 6, 10, 8),
      kind: JournalKind.alcohol,
      payload: {'units': 2.0},
    );
    await source.addEntry(entry);
    final recent = await source.recentEntries(const Duration(days: 1), now: DateTime.utc(2026, 6, 10, 12));
    expect(recent, hasLength(1));
    expect(recent.first.kind, JournalKind.alcohol);
    expect(recent.first.payload['units'], 2.0);
  });

  test('recentEntries respects the window', () async {
    await source.addEntry(JournalEntry(
      at: DateTime.utc(2026, 6, 8, 8),
      kind: JournalKind.caffeine,
      payload: {'mg': 100},
    ));
    final recent = await source.recentEntries(const Duration(hours: 24), now: DateTime.utc(2026, 6, 10, 12));
    expect(recent, isEmpty);
  });

  test('addAttack stores with risk assessment id', () async {
    final id = await source.addAttack(
      Attack(startedAt: DateTime.utc(2026, 6, 10, 9), severity: 7),
      riskAssessmentId: 42,
    );
    expect(id, isPositive);
    final attacks = await source.recentAttacks(const Duration(days: 7), now: DateTime.utc(2026, 6, 10, 18));
    expect(attacks, hasLength(1));
    expect(attacks.first.severity, 7);
  });
}
