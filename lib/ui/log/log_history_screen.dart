import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../state/journal_entries_provider.dart';
import '../../state/manual_sleep_provider.dart';
import '../../state/medication_provider.dart';
import '../../state/providers.dart';
import 'journal_entry_sheet.dart';
import 'sleep_entry_sheet.dart';

class LogHistoryScreen extends ConsumerWidget {
  const LogHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(journalHistoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Log history')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('No entries yet'));
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) => _Row(item: items[i]),
          );
        },
      ),
    );
  }
}

class _Row extends ConsumerWidget {
  final LogHistoryItem item;
  const _Row({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final time = DateFormat('MMM d, HH:mm').format(item.at.toLocal());
    return Dismissible(
      key: ValueKey(_keyFor(item)),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) async {
        await _delete(ref, item);
        final messenger = ScaffoldMessenger.of(context);
        messenger.showSnackBar(SnackBar(
          content: const Text('Entry deleted'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => _restore(ref, item),
          ),
          duration: const Duration(seconds: 5),
        ));
      },
      child: ListTile(
        leading: Icon(_icon(item)),
        title: Text(_summary(item)),
        subtitle: Text(time),
        onTap: () => _edit(context, item),
      ),
    );
  }

  String _keyFor(LogHistoryItem item) {
    if (item is JournalLogItem) return 'j-${item.entry.id}';
    if (item is SleepLogItem) return 's-${item.record.night.toIso8601String()}';
    if (item is MedicationLogItem) return 'm-${item.dose.id}';
    return item.hashCode.toString();
  }

  IconData _icon(LogHistoryItem item) {
    if (item is SleepLogItem) return Icons.bedtime_outlined;
    if (item is MedicationLogItem) return Icons.medication_outlined;
    final entry = (item as JournalLogItem).entry;
    switch (entry.kind) {
      case JournalKind.alcohol:   return Icons.local_bar_outlined;
      case JournalKind.caffeine:  return Icons.local_cafe_outlined;
      case JournalKind.hydration: return Icons.water_drop_outlined;
      case JournalKind.stress:    return Icons.psychology_outlined;
    }
  }

  String _summary(LogHistoryItem item) {
    if (item is SleepLogItem) {
      final h = item.record.totalSleep.inHours;
      final m = item.record.totalSleep.inMinutes % 60;
      return '${h}h ${m}m sleep';
    }
    if (item is MedicationLogItem) {
      final d = item.dose;
      const relief = {0: ' — didn\'t help', 1: ' — helped some', 2: ' — helped'};
      return '${d.name}${relief[d.reliefRating] ?? ''}';
    }
    final e = (item as JournalLogItem).entry;
    switch (e.kind) {
      case JournalKind.alcohol:   return '${e.payload['units']} drinks';
      case JournalKind.caffeine:  return '${e.payload['mg']} mg';
      case JournalKind.hydration:
        final l = (e.payload['liters'] as num).toDouble();
        return '${(l * 1000).round()} ml';
      case JournalKind.stress:    return 'Stress ${e.payload['rating']}/5';
    }
  }

  Future<void> _edit(BuildContext context, LogHistoryItem item) async {
    if (item is SleepLogItem) {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => SleepEntrySheet(initial: item.record),
      );
    } else if (item is JournalLogItem) {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => JournalEntrySheet(kind: item.entry.kind, initial: item.entry),
      );
    }
  }

  Future<void> _delete(WidgetRef ref, LogHistoryItem item) async {
    if (item is JournalLogItem) {
      await ref.read(journalSourceProvider).deleteEntry(item.entry.id!);
    } else if (item is SleepLogItem) {
      await ref.read(manualSleepSourceProvider).delete(item.record.night);
    } else if (item is MedicationLogItem) {
      await ref.read(medicationRepoProvider).delete(item.dose.id!);
    }
  }

  Future<void> _restore(WidgetRef ref, LogHistoryItem item) async {
    if (item is JournalLogItem) {
      await ref.read(journalSourceProvider).addEntry(item.entry);
    } else if (item is SleepLogItem) {
      await ref.read(manualSleepSourceProvider).upsert(item.record);
    } else if (item is MedicationLogItem) {
      await ref.read(medicationRepoProvider).insert(item.dose);
    }
  }
}
