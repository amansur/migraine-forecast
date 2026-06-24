import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/app/theme.dart';
import 'package:migraine_forecast/ui/shared/mascot/blob_painter.dart';
import 'package:migraine_forecast/ui/shared/mascot/mascot_accessories.dart';

void main() {
  for (final band in RiskBand.values) {
    testWidgets('BlobPainter + accessories paint for $band', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: SizedBox(
                width: 160,
                height: 160,
                child: CustomPaint(
                  painter: BlobPainter(
                    shape: BlobShape.forBand(band),
                    color: colorForBand(band.name),
                    face: MascotFace.forBand(band),
                  ),
                  foregroundPainter: MascotAccessoriesPainter(
                    band: band,
                    color: colorForBand(band.name),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.byType(CustomPaint), findsWidgets);
    });
  }

  test('BlobShape.lerp interpolates endpoints', () {
    final a = BlobShape.forBand(RiskBand.low);
    final b = BlobShape.forBand(RiskBand.veryHigh);
    final mid = BlobShape.lerp(a, b, 0.5);
    expect(mid.topBulge, closeTo((a.topBulge + b.topBulge) / 2, 1e-9));
  });

  test('MascotFace.lerp switches sweat at midpoint', () {
    final calm = MascotFace.forBand(RiskBand.low); // sweat false
    final worried = MascotFace.forBand(RiskBand.high); // sweat true
    expect(MascotFace.lerp(calm, worried, 0.49).sweat, isFalse);
    expect(MascotFace.lerp(calm, worried, 0.51).sweat, isTrue);
  });

  test('BlobPainter.shouldRepaint reacts to squish change', () {
    final base = BlobPainter(
      shape: BlobShape.forBand(RiskBand.low),
      color: colorForBand('low'),
      face: MascotFace.forBand(RiskBand.low),
    );
    final squished = BlobPainter(
      shape: BlobShape.forBand(RiskBand.low),
      color: colorForBand('low'),
      face: MascotFace.forBand(RiskBand.low),
      squish: 0.3,
    );
    expect(squished.shouldRepaint(base), isTrue);
  });
}
