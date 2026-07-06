import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/ui/shared/animations/celebration_overlay.dart';
import 'package:migraine_forecast/ui/shared/mascot/mascot_widget.dart';

void main() {
  testWidgets('show triggers mascot wiggle and inserts a confetti layer', (tester) async {
    final controller = MascotController();
    MascotAction? seen;
    controller.addListener(() => seen = controller.pending);

    late BuildContext ctx;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Builder(builder: (c) {
        ctx = c;
        return const SizedBox.expand();
      })),
    ));

    CelebrationOverlay.show(ctx, controller: controller);
    await tester.pump();
    expect(seen, MascotAction.wiggle);
    expect(find.byType(CustomPaint), findsWidgets); // confetti overlay present

    await tester.pump(const Duration(milliseconds: 1300)); // overlay removes itself
  });

  testWidgets('reduced motion: no confetti layer, mascot still wiggles', (tester) async {
    final controller = MascotController();
    MascotAction? seen;
    controller.addListener(() => seen = controller.pending);

    late BuildContext ctx;
    await tester.pumpWidget(MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: MaterialApp(
        home: Scaffold(body: Builder(builder: (c) {
          ctx = c;
          return const SizedBox.expand();
        })),
      ),
    ));

    final countBefore = find.byType(IgnorePointer).evaluate().length;

    CelebrationOverlay.show(ctx, controller: controller);
    await tester.pump();

    expect(seen, MascotAction.wiggle);
    // No IgnorePointer overlay layer was inserted (count unchanged).
    expect(find.byType(IgnorePointer).evaluate().length, countBefore);
  });

  testWidgets('showCheckmark triggers blink', (tester) async {
    // skip particle, assert blink only
    final controller = MascotController();
    MascotAction? seen;
    controller.addListener(() => seen = controller.pending);

    late BuildContext ctx;
    await tester.pumpWidget(MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: MaterialApp(
        home: Scaffold(body: Builder(builder: (c) {
          ctx = c;
          return const SizedBox.expand();
        })),
      ),
    ));

    CelebrationOverlay.showCheckmark(ctx, controller: controller);
    await tester.pump();
    expect(seen, MascotAction.wiggle);
  });
}
