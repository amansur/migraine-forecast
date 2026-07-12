import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/medication_provider.dart';
import '../shared/animations/celebration_overlay.dart';

const _classLabels = {
  MedClass.triptan: 'Triptan',
  MedClass.simpleAnalgesic: 'Pain reliever',
  MedClass.combination: 'Combination',
  MedClass.preventive: 'Preventive',
  MedClass.other: 'Other',
};

class MedicationEntrySheet extends ConsumerStatefulWidget {
  const MedicationEntrySheet({super.key});

  @override
  ConsumerState<MedicationEntrySheet> createState() => _MedicationEntrySheetState();
}

class _MedicationEntrySheetState extends ConsumerState<MedicationEntrySheet> {
  final _nameController = TextEditingController();
  MedClass? _medClass;
  int? _relief;
  DateTime _at = DateTime.now().toUtc();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _valid => _nameController.text.trim().isNotEmpty && _medClass != null;

  Future<void> _save() async {
    await ref.read(medicationRepoProvider).insert(MedicationDose(
          at: _at,
          name: _nameController.text.trim(),
          medClass: _medClass!,
          reliefRating: _relief,
        ));
    ref.invalidate(recentMedicationDosesProvider);
    ref.invalidate(medicationNamesProvider);
    if (!mounted) return;
    CelebrationOverlay.show(context);
    Navigator.of(context).pop(true);
  }

  Future<void> _pickTime() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _at.toLocal(),
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now(),
    );
    if (picked == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_at.toLocal()),
    );
    if (time == null) return;
    setState(() {
      _at = DateTime(picked.year, picked.month, picked.day, time.hour, time.minute)
          .toUtc();
    });
  }

  @override
  Widget build(BuildContext context) {
    final pastNames = ref.watch(medicationNamesProvider).asData?.value ?? const [];
    return Padding(
      padding:
          EdgeInsets.fromLTRB(20, 16, 20, 16 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Log medication', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            key: const Key('med-name'),
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'e.g. Sumatriptan',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
          ),
          if (pastNames.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final n in pastNames.take(4))
                  ActionChip(
                    key: Key('med-past-$n'),
                    label: Text(n),
                    onPressed: () => setState(() => _nameController.text = n),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              for (final c in MedClass.values)
                ChoiceChip(
                  key: Key('med-class-${c.name}'),
                  label: Text(_classLabels[c]!),
                  selected: _medClass == c,
                  onSelected: (_) => setState(() => _medClass = c),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Did it help? (optional)', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            children: [
              for (final (label, value) in const [('No', 0), ('Some', 1), ('Yes', 2)])
                ChoiceChip(
                  key: Key('med-relief-$value'),
                  label: Text(label),
                  selected: _relief == value,
                  onSelected: (sel) => setState(() => _relief = sel ? value : null),
                ),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _pickTime,
            icon: const Icon(Icons.schedule),
            label: Text(_at.toLocal().toString().substring(0, 16)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Spacer(),
              FilledButton(
                key: const Key('med-save'),
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
