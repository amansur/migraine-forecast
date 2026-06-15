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

Future<void> pumpSheet(WidgetTester tester, _FakeJournal fake, JournalKind kind, {JournalEntry? initial}) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [journalSourceProvider.overrideWithValue(fake)],
    child: MaterialApp(
      home: Scaffold(body: JournalEntrySheet(kind: kind, initial: initial)),
    ),
  ));
}

void main() {
  testWidgets('alcohol: tapping +1 then Save writes units=1', (tester) async {
    final fake = _FakeJournal();
    await pumpSheet(tester, fake, JournalKind.alcohol);
    await tester.tap(find.byKey(const Key('alcohol-inc')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('entry-save')));
    await tester.pump();
    expect(fake.added, hasLength(1));
    expect(fake.added.single.kind, JournalKind.alcohol);
    expect(fake.added.single.payload['units'], 1);
  });

  testWidgets('caffeine: selecting Coffee preset writes mg=95', (tester) async {
    final fake = _FakeJournal();
    await pumpSheet(tester, fake, JournalKind.caffeine);
    await tester.tap(find.byKey(const Key('caffeine-preset-coffee')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('entry-save')));
    await tester.pump();
    expect(fake.added.single.payload['mg'], 95);
  });

  testWidgets('hydration: tapping Bottle writes liters=0.5', (tester) async {
    final fake = _FakeJournal();
    await pumpSheet(tester, fake, JournalKind.hydration);
    await tester.tap(find.byKey(const Key('hydration-preset-bottle')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('entry-save')));
    await tester.pump();
    expect(fake.added.single.payload['liters'], 0.5);
  });

  testWidgets('stress: selecting rating 4 writes rating=4', (tester) async {
    final fake = _FakeJournal();
    await pumpSheet(tester, fake, JournalKind.stress);
    await tester.tap(find.byKey(const Key('stress-rating-4')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('entry-save')));
    await tester.pump();
    expect(fake.added.single.payload['rating'], 4);
  });

  testWidgets('edit mode pre-fills and calls updateEntry', (tester) async {
    final fake = _FakeJournal();
    final initial = JournalEntry(
      id: 7,
      at: DateTime.utc(2026, 6, 13, 10),
      kind: JournalKind.stress,
      payload: const {'rating': 2},
    );
    await pumpSheet(tester, fake, JournalKind.stress, initial: initial);
    await tester.tap(find.byKey(const Key('stress-rating-5')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('entry-save')));
    await tester.pump();
    expect(fake.updated, hasLength(1));
    expect(fake.updated.single.id, 7);
    expect(fake.updated.single.payload['rating'], 5);
  });

  testWidgets('save is disabled until payload is valid', (tester) async {
    final fake = _FakeJournal();
    await pumpSheet(tester, fake, JournalKind.stress);
    final saveBtn = tester.widget<FilledButton>(find.byKey(const Key('entry-save')));
    expect(saveBtn.onPressed, isNull);
  });
}
