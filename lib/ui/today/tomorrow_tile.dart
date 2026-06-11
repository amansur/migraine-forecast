import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../state/risk_assessment_provider.dart';

class TomorrowTile extends ConsumerWidget {
  const TomorrowTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tomorrow = ref.watch(tomorrowRiskAssessmentProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: tomorrow.when(
          loading: () => const Center(child: SizedBox(
            width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2),
          )),
          error: (e, _) => Text('Tomorrow: --', style: Theme.of(context).textTheme.titleSmall),
          data: (ass) {
            final color = colorForBand(ass.band.name);
            return Row(
              children: [
                Container(
                  width: 14, height: 14,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 12),
                Text('Tomorrow: ${_label(ass.band)} (${ass.score})',
                    style: Theme.of(context).textTheme.titleSmall),
              ],
            );
          },
        ),
      ),
    );
  }

  String _label(RiskBand b) {
    switch (b) {
      case RiskBand.low: return 'Low';
      case RiskBand.moderate: return 'Moderate';
      case RiskBand.high: return 'High';
      case RiskBand.veryHigh: return 'Very High';
    }
  }
}
