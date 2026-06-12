import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/settings_provider.dart';
import '../shared/unit_formatter.dart';

class ContributorChip extends ConsumerWidget {
  final TriggerSignal signal;
  const ContributorChip({super.key, required this.signal});

  IconData _directionIcon(String explanation) {
    final lower = explanation.toLowerCase();
    if (lower.contains('cooling') || lower.contains('dropping') || lower.contains('deficit') || lower.contains('low')) {
      return Icons.trending_down;
    }
    if (lower.contains('warming') || lower.contains('rising')) {
      return Icons.trending_up;
    }
    return Icons.trending_flat;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formatter = ref.watch(unitFormatterProvider).asData?.value ?? const UnitFormatter();
    final formatted = formatter.formatExplanation(signal.explanation);
    return Chip(
      avatar: Icon(_directionIcon(formatted), size: 16),
      label: SelectableText(formatted),
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
      ),
    );
  }
}
