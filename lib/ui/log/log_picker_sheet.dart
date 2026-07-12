import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../state/manual_sleep_provider.dart';
import 'journal_entry_sheet.dart';
import 'medication_entry_sheet.dart';
import 'sleep_entry_sheet.dart';

class LogPickerSheet extends ConsumerWidget {
  const LogPickerSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sleepEnabled = ref.watch(manualSleepEnabledProvider);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
          _kindTile(context, key: 'log-kind-alcohol', icon: Icons.local_bar_outlined,
              label: 'Alcohol', onTap: () => _openJournalSheet(context, JournalKind.alcohol)),
          _kindTile(context, key: 'log-kind-caffeine', icon: Icons.local_cafe_outlined,
              label: 'Caffeine', onTap: () => _openJournalSheet(context, JournalKind.caffeine)),
          _kindTile(context, key: 'log-kind-hydration', icon: Icons.water_drop_outlined,
              label: 'Hydration', onTap: () => _openJournalSheet(context, JournalKind.hydration)),
          _kindTile(context, key: 'log-kind-stress', icon: Icons.psychology_outlined,
              label: 'Stress', onTap: () => _openJournalSheet(context, JournalKind.stress)),
          _kindTile(context, key: 'log-kind-skipped-meal', icon: Icons.no_meals_outlined,
              label: 'Skipped meal', onTap: () => _openJournalSheet(context, JournalKind.skippedMeal)),
          _kindTile(context, key: 'log-kind-medication', icon: Icons.medication_outlined,
              label: 'Medication', onTap: () => _openMedicationSheet(context)),
          if (sleepEnabled)
            _kindTile(context, key: 'log-kind-sleep', icon: Icons.bedtime_outlined,
                label: 'Sleep', onTap: () => _openSleepSheet(context)),
          const Divider(height: 1),
          ListTile(
            key: const Key('log-history-link'),
            leading: const Icon(Icons.history),
            title: const Text('View history'),
            onTap: () {
              Navigator.of(context).pop();
              context.push('/log-history');
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _kindTile(BuildContext context,
      {required String key, required IconData icon, required String label, required VoidCallback onTap}) {
    return ListTile(
      key: Key(key),
      leading: Icon(icon),
      title: Text(label),
      onTap: onTap,
    );
  }

  Future<void> _openJournalSheet(BuildContext context, JournalKind kind) async {
    Navigator.of(context).pop();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => JournalEntrySheet(kind: kind),
    );
  }

  Future<void> _openMedicationSheet(BuildContext context) async {
    Navigator.of(context).pop();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const MedicationEntrySheet(),
    );
  }

  Future<void> _openSleepSheet(BuildContext context) async {
    Navigator.of(context).pop();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const SleepEntrySheet(),
    );
  }
}
