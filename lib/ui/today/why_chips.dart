import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../shared/animations/animated_entry.dart';
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < shown.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AnimatedEntry(
                  delay: Duration(milliseconds: 60 * i),
                  effect: AnimatedEntryEffect.scalePop,
                  child: ContributorChip(signal: shown[i]),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
