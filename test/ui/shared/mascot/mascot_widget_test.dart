import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/app/theme.dart';
import 'package:migraine_forecast/state/mascot_character.dart';
import 'package:migraine_forecast/ui/shared/mascot/mascot_widget.dart';

Widget reducedMotion(Widget child) => MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: child,
    );

Widget host(RiskBand band, {MascotController? controller, MascotCharacter character = MascotCharacter.kitty}) {
  return MaterialApp(
    theme: buildLightTheme(),
    home: Scaffold(
      body: Center(
        child: reducedMotion(MascotWidget(band: band, controller: controller, character: character)),
      ),
    ),
  );
}

void main() {
  testWidgets('renders the SVG body + face for each band', (tester) async {
    for (final band in RiskBand.values) {
      await tester.pumpWidget(host(band));
      await tester.pump();
      expect(find.byType(MascotWidget), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets); // face painter present
    }
  });

  testWidgets('exposes band, size and character', (tester) async {
    await tester.pumpWidget(host(RiskBand.high, character: MascotCharacter.bee));
    final w = tester.widget<MascotWidget>(find.byType(MascotWidget));
    expect(w.band, RiskBand.high);
    expect(w.character, MascotCharacter.bee);
    expect(w.size, 160);
  });

  testWidgets('idle loop does not hang pumpAndSettle under reduced motion', (tester) async {
    await tester.pumpWidget(host(RiskBand.low));
    await tester.pumpAndSettle();
    expect(find.byType(MascotWidget), findsOneWidget);
  });

  testWidgets('controller.blink runs and acks', (tester) async {
    final controller = MascotController();
    await tester.pumpWidget(host(RiskBand.low, controller: controller));
    controller.blink();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(controller.pending, isNull);
  });

  testWidgets('onWiggle fires when wiggle completes', (tester) async {
    var wiggled = false;
    final controller = MascotController();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: reducedMotion(MascotWidget(
          band: RiskBand.low,
          controller: controller,
          onWiggle: () => wiggled = true,
        )),
      ),
    ));
    controller.wiggle();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(wiggled, isTrue);
  });
}
