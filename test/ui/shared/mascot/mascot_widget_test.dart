import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/app/theme.dart';
import 'package:migraine_forecast/ui/shared/mascot/mascot_accessories.dart';
import 'package:migraine_forecast/ui/shared/mascot/mascot_widget.dart';

MascotAccessoriesPainter _accessories(WidgetTester tester) {
  final cp = tester.widget<CustomPaint>(
    find.descendant(of: find.byType(MascotWidget), matching: find.byType(CustomPaint)).first,
  );
  return cp.foregroundPainter! as MascotAccessoriesPainter;
}

/// Wraps [child] in a [MediaQuery] that reports reduced motion, so the widget
/// stops its idle loop and [pumpAndSettle] can complete without timing out.
Widget reducedMotion(Widget child) => MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: child,
    );

Widget host(RiskBand band, {MascotController? controller, bool reduced = false}) {
  Widget mascot = MascotWidget(band: band, controller: controller);
  if (reduced) mascot = reducedMotion(mascot);
  return MaterialApp(
    theme: buildLightTheme(),
    home: Scaffold(body: Center(child: mascot)),
  );
}

void main() {
  for (final band in RiskBand.values) {
    testWidgets('renders correct accessory for $band', (tester) async {
      await tester.pumpWidget(host(band, reduced: true));
      await tester.pump();
      expect(_accessories(tester).band, band);
    });
  }

  testWidgets('idle loop does not hang pumpAndSettle under reduced motion', (tester) async {
    await tester.pumpWidget(host(RiskBand.low, reduced: true));
    await tester.pumpAndSettle(); // would time out if idle loop ran
    expect(find.byType(MascotWidget), findsOneWidget);
  });

  testWidgets('controller.blink runs and acks', (tester) async {
    final controller = MascotController();
    await tester.pumpWidget(host(RiskBand.low, controller: controller, reduced: true));
    controller.blink();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(controller.pending, isNull); // consumed
  });

  testWidgets('onWiggle fires when wiggle completes', (tester) async {
    var wiggled = false;
    final controller = MascotController();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MascotWidget(
          band: RiskBand.low,
          controller: controller,
          onWiggle: () => wiggled = true,
        ),
      ),
    ));
    controller.wiggle();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(wiggled, isTrue);
    // settle the idle loop so the test can end cleanly
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('band change updates accessory via didUpdateWidget', (tester) async {
    final notifier = ValueNotifier<RiskBand>(RiskBand.high);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ValueListenableBuilder<RiskBand>(
          valueListenable: notifier,
          builder: (_, b, __) => reducedMotion(MascotWidget(band: b)),
        ),
      ),
    ));
    await tester.pump();
    expect(_accessories(tester).band, RiskBand.high);
    notifier.value = RiskBand.low;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(_accessories(tester).band, RiskBand.low);
  });
}
