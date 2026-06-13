import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_weatherr/ui/insights/phase_ribbon.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('renders a cell per day in the window', (tester) async {
    await tester.pumpWidget(_wrap(PhaseRibbon(
      windowStart: DateTime.utc(2026, 6, 1),
      windowEnd: DateTime.utc(2026, 6, 7),
      resolver: (_) => const PhaseUnknown(),
    )));
    await tester.pumpAndSettle();
    // Window 2026-06-01..2026-06-07 expands back to Sunday 2026-05-31 → 8 days.
    expect(
      find.byWidgetPredicate((w) => w is SizedBox && (w.key?.toString().contains('phase-cell-') ?? false)),
      findsNWidgets(8),
    );
  });

  testWidgets('legend shows four phases', (tester) async {
    await tester.pumpWidget(_wrap(PhaseRibbon(
      windowStart: DateTime.utc(2026, 6, 1),
      windowEnd: DateTime.utc(2026, 6, 7),
      resolver: (_) => const PhaseUnknown(),
    )));
    await tester.pumpAndSettle();
    expect(find.text('menses'), findsOneWidget);
    expect(find.text('follicular'), findsOneWidget);
    expect(find.text('ovulatory'), findsOneWidget);
    expect(find.text('luteal'), findsOneWidget);
  });

  testWidgets('mix of confirmed/predicted/unknown renders without crashing', (tester) async {
    await tester.pumpWidget(_wrap(PhaseRibbon(
      windowStart: DateTime.utc(2026, 6, 1),
      windowEnd: DateTime.utc(2026, 6, 7),
      resolver: (day) {
        if (day.day.isEven) return const PhaseConfirmed(CyclePhase.follicular, 6);
        if (day.day == 1) return const PhasePredicted(CyclePhase.menses, 1);
        return const PhaseUnknown();
      },
    )));
    await tester.pumpAndSettle();
    // Just verify cells exist (visual content not asserted)
    expect(
      find.byWidgetPredicate((w) => w is SizedBox && (w.key?.toString().contains('phase-cell-') ?? false)),
      findsNWidgets(8),
    );
  });
}
