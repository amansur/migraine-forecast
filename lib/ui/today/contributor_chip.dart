import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/settings_provider.dart';
import '../shared/unit_formatter.dart';

class ContributorChip extends ConsumerWidget {
  final TriggerSignal signal;
  const ContributorChip({super.key, required this.signal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formatter = ref.watch(unitFormatterProvider).asData?.value ?? const UnitFormatter();
    return Chip(
      avatar: const Icon(Icons.trending_up, size: 16),
      label: SelectableText(formatter.formatExplanation(signal.explanation)),
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
      ),
    );
  }
}
