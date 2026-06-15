import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/manual_sleep_provider.dart';

class SleepEntrySheet extends ConsumerStatefulWidget {
  final SleepRecord? initial;
  const SleepEntrySheet({super.key, this.initial});

  @override
  ConsumerState<SleepEntrySheet> createState() => _SleepEntrySheetState();
}

class _SleepEntrySheetState extends ConsumerState<SleepEntrySheet> {
  late DateTime _bed;
  late DateTime _wake;

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
    if (init != null) {
      _bed = init.sleepStart.toLocal();
      _wake = _bed.add(init.totalSleep);
    } else {
      // Default: last night 22:00 → this morning 06:00 local.
      final today = DateTime.now();
      _bed = DateTime(today.year, today.month, today.day - 1, 22, 0);
      _wake = DateTime(today.year, today.month, today.day, 6, 0);
    }
  }

  Duration get _duration => _wake.difference(_bed);

  bool get _valid =>
      _duration >= const Duration(hours: 1) &&
      _duration <= const Duration(hours: 16);

  DateTime get _night {
    final utc = _bed.toUtc();
    return DateTime.utc(utc.year, utc.month, utc.day);
  }

  Future<void> _save() async {
    final manual = ref.read(manualSleepSourceProvider);
    await manual.upsert(SleepRecord(
      night: _night,
      sleepStart: _bed.toUtc(),
      totalSleep: _duration,
      efficiency: 1.0,
    ));
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _delete() async {
    final init = widget.initial;
    if (init == null) return;
    await ref.read(manualSleepSourceProvider).delete(init.night);
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<DateTime?> _pick(DateTime initial) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 14)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null || !mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20,
          16 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Log sleep', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.bedtime_outlined),
            title: const Text('Bedtime'),
            subtitle: Text(_bed.toString().substring(0, 16)),
            onTap: () async {
              final picked = await _pick(_bed);
              if (picked != null) setState(() => _bed = picked);
            },
          ),
          ListTile(
            leading: const Icon(Icons.wb_sunny_outlined),
            title: const Text('Wake time'),
            subtitle: Text(_wake.toString().substring(0, 16)),
            onTap: () async {
              final picked = await _pick(_wake);
              if (picked != null) setState(() => _wake = picked);
            },
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              _valid
                  ? '${_duration.inHours}h ${_duration.inMinutes % 60}m'
                  : 'Sleep must be 1–16h',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (widget.initial != null)
                TextButton(onPressed: _delete, child: const Text('Delete')),
              const Spacer(),
              FilledButton(
                key: const Key('sleep-save'),
                onPressed: _valid ? _save : null,
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
