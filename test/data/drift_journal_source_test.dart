import 'package:domain/domain.dart' as domain;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/data/database.dart';
import 'package:migraine_forecast/data/sources/drift_journal_source.dart';

void main() {
  late AppDatabase db;
  late DriftJournalSource source;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    source = DriftJournalSource(db);
  });
  tearDown(() => db.close());

  test('addEntry then recentEntries returns row with id', () async {
    final now = DateTime.utc(2026, 6, 13, 12);
    await source.addEntry(domain.JournalEntry(
      at: now.subtract(const Duration(hours: 1)),
      kind: domain.JournalKind.alcohol,
      payload: const {'units': 2.0},
    ));
    final entries = await source.recentEntries(const Duration(days: 1), now: now);
    expect(entries, hasLength(1));
    expect(entries.single.id, isNotNull);
    expect(entries.single.kind, domain.JournalKind.alcohol);
  });

  test('updateEntry persists changes to payload and at', () async {
    final now = DateTime.utc(2026, 6, 13, 12);
    await source.addEntry(domain.JournalEntry(
      at: now.subtract(const Duration(hours: 2)),
      kind: domain.JournalKind.caffeine,
      payload: const {'mg': 95.0},
    ));
    final entry = (await source.recentEntries(const Duration(days: 1), now: now)).single;
    final updated = domain.JournalEntry(
      id: entry.id,
      at: now.subtract(const Duration(hours: 1)),
      kind: domain.JournalKind.caffeine,
      payload: const {'mg': 190.0},
    );
    await source.updateEntry(updated);
    final after = await source.recentEntries(const Duration(days: 1), now: now);
    expect(after.single.payload['mg'], 190.0);
    expect(after.single.at, now.subtract(const Duration(hours: 1)));
  });

  test('updateEntry without id throws', () async {
    expect(
      () => source.updateEntry(domain.JournalEntry(
        at: DateTime.utc(2026, 6, 13),
        kind: domain.JournalKind.stress,
        payload: const {'rating': 3},
      )),
      throwsArgumentError,
    );
  });

  test('deleteEntry removes the row', () async {
    final now = DateTime.utc(2026, 6, 13, 12);
    await source.addEntry(domain.JournalEntry(
      at: now.subtract(const Duration(hours: 1)),
      kind: domain.JournalKind.hydration,
      payload: const {'liters': 0.5},
    ));
    final id = (await source.recentEntries(const Duration(days: 1), now: now)).single.id!;
    await source.deleteEntry(id);
    expect(await source.recentEntries(const Duration(days: 1), now: now), isEmpty);
  });

  test('watchRecentEntries emits when an entry is added', () async {
    final now = DateTime.utc(2026, 6, 13, 12);
    final stream = source.watchRecentEntries(const Duration(days: 1), now: now);
    final emissions = <int>[];
    final sub = stream.listen((list) => emissions.add(list.length));
    await source.addEntry(domain.JournalEntry(
      at: now.subtract(const Duration(hours: 1)),
      kind: domain.JournalKind.stress,
      payload: const {'rating': 4},
    ));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await sub.cancel();
    expect(emissions, contains(1));
  });
}
