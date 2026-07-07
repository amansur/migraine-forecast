import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/state/mascot_pool.dart';
import 'package:migraine_forecast/ui/shared/mascot/mascot_widget.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: Center(child: child)));

void main() {
  testWidgets('renders an Image for every band', (tester) async {
    for (final band in RiskBand.values) {
      await tester.pumpWidget(_host(MascotWidget(band: band, size: 80)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byType(Image), findsOneWidget, reason: '$band');
    }
  });

  testWidgets('wiggle action fires onWiggle', (tester) async {
    final controller = MascotController();
    var wiggled = false;
    await tester.pumpWidget(_host(MascotWidget(
      band: RiskBand.low,
      size: 80,
      controller: controller,
      onWiggle: () => wiggled = true,
    )));
    controller.wiggle();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(wiggled, isTrue);
    controller.dispose();
  });

  testWidgets('wave action completes without error', (tester) async {
    final controller = MascotController();
    await tester.pumpWidget(_host(MascotWidget(
      band: RiskBand.moderate,
      size: 80,
      controller: controller,
    )));
    controller.wave();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.takeException(), isNull);
    controller.dispose();
  });

  testWidgets('dropping to a lower band plays a wiggle', (tester) async {
    var wiggled = false;
    Widget build(RiskBand b) => _host(MascotWidget(
        band: b, size: 80, onWiggle: () => wiggled = true));
    await tester.pumpWidget(build(RiskBand.high));
    await tester.pump();
    await tester.pumpWidget(build(RiskBand.low));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump(const Duration(milliseconds: 600));
    expect(wiggled, isTrue);
  });

  testWidgets('cycleOffset changes the rendered asset within the band pool',
      (tester) async {
    final pool = kMascotPool[RiskBand.moderate]!;
    final seen = <String>{};
    for (var i = 0; i < pool.length; i++) {
      await tester.pumpWidget(_host(
          MascotWidget(band: RiskBand.moderate, size: 80, cycleOffset: i)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      final img = tester.widget<Image>(find.byType(Image));
      final asset = (img.image as AssetImage).assetName;
      expect(pool, contains(asset));
      seen.add(asset);
    }
    expect(seen.length, pool.length,
        reason: 'each offset shows a different pool member');
  });

  testWidgets(
      're-pin wiggle style on cycle: rebuild with new cycleOffset mid-flight '
      'completes without error and fires onWiggle', (tester) async {
    final controller = MascotController();
    var wiggled = false;

    Widget build(int offset) => _host(MascotWidget(
          band: RiskBand.low,
          size: 80,
          cycleOffset: offset,
          controller: controller,
          onWiggle: () => wiggled = true,
        ));

    // Initial render with offset 0.
    await tester.pumpWidget(build(0));
    await tester.pump();

    // Start a wiggle.
    controller.wiggle();
    await tester.pump(); // kick animation

    // Advance partway so the wiggle is in flight.
    await tester.pump(const Duration(milliseconds: 100));

    // Rebuild with a new cycleOffset while wiggle is still in flight — this
    // exercises the didUpdateWidget re-pin path.
    await tester.pumpWidget(build(1));
    await tester.pump();

    // Let the animation complete.
    await tester.pump(const Duration(milliseconds: 800));

    expect(tester.takeException(), isNull,
        reason: 'no exception after mid-flight cycleOffset change');
    expect(wiggled, isTrue, reason: 'onWiggle fires after re-pin');
    controller.dispose();
  });

  testWidgets('every wiggle style plays to completion and fires onWiggle',
      (tester) async {
    // Sweep every band x offset: collectively covers all pooled icons and
    // therefore all four WiggleStyles.
    for (final band in RiskBand.values) {
      final pool = kMascotPool[band]!;
      for (var i = 0; i < pool.length; i++) {
        final controller = MascotController();
        var wiggled = false;
        await tester.pumpWidget(_host(MascotWidget(
          band: band,
          size: 80,
          cycleOffset: i,
          controller: controller,
          onWiggle: () => wiggled = true,
        )));
        controller.wiggle();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 800));
        expect(tester.takeException(), isNull, reason: '$band offset $i');
        expect(wiggled, isTrue, reason: '$band offset $i');
        controller.dispose();
      }
    }
  });
}
