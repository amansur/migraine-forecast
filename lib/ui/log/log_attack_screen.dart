import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../state/providers.dart';

class LogAttackScreen extends ConsumerStatefulWidget {
  const LogAttackScreen({super.key});
  @override
  ConsumerState<LogAttackScreen> createState() => _LogAttackScreenState();
}

class _LogAttackScreenState extends ConsumerState<LogAttackScreen> {
  late DateTime _start = DateTime.now();
  DateTime? _end;
  double _severity = 5;
  final _notesCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log a migraine')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                title: const Text('Started'),
                subtitle: Text(_start.toLocal().toString()),
                trailing: const Icon(Icons.edit_outlined),
                onTap: _pickStart,
              ),
              ListTile(
                title: const Text('Ended (optional)'),
                subtitle: Text(_end?.toLocal().toString() ?? 'In progress'),
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
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
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
    await journal.addAttack(
      Attack(startedAt: _start.toUtc(), endedAt: _end?.toUtc(), severity: _severity.round()),
      riskAssessmentId: null, // Plan 5 will wire the assessment row's PK
    );
    if (mounted) {
      try {
        context.pop();
      } catch (_) {
        // No prior route in test environment — ignore
      }
    }
  }
}
