import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../state/calibration_provider.dart';

const _bandLabels = {
  RiskBand.low: 'Low',
  RiskBand.moderate: 'Moderate',
  RiskBand.high: 'High',
  RiskBand.veryHigh: 'Very high',
};

/// "How often attacks actually followed each forecast band" — the honesty
/// check on the risk engine, computed from the shared day timeline.
class CalibrationCard extends ConsumerWidget {
  const CalibrationCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(calibrationReportProvider);
    return view.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (v) {
        final r = v.report;
        if (r.scoredDays == 0) return const SizedBox.shrink();
        final theme = Theme.of(context);
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Forecast accuracy', style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  'How often attacks actually followed each forecast band '
                  '(${r.scoredDays} days).',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                for (final b in r.bands) _BandRow(b: b),
                if (v.usedBackfilled)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Includes reconstructed (backfilled) days — accuracy will '
                      'be measured on live forecasts as more days accumulate.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BandRow extends StatelessWidget {
  final BandCalibration b;
  const _BandRow({required this.b});

  @override
  Widget build(BuildContext context) {
    final pct = (b.attackRate.point * 100).round();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        SizedBox(width: 84, child: Text(_bandLabels[b.band]!)),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: b.attackRate.point,
              minHeight: 8,
              color: colorForBand(b.band.name),
              backgroundColor: colorForBand(b.band.name).withValues(alpha: 0.15),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text('$pct% · ${b.days}d', style: Theme.of(context).textTheme.bodySmall),
      ]),
    );
  }
}
