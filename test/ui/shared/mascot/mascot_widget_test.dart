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

  /// Finds band+offset that displays [stem] today (pools are date-seeded).
  (RiskBand, int) bandOffsetFor(String stem) {
    for (final band in RiskBand.values) {
      final pool = kMascotPool[band]!;
      for (var i = 0; i < pool.length; i++) {
        if (mascotAssetFor(band, offset: i) == 'assets/mascots/$stem.png') {
          return (band, i);
        }
      }
    }
    fail('no band/offset shows $stem');
  }

  Matrix4 netTransform(WidgetTester tester) {
    var m = Matrix4.identity();
    final imageEl = tester.element(find.byType(Image));
    imageEl.visitAncestorElements((el) {
      final w = el.widget;
      if (w is Transform) m = w.transform.clone()..multiply(m);
      return w is! MascotWidget;
    });
    return m;
  }

  group('per-mascot idle styles', () {
    Future<void> pumpMascot(WidgetTester tester, String stem,
        {bool reduce = false}) async {
      final (band, offset) = bandOffsetFor(stem);
      await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduce),
          child: Scaffold(
            body: Center(
              child: MascotWidget(band: band, size: 80, cycleOffset: offset),
            ),
          ),
        ),
      ));
      await tester.pump();
      // Mid idle phase (idle period is 2600 ms).
      await tester.pump(const Duration(milliseconds: 1300));
    }

    testWidgets('hover translates the mascot', (tester) async {
      await pumpMascot(tester, 'butterfly');
      final m = netTransform(tester);
      expect(m.getTranslation().length, greaterThan(0.5));
    });

    testWidgets('drift translates the mascot horizontally', (tester) async {
      await pumpMascot(tester, 'sleepy_cloud');
      final m = netTransform(tester);
      expect(m.getTranslation().x.abs() + m.getTranslation().y.abs(),
          greaterThan(0.5));
    });

    testWidgets('sway rotates the mascot', (tester) async {
      await pumpMascot(tester, 'sprout');
      final m = netTransform(tester);
      // Rotation shows up as a nonzero off-diagonal term.
      expect(m.entry(0, 1).abs() + m.entry(1, 0).abs(), greaterThan(0.001));
    });

    testWidgets('still does not translate or rotate', (tester) async {
      await pumpMascot(tester, 'snail');
      final m = netTransform(tester);
      expect(m.getTranslation().length, lessThan(0.01));
      expect(m.entry(0, 1).abs() + m.entry(1, 0).abs(), lessThan(0.0001));
    });

    testWidgets('bounce translates the mascot vertically', (tester) async {
      await pumpMascot(tester, 'cat');
      final m = netTransform(tester);
      expect(m.getTranslation().y.abs(), greaterThan(0.5));
    });

    testWidgets('reduced motion: idle is identity for every style',
        (tester) async {
      for (final stem in ['butterfly', 'sleepy_cloud', 'sprout', 'snail', 'cat']) {
        await pumpMascot(tester, stem, reduce: true);
        final m = netTransform(tester);
        expect(m.isIdentity(), isTrue, reason: stem);
      }
    });
  });
}
