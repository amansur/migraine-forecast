import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'calendar_heatmap.dart';

Color colorForPhase(CyclePhase phase) {
  switch (phase) {
    case CyclePhase.menses:
      return BrandColors.phaseMenses;
    case CyclePhase.follicular:
      return BrandColors.phaseFollicular;
    case CyclePhase.ovulatory:
      return BrandColors.phaseOvulatory;
    case CyclePhase.luteal:
      return BrandColors.phaseLuteal;
  }
}

/// A thin band rendered above [CalendarHeatmap], one column per day, colored
/// by derived cycle phase. Confirmed days are solid, predicted muted, unknown
/// blank.
///
/// Column layout (cols, gap, Sunday-alignment) mirrors [CalendarHeatmap] so
/// the ribbon visually aligns with the heatmap above it.
class PhaseRibbon extends StatelessWidget {
  final DateTime windowStart;
  final DateTime windowEnd;
  final PhaseResult Function(DateTime day) resolver;

  static const _cellHeight = 8.0;
  static const _gap = 4.0;

  const PhaseRibbon({
    super.key,
    required this.windowStart,
    required this.windowEnd,
    required this.resolver,
  });

  @override
  Widget build(BuildContext context) {
    final gridStart = CalendarHeatmap.nearestSunday(
      DateTime.utc(windowStart.year, windowStart.month, windowStart.day),
    );
    final gridEnd = DateTime.utc(windowEnd.year, windowEnd.month, windowEnd.day);

    final days = <DateTime>[];
    var d = gridStart;
    while (!d.isAfter(gridEnd)) {
      days.add(d);
      d = d.add(const Duration(days: 1));
    }

    return LayoutBuilder(builder: (context, constraints) {
      const cols = CalendarHeatmap.cols;
      const totalGap = (cols - 1) * _gap;
      final cellWidth = (constraints.maxWidth - totalGap) / cols;

      final rows = <Widget>[];
      for (var i = 0; i < days.length; i += cols) {
        final rowDays = days.sublist(i, (i + cols).clamp(0, days.length));
        final cells = <Widget>[];
        for (var j = 0; j < rowDays.length; j++) {
          cells.add(_cell(rowDays[j], cellWidth));
          if (j < rowDays.length - 1) cells.add(const SizedBox(width: _gap));
        }
        rows.add(Padding(
          padding: const EdgeInsets.only(bottom: _gap),
          child: Row(children: cells),
        ));
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...rows,
          const SizedBox(height: 4),
          const _PhaseLegend(),
        ],
      );
    });
  }

  Widget _cell(DateTime day, double width) {
    final r = resolver(day);
    final (color, opacity) = switch (r) {
      PhaseConfirmed(:final phase) => (colorForPhase(phase), 1.0),
      PhasePredicted(:final phase) => (colorForPhase(phase), 0.4),
      PhaseUnknown() => (const Color(0xFFD8D4CC), 1.0),
    };
    return SizedBox(
      key: ValueKey('phase-cell-${day.toIso8601String()}'),
      width: width,
      height: _cellHeight,
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: opacity),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _PhaseLegend extends StatelessWidget {
  const _PhaseLegend();

  @override
  Widget build(BuildContext context) {
    const items = [
      (BrandColors.phaseMenses, 'menses'),
      (BrandColors.phaseFollicular, 'follicular'),
      (BrandColors.phaseOvulatory, 'ovulatory'),
      (BrandColors.phaseLuteal, 'luteal'),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('Phase: ',
            style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45))),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Row(children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: item.$1,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 3),
                Text(item.$2,
                    style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45))),
              ]),
            )),
      ],
    );
  }
}
