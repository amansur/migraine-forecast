import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/data/sources/journal_source.dart';
import 'package:migraine_forecast/state/providers.dart';
import 'package:migraine_forecast/ui/log/journal_entry_sheet.dart';

class _FakeJournal implements JournalSource {
  final added = <JournalEntry>[];
  final updated = <JournalEntry>[];
  final deleted = <int>[];

  @override
  Future<void> addEntry(JournalEntry e) async => added.add(e);
  @override
  Future<void> updateEntry(JournalEntry e) async => updated.add(e);
  @override
  Future<void> deleteEntry(int id) async => deleted.add(id);

  // Everything else is unused for these tests:
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

int _ignorePointerCount(WidgetTester tester) =>
    tester.widgetList(find.byType(IgnorePointer)).length;

void main() {
  testWidgets('saving a new journal entry shows a confetti overlay', (tester) async {
    final fake = _FakeJournal();
    await tester.pumpWidget(ProviderScope(
      overrides: [journalSourceProvider.overrideWithValue(fake)],
      child: const MaterialApp(
        home: Scaffold(body: JournalEntrySheet(kind: JournalKind.alcohol)),
      ),
    ));

    await tester.tap(find.byKey(const Key('alcohol-inc')));
    await tester.pump();

    final before = _ignorePointerCount(tester);

    await tester.tap(find.byKey(const Key('entry-save')));
    await tester.pump(); // run _save() to the overlay insert

    expect(fake.added, hasLength(1));
    // Confetti overlay inserted before pop — one extra IgnorePointer in tree.
    expect(_ignorePointerCount(tester), greaterThan(before));

    await tester.pump(const Duration(milliseconds: 1300));
  });

  testWidgets('updating an existing journal entry does NOT show confetti', (tester) async {
    final fake = _FakeJournal();
    final initial = JournalEntry(
      id: 42,
      at: DateTime.utc(2026, 6, 20, 9),
      kind: JournalKind.alcohol,
      payload: const {'units': 1},
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [journalSourceProvider.overrideWithValue(fake)],
      child: MaterialApp(
        home: Scaffold(
          body: JournalEntrySheet(kind: JournalKind.alcohol, initial: initial),
        ),
      ),
    ));

    final before = _ignorePointerCount(tester);

    await tester.tap(find.byKey(const Key('entry-save')));
    await tester.pump();

    expect(fake.updated, hasLength(1));
    // No celebration overlay for updates — count unchanged.
    expect(_ignorePointerCount(tester), equals(before));
  });
}
