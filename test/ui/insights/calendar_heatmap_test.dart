import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/app/theme.dart';
import 'package:migraine_forecast/ui/insights/calendar_heatmap.dart';

Widget _wrapHeatmap(CalendarHeatmap heatmap) {
  return MaterialApp(
    theme: buildLightTheme(),
    home: Scaffold(
      body: SizedBox(
        width: 400,
        child: heatmap,
      ),
    ),
  );
}

void main() {
  // A fixed "today" in UTC for deterministic tests.
  // We use a specific date to ensure the near-Sunday rounding is predictable.
  // 2024-01-07 is a Sunday. windowEnd is 2024-01-13 (Saturday).
  final baseDay = DateTime.utc(2024, 1, 13); // a Saturday
  final windowStart = baseDay.subtract(const Duration(days: 6)); // 2024-01-07 (Sun)

  group('colorForSeverity', () {
    test('severity 1 returns bandLow', () {
      expect(colorForSeverity(1), BrandColors.bandLow);
    });
    test('severity 2 returns bandLow', () {
      expect(colorForSeverity(2), BrandColors.bandLow);
    });
    test('severity 3 returns bandModerate', () {
      expect(colorForSeverity(3), BrandColors.bandModerate);
    });
    test('severity 5 returns bandModerate', () {
      expect(colorForSeverity(5), BrandColors.bandModerate);
    });
    test('severity 6 returns bandHigh', () {
      expect(colorForSeverity(6), BrandColors.bandHigh);
    });
    test('severity 8 returns bandHigh', () {
      expect(colorForSeverity(8), BrandColors.bandHigh);
    });
    test('severity 9 returns bandVeryHigh', () {
      expect(colorForSeverity(9), BrandColors.bandVeryHigh);
    });
    test('severity 10 returns bandVeryHigh', () {
      expect(colorForSeverity(10), BrandColors.bandVeryHigh);
    });
  });

  group('CalendarHeatmap.nearestSunday', () {
    test('Sunday stays as Sunday', () {
      final sun = DateTime.utc(2024, 1, 7); // Sunday
      expect(CalendarHeatmap.nearestSunday(sun), sun);
    });
    test('Monday rolls back to Sunday', () {
      final mon = DateTime.utc(2024, 1, 8);
      expect(CalendarHeatmap.nearestSunday(mon), DateTime.utc(2024, 1, 7));
    });
    test('Saturday rolls back to Sunday', () {
      final sat = DateTime.utc(2024, 1, 13);
      expect(CalendarHeatmap.nearestSunday(sat), DateTime.utc(2024, 1, 7));
    });
  });

  group('CalendarHeatmap widget', () {
    testWidgets('renders day-of-week header labels', (tester) async {
      await tester.pumpWidget(_wrapHeatmap(CalendarHeatmap(
        severityByDay: {},
        windowStart: windowStart,
        windowEnd: baseDay,
      )));
      await tester.pumpAndSettle();

      // Should find S, M, T, W, T, F, S labels
      expect(find.text('S'), findsAtLeast(2)); // two Sundays + Saturdays
      expect(find.text('M'), findsOneWidget);
      expect(find.text('W'), findsOneWidget);
      expect(find.text('F'), findsOneWidget);
    });

    testWidgets('cell for severity 9 uses bandVeryHigh color', (tester) async {
      final attackDay = DateTime.utc(2024, 1, 8); // Monday
      await tester.pumpWidget(_wrapHeatmap(CalendarHeatmap(
        severityByDay: {attackDay: 9},
        windowStart: windowStart,
        windowEnd: baseDay,
      )));
      await tester.pumpAndSettle();

      // Find Container widgets with bandVeryHigh color
      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasVeryHighColor = containers.any((c) {
        final decoration = c.decoration;
        if (decoration is BoxDecoration) {
          return decoration.color == BrandColors.bandVeryHigh;
        }
        return false;
      });
      expect(hasVeryHighColor, isTrue);
    });

    testWidgets('cell for severity 1 uses bandLow color', (tester) async {
      final attackDay = DateTime.utc(2024, 1, 8);
      await tester.pumpWidget(_wrapHeatmap(CalendarHeatmap(
        severityByDay: {attackDay: 1},
        windowStart: windowStart,
        windowEnd: baseDay,
      )));
      await tester.pumpAndSettle();

      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasLowColor = containers.any((c) {
        final decoration = c.decoration;
        if (decoration is BoxDecoration) {
          return decoration.color == BrandColors.bandLow;
        }
        return false;
      });
      expect(hasLowColor, isTrue);
    });

    testWidgets('days without attacks use sage background', (tester) async {
      await tester.pumpWidget(_wrapHeatmap(CalendarHeatmap(
        severityByDay: {},
        windowStart: windowStart,
        windowEnd: baseDay,
      )));
      await tester.pumpAndSettle();

      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasSageBackground = containers.any((c) {
        final decoration = c.decoration;
        if (decoration is BoxDecoration) {
          // sage.withValues(alpha: 0.12) — check the color is a sage variant
          final color = decoration.color;
          return color != null &&
              color != BrandColors.bandVeryHigh &&
              color != BrandColors.bandHigh &&
              color != BrandColors.bandModerate &&
              color != BrandColors.bandLow;
        }
        return false;
      });
      expect(hasSageBackground, isTrue);
    });

    testWidgets('renders expected number of day cells', (tester) async {
      // windowStart=2024-01-07 (Sun), windowEnd=2024-01-13 (Sat) = 7 days
      // nearestSunday of 2024-01-07 is itself, so exactly 7 cells
      await tester.pumpWidget(_wrapHeatmap(CalendarHeatmap(
        severityByDay: {},
        windowStart: windowStart,
        windowEnd: baseDay,
      )));
      await tester.pumpAndSettle();

      // 7 InkWell tappable cells
      expect(find.byType(InkWell), findsNWidgets(7));
    });

    testWidgets('shows legend with severity labels', (tester) async {
      await tester.pumpWidget(_wrapHeatmap(CalendarHeatmap(
        severityByDay: const {},
        windowStart: windowStart,
        windowEnd: baseDay,
      )));
      await tester.pumpAndSettle();

      expect(find.textContaining('Severity'), findsOneWidget);
      expect(find.text('1–2'), findsOneWidget);
      expect(find.text('9–10'), findsOneWidget);
    });

    testWidgets('tapping a day cell calls onTap', (tester) async {
      DateTime? tappedDay;
      final attackDay = DateTime.utc(2024, 1, 8);
      await tester.pumpWidget(_wrapHeatmap(CalendarHeatmap(
        severityByDay: {attackDay: 7},
        windowStart: windowStart,
        windowEnd: baseDay,
        onTap: (d) => tappedDay = d,
      )));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(InkWell).first);
      await tester.pump();

      expect(tappedDay, isNotNull);
    });
  });
}
