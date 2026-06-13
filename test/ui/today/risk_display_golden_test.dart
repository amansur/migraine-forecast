import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/app/theme.dart';
import 'package:migraine_forecast/state/settings_provider.dart';
import 'package:migraine_forecast/ui/today/risk_display.dart';

RiskAssessment _ass(int score, RiskBand band) => RiskAssessment(
      score: score,
      band: band,
      contributors: const [],
      computedAt: DateTime.utc(2026, 6, 10),
      configVersion: 1,
      targetDate: DateTime.utc(2026, 6, 10),
      horizon: RiskHorizon.today,
    );

void main() {
  for (final entry in {
    'low': _ass(15, RiskBand.low),
    'moderate': _ass(35, RiskBand.moderate),
    'high': _ass(58, RiskBand.high),
    'very_high': _ass(85, RiskBand.veryHigh),
  }.entries) {
    testWidgets('gauge_${entry.key}', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: buildLightTheme(),
        home: Scaffold(
          body: Center(
            child: RiskDisplay(assessment: entry.value, mode: RiskDisplayMode.gauge),
          ),
        ),
      ));
      await expectLater(
        find.byType(RiskDisplay),
        matchesGoldenFile('goldens/gauge_${entry.key}.png'),
      );
    });
  }
}
