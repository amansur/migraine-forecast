import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/ui/onboarding/onboarding_screen.dart';
import 'package:migraine_forecast/ui/shared/mascot/mascot_widget.dart';

void main() {
  testWidgets('onboarding shows an 80px mascot cameo', (tester) async {
    await tester.pumpWidget(const ProviderScope(
      child: MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: MaterialApp(home: OnboardingScreen()),
      ),
    ));
    await tester.pump();

    expect(find.byType(MascotWidget), findsOneWidget);
    final mascot = tester.widget<MascotWidget>(find.byType(MascotWidget));
    expect(mascot.size, 80);
    expect(mascot.band, RiskBand.low);
  });
}
