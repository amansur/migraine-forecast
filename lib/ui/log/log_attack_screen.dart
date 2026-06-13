import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../state/providers.dart';
import '../../state/risk_assessment_provider.dart';

class LogAttackScreen extends ConsumerStatefulWidget {
  final Attack? initialAttack;
  final DateTime? initialDate;
  const LogAttackScreen({super.key, this.initialAttack, this.initialDate});
  @override
  ConsumerState<LogAttackScreen> createState() => _LogAttackScreenState();
}

class _LogAttackScreenState extends ConsumerState<LogAttackScreen> {
  late DateTime _start = _initStart();
  late DateTime? _end = widget.initialAttack?.endedAt?.toLocal();
  late double _severity = widget.initialAttack?.severity.toDouble() ?? 5;
  late bool _inProgress = widget.initialAttack?.inProgress ?? false;
  late final _notesCtrl = TextEditingController();
  bool _saving = false;

  DateTime _initStart() {
    if (widget.initialAttack != null) {
      return widget.initialAttack!.startedAt.toLocal();
    }
    if (widget.initialDate != null) {
      final d = widget.initialDate!;
      // initialDate is a UTC midnight marker (e.g. June 11 00:00Z).
      // We want to initialize the log to June 11 at 12:00 PM in the user's Local time.
      return DateTime(d.year, d.month, d.day, 12, 0);
    }
    return DateTime.now();
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log a migraine')),
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    title: const Text('Started'),
                    subtitle: Text(_start.toString()),
                    trailing: const Icon(Icons.edit_outlined),
                    onTap: _pickStart,
                  ),
                  SwitchListTile(
                    key: const Key('still-in-progress-switch'),
                    title: const Text('Still in progress'),
                    subtitle: const Text('Leave on if the attack is ongoing.'),
                    value: _inProgress,
                    onChanged: (v) => setState(() {
                      _inProgress = v;
                      if (v) _end = null;
                    }),
                  ),
                  if (!_inProgress)
                    ListTile(
                      title: const Text('Ended (optional)'),
                      subtitle: Text(_end?.toString() ?? 'No end time recorded'),
                      trailing: const Icon(Icons.edit_outlined),
                      onTap: _pickEnd,
                    ),
                  const SizedBox(height: 12),
                  Text('Severity: ${_severity.round()}', style: Theme.of(context).textTheme.titleMedium),
                  Slider(value: _severity, min: 1, max: 10, divisions: 9, onChanged: (v) => setState(() => _severity = v)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notesCtrl,
                    decoration: const InputDecoration(labelText: 'Notes', border: OutlineInputBorder()),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(_saving ? 'Saving…' : 'Save'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_saving)
            const ColoredBox(
              color: Color(0x80000000),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Future<void> _pickStart() async {
    final picked = await _pickDateTime(_start);
    if (picked != null) setState(() => _start = picked);
  }

  Future<void> _pickEnd() async {
    final picked = await _pickDateTime(_end ?? DateTime.now());
    if (picked != null) setState(() => _end = picked);
  }

  Future<DateTime?> _pickDateTime(DateTime initial) async {
    final d = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (d == null) return null;
    if (!mounted) return null;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (t == null) return null;
    return DateTime(d.year, d.month, d.day, t.hour, t.minute);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final journal = ref.read(journalSourceProvider);
    final repo = ref.read(assessmentRepoProvider);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final startUtc = _start.toUtc();
      final dayMarker = DateTime.utc(startUtc.year, startUtc.month, startUtc.day);

      final assessmentForDay =
          await repo.latestForDate(target: dayMarker, horizon: RiskHorizon.today);
      int? activeId;
      if (assessmentForDay == null) {
        try {
          await ref.read(riskAssessmentProvider.notifier).backfill(dayMarker);
          // Backfilled rows have computedAt = now(), so look up by targetDate.
          activeId = await repo.rowIdForDate(target: dayMarker, horizon: RiskHorizon.today);
          // Invalidate the provider so the UI shows the newly backfilled data
          ref.invalidate(dayAssessmentProvider(dayMarker));
        } catch (e) {
          debugPrint('Backfill failed: $e');
          if (mounted) {
            messenger.showSnackBar(
              const SnackBar(content: Text("Couldn't fetch weather — risk for this day will be unavailable.")),
            );
          }
        }
      } else {
        activeId = await repo.activeAtRowId(startUtc);
      }

      final current = Attack(
        startedAt: startUtc,
        endedAt: _inProgress ? null : _end?.toUtc(),
        severity: _severity.round(),
        inProgress: _inProgress,
      );

      if (widget.initialAttack != null) {
        await journal.updateAttack(widget.initialAttack!, current);
      } else {
        await journal.addAttack(current, riskAssessmentId: activeId);
      }

      if (mounted) {
        try {
          context.pop();
        } catch (_) {
          // No prior route in test environment — ignore
        }
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
