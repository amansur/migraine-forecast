import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/app/theme.dart';
import 'package:migraine_forecast/ui/shared/mascot/mascot_character.dart';
import 'package:migraine_forecast/ui/shared/mascot/mascot_widget.dart';

void main() {
  setUpAll(() async {
    try {
      await precacheMascots(); // warm the flutter_svg cache so goldens are stable
    } catch (_) {
      // May fail in headless test environment (no asset codec); goldens still run.
    }
  });

  for (final band in RiskBand.values) {
    testWidgets('kitty_${band.name}', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            theme: buildLightTheme(),
            home: Scaffold(
              body: Center(
                child: RepaintBoundary(
                  child: SizedBox(
                    width: 200,
                    height: 200,
                    child: MascotWidget(
                      band: band,
                      character: MascotCharacter.kitty,
                      size: 200,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(RepaintBoundary).first,
        matchesGoldenFile('goldens/kitty_${band.name}.png'),
      );
    });
  }
}
