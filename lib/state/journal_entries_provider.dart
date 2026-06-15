import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';

import 'manual_sleep_provider.dart';
import 'providers.dart';

/// Item rendered in the history list. Either a journal entry or a manual
/// sleep record. Manual sleep is kept as a distinct case so the edit sheet
/// can route to the sleep-specific editor.
sealed class LogHistoryItem {
  DateTime get at;
}

class JournalLogItem extends LogHistoryItem {
  final JournalEntry entry;
  JournalLogItem(this.entry);
  @override
  DateTime get at => entry.at;
}

class SleepLogItem extends LogHistoryItem {
  final SleepRecord record;
  SleepLogItem(this.record);
  // Use sleepStart so it sorts within the day naturally.
  @override
  DateTime get at => record.sleepStart;
}

const _historyWindow = Duration(days: 30);

final journalHistoryProvider = StreamProvider.autoDispose<List<LogHistoryItem>>((ref) {
  final journal = ref.watch(journalSourceProvider);
  final manual = ref.watch(manualSleepSourceProvider);
  final now = DateTime.now().toUtc();
  return Rx.combineLatest2<List<JournalEntry>, List<SleepRecord>, List<LogHistoryItem>>(
    journal.watchRecentEntries(_historyWindow, now: now),
    manual.watchRecent(_historyWindow, now: now),
    (entries, sleeps) {
      final items = <LogHistoryItem>[
        ...entries.map(JournalLogItem.new),
        ...sleeps.map(SleepLogItem.new),
      ];
      items.sort((a, b) => b.at.compareTo(a.at));
      return items;
    },
  );
});
