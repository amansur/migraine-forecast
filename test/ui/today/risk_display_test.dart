import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_weatherr/state/settings_provider.dart';
import 'package:migraine_weatherr/ui/today/risk_display.dart';

RiskAssessment makeAss(int score, RiskBand band) => RiskAssessment(
      score: score,
      band: band,
      contributors: const [],
      computedAt: DateTime.utc(2026, 6, 10),
      configVersion: 1,
      targetDate: DateTime.utc(2026, 6, 10),
      horizon: RiskHorizon.today,
    );

void main() {
  for (final mode in RiskDisplayMode.values) {
    testWidgets('renders ${mode.name} for high band', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: RiskDisplay(assessment: makeAss(58, RiskBand.high), mode: mode),
        ),
      ));
      expect(find.text('High'), findsOneWidget);
    });
  }
}
