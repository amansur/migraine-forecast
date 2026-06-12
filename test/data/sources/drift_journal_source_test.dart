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
      payload: const {'units': 2.0},
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
      payload: const {'mg': 100},
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

  test('recentAttacks filters both lower and upper bounds', () async {
    final day = DateTime.utc(2026, 6, 10);
    final prevDay = day.subtract(const Duration(days: 1));
    final nextDay = day.add(const Duration(days: 1));

    await source.addAttack(Attack(startedAt: prevDay, severity: 1));
    await source.addAttack(Attack(startedAt: day, severity: 5));
    await source.addAttack(Attack(startedAt: nextDay, severity: 8));

    // Ask for exactly June 10th
    final results = await source.recentAttacks(
      const Duration(days: 1),
      now: nextDay,
    );

    expect(results, hasLength(1));
    expect(results.first.severity, 5);
  });

  test('persists and reads back Attack.inProgress', () async {
    final now = DateTime.utc(2026, 6, 1, 12);
    await source.addAttack(Attack(startedAt: now, severity: 6, inProgress: true));
    final attacks = await source.recentAttacks(
      const Duration(days: 1),
      now: now.add(const Duration(hours: 1)),
    );
    expect(attacks, hasLength(1));
    expect(attacks.first.inProgress, isTrue);
    expect(attacks.first.endedAt, isNull);
  });

  test('updateAttack round-trips inProgress', () async {
    final now = DateTime.utc(2026, 6, 1, 12);
    final original = Attack(startedAt: now, severity: 6);
    await source.addAttack(original);

    final updated = Attack(startedAt: now, severity: 6, inProgress: true);
    await source.updateAttack(original, updated);

    final attacks = await source.recentAttacks(
      const Duration(days: 1),
      now: now.add(const Duration(hours: 1)),
    );
    expect(attacks, hasLength(1));
    expect(attacks.first.inProgress, isTrue);
  });
}
