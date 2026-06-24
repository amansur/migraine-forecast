import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/providers.dart';
import '../shared/animations/celebration_overlay.dart';

class JournalEntrySheet extends ConsumerStatefulWidget {
  final JournalKind kind;
  final JournalEntry? initial;
  const JournalEntrySheet({super.key, required this.kind, this.initial});

  @override
  ConsumerState<JournalEntrySheet> createState() => _JournalEntrySheetState();
}

class _JournalEntrySheetState extends ConsumerState<JournalEntrySheet> {
  late DateTime _at;
  int? _units;     // alcohol
  int? _mg;        // caffeine
  double? _liters; // hydration
  int? _rating;    // stress

  static const _coffeeMg = 95;
  static const _espressoMg = 64;
  static const _teaMg = 47;
  static const _energyMg = 80;

  @override
  void initState() {
    super.initState();
    _at = widget.initial?.at ?? DateTime.now().toUtc();
    final p = widget.initial?.payload;
    if (p != null) {
      switch (widget.kind) {
        case JournalKind.alcohol:
          _units = (p['units'] as num?)?.toInt();
        case JournalKind.caffeine:
          _mg = (p['mg'] as num?)?.toInt();
        case JournalKind.hydration:
          _liters = (p['liters'] as num?)?.toDouble();
        case JournalKind.stress:
          _rating = (p['rating'] as num?)?.toInt();
      }
    }
  }

  bool get _valid {
    switch (widget.kind) {
      case JournalKind.alcohol:
        return (_units ?? 0) >= 1;
      case JournalKind.caffeine:
        return (_mg ?? 0) >= 1;
      case JournalKind.hydration:
        return (_liters ?? 0) > 0;
      case JournalKind.stress:
        return _rating != null;
    }
  }

  Map<String, Object?> _payload() {
    switch (widget.kind) {
      case JournalKind.alcohol:
        return {'units': _units!};
      case JournalKind.caffeine:
        return {'mg': _mg!};
      case JournalKind.hydration:
        return {'liters': _liters!};
      case JournalKind.stress:
        return {'rating': _rating!};
    }
  }

  Future<void> _save() async {
    final journal = ref.read(journalSourceProvider);
    final entry = JournalEntry(
      id: widget.initial?.id,
      at: _at,
      kind: widget.kind,
      payload: _payload(),
    );
    final isNew = entry.id == null;
    if (isNew) {
      await journal.addEntry(entry);
    } else {
      await journal.updateEntry(entry);
    }
    if (!mounted) return;
    if (isNew) {
      CelebrationOverlay.show(context);
    }
    Navigator.of(context).pop(true);
  }

  Future<void> _delete() async {
    final id = widget.initial?.id;
    if (id == null) return;
    await ref.read(journalSourceProvider).deleteEntry(id);
    if (mounted) Navigator.of(context).pop(true);
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
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20,
          16 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(_title(), style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          _buildControls(),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _pickTime,
            icon: const Icon(Icons.schedule),
            label: Text(_at.toLocal().toString().substring(0, 16)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (widget.initial != null)
                TextButton(
                  onPressed: _delete,
                  child: const Text('Delete'),
                ),
              const Spacer(),
              FilledButton(
                key: const Key('entry-save'),
                onPressed: _valid ? _save : null,
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _title() {
    switch (widget.kind) {
      case JournalKind.alcohol:   return 'Log alcohol';
      case JournalKind.caffeine:  return 'Log caffeine';
      case JournalKind.hydration: return 'Log hydration';
      case JournalKind.stress:    return 'Log stress';
    }
  }

  Widget _buildControls() {
    switch (widget.kind) {
      case JournalKind.alcohol:   return _alcohol();
      case JournalKind.caffeine:  return _caffeine();
      case JournalKind.hydration: return _hydration();
      case JournalKind.stress:    return _stress();
    }
  }

  Widget _alcohol() {
    final units = _units ?? 0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton.outlined(
          onPressed: units > 0 ? () => setState(() => _units = units - 1) : null,
          icon: const Icon(Icons.remove),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text('$units drinks', style: Theme.of(context).textTheme.headlineSmall),
        ),
        IconButton.outlined(
          key: const Key('alcohol-inc'),
          onPressed: () => setState(() => _units = units + 1),
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }

  Widget _caffeine() {
    return Wrap(
      spacing: 8,
      children: [
        _presetChip('Coffee 95mg', _coffeeMg, key: 'caffeine-preset-coffee'),
        _presetChip('Espresso 64mg', _espressoMg, key: 'caffeine-preset-espresso'),
        _presetChip('Tea 47mg', _teaMg, key: 'caffeine-preset-tea'),
        _presetChip('Energy 80mg', _energyMg, key: 'caffeine-preset-energy'),
      ],
    );
  }

  Widget _presetChip(String label, int mg, {required String key}) {
    final selected = _mg == mg;
    return ChoiceChip(
      key: Key(key),
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _mg = mg),
    );
  }

  Widget _hydration() {
    return Wrap(
      spacing: 8,
      children: [
        _hydrationChip('Glass 250ml', 0.25, key: 'hydration-preset-glass'),
        _hydrationChip('Bottle 500ml', 0.5, key: 'hydration-preset-bottle'),
        _hydrationChip('Liter 1000ml', 1.0, key: 'hydration-preset-liter'),
      ],
    );
  }

  Widget _hydrationChip(String label, double liters, {required String key}) {
    final selected = _liters == liters;
    return ChoiceChip(
      key: Key(key),
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _liters = liters),
    );
  }

  Widget _stress() {
    return Wrap(
      spacing: 8,
      alignment: WrapAlignment.center,
      children: List.generate(5, (i) {
        final v = i + 1;
        return ChoiceChip(
          key: Key('stress-rating-$v'),
          label: Text('$v'),
          selected: _rating == v,
          onSelected: (_) => setState(() => _rating = v),
        );
      }),
    );
  }
}
