import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/state/journal_entries_provider.dart';
import 'package:migraine_forecast/ui/log/log_history_screen.dart';

void main() {
  testWidgets('renders rows from journalHistoryProvider', (tester) async {
    final entries = <LogHistoryItem>[
      JournalLogItem(JournalEntry(
        id: 1,
        at: DateTime.utc(2026, 6, 13, 10),
        kind: JournalKind.alcohol,
        payload: const {'units': 2},
      )),
      JournalLogItem(JournalEntry(
        id: 2,
        at: DateTime.utc(2026, 6, 13, 9),
        kind: JournalKind.caffeine,
        payload: const {'mg': 95},
      )),
    ];
    await tester.pumpWidget(ProviderScope(
      overrides: [
        journalHistoryProvider.overrideWith((_) => Stream.value(entries)),
      ],
      child: const MaterialApp(home: LogHistoryScreen()),
    ));
    await tester.pump();
    expect(find.text('2 drinks'), findsOneWidget);
    expect(find.text('95 mg'), findsOneWidget);
  });

  testWidgets('empty state renders when no entries', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        journalHistoryProvider.overrideWith((_) => Stream.value(<LogHistoryItem>[])),
      ],
      child: const MaterialApp(home: LogHistoryScreen()),
    ));
    await tester.pump();
    expect(find.text('No entries yet'), findsOneWidget);
  });
}
