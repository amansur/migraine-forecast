import 'package:flutter/material.dart';

import '../../app/theme.dart';

class CalendarHeatmap extends StatelessWidget {
  /// Days (UTC midnight) on which an attack occurred.
  final Set<DateTime> attackDays;
  /// First day to show (inclusive).
  final DateTime windowStart;
  /// Last day to show (inclusive).
  final DateTime windowEnd;
  /// Called when a day is tapped.
  final ValueChanged<DateTime>? onTap;

  const CalendarHeatmap({
    super.key,
    required this.attackDays,
    required this.windowStart,
    required this.windowEnd,
    this.onTap,
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
            final d = DateTime.now();
            final todayMarker = DateTime.utc(d.year, d.month, d.day);
            final isToday = day.isAtSameMomentAs(todayMarker);

            return InkWell(
              onTap: () => onTap?.call(day),
              borderRadius: BorderRadius.circular(4),
              child: Container(
                width: cellSize,
                height: cellSize,
                decoration: BoxDecoration(
                  color: hit ? BrandColors.bandVeryHigh : BrandColors.sage.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                  border: isToday ? Border.all(color: BrandColors.sage, width: 2) : null,
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

