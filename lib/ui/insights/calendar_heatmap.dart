import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Maps a severity value (1–10) to a brand band color.
Color colorForSeverity(int severity) {
  if (severity >= 9) return BrandColors.bandVeryHigh;
  if (severity >= 6) return BrandColors.bandHigh;
  if (severity >= 3) return BrandColors.bandModerate;
  return BrandColors.bandLow;
}

/// A 7-column (week-aligned) calendar heatmap.
///
/// Each column is a day of the week (Sun..Sat). Each row is a week.
/// The window always starts on the Sunday on or before [windowStart].
class CalendarHeatmap extends StatelessWidget {
  /// Day (UTC midnight) → max severity on that day. Days absent have no attack.
  final Map<DateTime, int> severityByDay;

  /// First day to show (inclusive). The grid will back-align to the nearest
  /// preceding Sunday, so the first column is always Sunday.
  final DateTime windowStart;

  /// Last day to show (inclusive).
  final DateTime windowEnd;

  /// Called when a day cell is tapped.
  final ValueChanged<DateTime>? onTap;

  /// Optional. Set of UTC-midnight days that have a location override active.
  /// Cells for these days show a small pin badge to indicate the assessment
  /// used a different location than the live GPS/manual default.
  final Set<DateTime> overriddenDays;

  static const _dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
  static const cols = 7;
  static const _gap = 4.0;

  const CalendarHeatmap({
    super.key,
    required this.severityByDay,
    required this.windowStart,
    required this.windowEnd,
    this.onTap,
    this.overriddenDays = const {},
  });

  /// Round [d] back to the nearest Sunday (weekday == 7 in Dart is Sunday).
  static DateTime nearestSunday(DateTime d) {
    // DateTime.weekday: Mon=1..Sun=7
    final offset = d.weekday % 7; // Sun=7%7=0, Mon=1%7=1, ... Sat=6%7=6
    return d.subtract(Duration(days: offset));
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayUtc = DateTime.utc(now.year, now.month, now.day);

    // Align grid start to a Sunday
    final gridStart = nearestSunday(
      DateTime.utc(windowStart.year, windowStart.month, windowStart.day),
    );
    final gridEnd = DateTime.utc(windowEnd.year, windowEnd.month, windowEnd.day);

    // Build list of all days from gridStart to gridEnd
    final days = <DateTime>[];
    var d = gridStart;
    while (!d.isAfter(gridEnd)) {
      days.add(d);
      d = d.add(const Duration(days: 1));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const totalGap = (cols - 1) * _gap;
        final cellSize = (constraints.maxWidth - totalGap) / cols;

        // Which days are the first of their month (for month labels)
        final firstOfMonthDays = <DateTime>{};
        for (final day in days) {
          if (day.day == 1) firstOfMonthDays.add(day);
        }

        // Header row: day-of-week labels
        final headerRow = Row(
          children: List.generate(cols, (i) {
            return SizedBox(
              width: cellSize + (i < cols - 1 ? _gap : 0),
              child: Text(
                _dayLabels[i],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }),
        );

        // Build grid rows (one row per week)
        final rows = <Widget>[];
        for (var i = 0; i < days.length; i += cols) {
          final rowDays = days.sublist(i, (i + cols).clamp(0, days.length));
          rows.add(_WeekRow(
            days: rowDays,
            cellSize: cellSize,
            gap: _gap,
            severityByDay: severityByDay,
            todayUtc: todayUtc,
            firstOfMonthDays: firstOfMonthDays,
            onTap: onTap,
            overriddenDays: overriddenDays,
          ));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            headerRow,
            const SizedBox(height: _gap),
            ...rows.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: _gap),
                  child: r,
                )),
            const SizedBox(height: 4),
            _Legend(),
          ],
        );
      },
    );
  }
}

class _WeekRow extends StatelessWidget {
  final List<DateTime> days;
  final double cellSize;
  final double gap;
  final Map<DateTime, int> severityByDay;
  final DateTime todayUtc;
  final Set<DateTime> firstOfMonthDays;
  final ValueChanged<DateTime>? onTap;
  final Set<DateTime> overriddenDays;

  const _WeekRow({
    required this.days,
    required this.cellSize,
    required this.gap,
    required this.severityByDay,
    required this.todayUtc,
    required this.firstOfMonthDays,
    required this.onTap,
    this.overriddenDays = const {},
  });

  @override
  Widget build(BuildContext context) {
    final cells = <Widget>[];
    for (var i = 0; i < days.length; i++) {
      final day = days[i];
      final severity = severityByDay[day];
      final isToday = day.isAtSameMomentAs(todayUtc);
      final isFirstOfMonth = firstOfMonthDays.contains(day);
      final hasOverride = overriddenDays.contains(day);

      final cell = SizedBox(
        width: cellSize,
        height: cellSize,
        child: Stack(
          children: [
            InkWell(
              onTap: () => onTap?.call(day),
              borderRadius: BorderRadius.circular(4),
              child: Container(
                width: cellSize,
                height: cellSize,
                decoration: BoxDecoration(
                  color: severity != null
                      ? colorForSeverity(severity)
                      : BrandColors.sage.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                  border: isToday
                      ? Border.all(color: BrandColors.sage, width: 2)
                      : null,
                ),
              ),
            ),
            if (isFirstOfMonth)
              Positioned(
                left: 2,
                top: 1,
                child: Text(
                  _monthAbbr(day.month),
                  style: TextStyle(
                    fontSize: 8,
                    height: 1.0,
                    color: severity != null
                        ? Colors.white.withValues(alpha: 0.85)
                        : BrandColors.ink.withValues(alpha: 0.55),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            // Location-override badge: small pin in the bottom-right corner.
            if (hasOverride)
              const Positioned(
                right: 1,
                bottom: 1,
                child: Icon(
                  Icons.location_on,
                  size: 8,
                  color: Colors.white,
                ),
              ),
          ],
        ),
      );

      cells.add(cell);
      if (i < days.length - 1) {
        cells.add(SizedBox(width: gap));
      }
    }
    // Pad incomplete rows so alignment stays correct
    final missing = CalendarHeatmap.cols - days.length;
    for (var p = 0; p < missing; p++) {
      if (cells.isNotEmpty) cells.add(SizedBox(width: gap));
      cells.add(SizedBox(width: cellSize, height: cellSize));
    }
    return Row(children: cells);
  }

  static String _monthAbbr(int month) {
    const abbrs = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return abbrs[month - 1];
  }
}

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const items = [
      (BrandColors.bandLow, '1–2'),
      (BrandColors.bandModerate, '3–5'),
      (BrandColors.bandHigh, '6–8'),
      (BrandColors.bandVeryHigh, '9–10'),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          'Severity: ',
          style: TextStyle(
            fontSize: 10,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
          ),
        ),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: item.$1,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    item.$2,
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}
