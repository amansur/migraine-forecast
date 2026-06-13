import 'package:flutter/material.dart';

/// Modal dialog asking the user for a 1..10 baseline severity. Returns the
/// selected severity on confirm, or null on cancel.
class BaselineSeverityDialog extends StatefulWidget {
  final String title;
  final int initial;
  const BaselineSeverityDialog({
    super.key,
    this.title = 'Baseline severity',
    this.initial = 5,
  });

  static Future<int?> show(BuildContext context,
          {String title = 'Baseline severity', int initial = 5}) =>
      showDialog<int>(
        context: context,
        builder: (_) => BaselineSeverityDialog(title: title, initial: initial),
      );

  @override
  State<BaselineSeverityDialog> createState() => _BaselineSeverityDialogState();
}

class _BaselineSeverityDialogState extends State<BaselineSeverityDialog> {
  late double _value = widget.initial.toDouble();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Severity: ${_value.round()}',
              style: Theme.of(context).textTheme.titleMedium),
          Slider(
            value: _value,
            min: 1,
            max: 10,
            divisions: 9,
            label: _value.round().toString(),
            onChanged: (v) => setState(() => _value = v),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.pop(context, _value.round()),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
