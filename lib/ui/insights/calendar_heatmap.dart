import 'package:flutter/material.dart';

import '../../app/theme.dart';

class CalendarHeatmap extends StatelessWidget {
  final Set<DateTime> attackDays;
  final DateTime windowStart;
  final DateTime windowEnd;
  const CalendarHeatmap({
    super.key,
    required this.attackDays,
    required this.windowStart,
    required this.windowEnd,
  });

  @override
  Widget build(BuildContext context) {
    final days = <DateTime>[];
    var d = DateTime.utc(windowStart.year, windowStart.month, windowStart.day);
    final end = DateTime.utc(windowEnd.year, windowEnd.month, windowEnd.day);
    while (!d.isAfter(end)) {
      days.add(d);
      d = d.add(const Duration(days: 1));
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        const cols = 14;
        final cellSize = (constraints.maxWidth - (cols - 1) * 4) / cols;
        return Wrap(
          spacing: 4,
          runSpacing: 4,
          children: days.map((day) {
            final hit = attackDays.contains(day);
            return Container(
              width: cellSize,
              height: cellSize,
              decoration: BoxDecoration(
                color: hit ? BrandColors.bandVeryHigh : BrandColors.sage.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
