import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../shared/contributor_order.dart';
import 'contributor_chip.dart';

class WhyChips extends StatelessWidget {
  final List<TriggerSignal> contributors;
  const WhyChips({super.key, required this.contributors});

  @override
  Widget build(BuildContext context) {
    final shown = sortContributorsForDisplay(
      contributors.where((c) => c.contribution > 0),
    ).take(4).toList();
    if (shown.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Why', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: shown.map((c) => ContributorChip(signal: c)).toList(),
        ),
      ],
    );
  }
}
