import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

class ContributorChip extends StatelessWidget {
  final TriggerSignal signal;
  const ContributorChip({super.key, required this.signal});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: const Icon(Icons.trending_up, size: 16),
      label: Text(signal.explanation),
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
      ),
    );
  }
}
