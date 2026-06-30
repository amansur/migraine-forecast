import 'dart:io' show Platform;

import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/app/theme.dart';
import 'package:migraine_forecast/ui/shared/mascot/blob_painter.dart';
import 'package:migraine_forecast/ui/shared/mascot/mascot_accessories.dart';

void main() {
  for (final band in RiskBand.values) {
    testWidgets('mascot_${band.name}', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            theme: buildLightTheme(),
            home: Scaffold(
              body: Center(
                child: RepaintBoundary(
                  child: SizedBox(
                    width: 200,
                    height: 200,
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
          ),
        ),
      );
      await expectLater(
        find.byType(RepaintBoundary).first,
        matchesGoldenFile('goldens/mascot_${band.name}.png'),
      );
    }, skip: !Platform.isLinux); // goldens are Linux-canonical (see CI)
  }
}
