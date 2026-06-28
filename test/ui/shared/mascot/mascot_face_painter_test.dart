import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/ui/shared/mascot/mascot_face_painter.dart';

void main() {
  for (final band in RiskBand.values) {
    testWidgets('MascotFacePainter paints for $band', (tester) async {
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: SizedBox(width: 160, height: 160),
          ),
        ),
      );
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: SizedBox(
                width: 160,
                height: 160,
                child: CustomPaint(
                  painter: MascotFacePainter(face: MascotFace.forBand(band)),
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.byType(CustomPaint), findsWidgets);
    });
  }

  test('MascotFace.lerp switches sweat at midpoint', () {
    final calm = MascotFace.forBand(RiskBand.low); // sweat false
    final worried = MascotFace.forBand(RiskBand.high); // sweat true
    expect(MascotFace.lerp(calm, worried, 0.49).sweat, isFalse);
    expect(MascotFace.lerp(calm, worried, 0.51).sweat, isTrue);
  });

  test('MascotFacePainter.shouldRepaint reacts to eyeOpen change', () {
    final open = MascotFacePainter(face: MascotFace.forBand(RiskBand.low));
    final closed = MascotFacePainter(face: MascotFace.forBand(RiskBand.low), eyeOpen: 0.0);
    expect(closed.shouldRepaint(open), isTrue);
  });
}
