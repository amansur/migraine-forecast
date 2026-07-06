import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/ui/shared/mascot/mascot_widget.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: Center(child: child)));

void main() {
  testWidgets('renders an Image for every band', (tester) async {
    for (final band in RiskBand.values) {
      await tester.pumpWidget(_host(MascotWidget(band: band, size: 80)));
      await tester.pump();
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
    await tester.pump(const Duration(milliseconds: 600));
    expect(wiggled, isTrue);
  });
}
