import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/state/calibration_provider.dart';
import 'package:migraine_forecast/ui/insights/calibration_card.dart';

void main() {
  Widget host(CalibrationView view) => ProviderScope(
        overrides: [calibrationReportProvider.overrideWith((ref) async => view)],
        child: const MaterialApp(home: Scaffold(body: CalibrationCard())),
      );

  testWidgets('shows per-band observed rates and day counts', (tester) async {
    final report = CalibrationReport(
      bands: [
        BandCalibration(
            band: RiskBand.low,
            attackRate: WilsonInterval.compute(successes: 1, trials: 20),
            days: 20),
        BandCalibration(
            band: RiskBand.high,
            attackRate: WilsonInterval.compute(successes: 4, trials: 10),
            days: 10),
      ],
      brierScore: 0.12,
      scoredDays: 30,
    );
    await tester.pumpWidget(host((report: report, usedBackfilled: false)));
    await tester.pumpAndSettle();
    expect(find.text('Forecast accuracy'), findsOneWidget);
    expect(find.textContaining('40% ('), findsOneWidget); // high-band rate + CI
    expect(find.textContaining('· 10d'), findsOneWidget);
    expect(find.textContaining('5% ('), findsOneWidget); // low-band rate + CI
    expect(find.textContaining('· 20d'), findsOneWidget);
    expect(find.textContaining('30 days'), findsOneWidget);
    expect(find.textContaining('Brier score 0.12'), findsOneWidget);
  });

  testWidgets('flags when backfilled days were included', (tester) async {
    final report = CalibrationReport(
      bands: [
        BandCalibration(
            band: RiskBand.moderate,
            attackRate: WilsonInterval.compute(successes: 1, trials: 5),
            days: 5),
      ],
      brierScore: 0.2,
      scoredDays: 5,
    );
    await tester.pumpWidget(host((report: report, usedBackfilled: true)));
    await tester.pumpAndSettle();
    expect(find.textContaining('reconstructed'), findsOneWidget);
  });

  testWidgets('renders nothing with no scored days', (tester) async {
    const report = CalibrationReport(bands: [], brierScore: null, scoredDays: 0);
    await tester.pumpWidget(host((report: report, usedBackfilled: true)));
    await tester.pumpAndSettle();
    expect(find.text('Forecast accuracy'), findsNothing);
  });
}
