import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:migraine_forecast/state/risk_assessment_provider.dart';
import 'package:migraine_forecast/state/settings_provider.dart';
import 'package:migraine_forecast/ui/today/tomorrow_detail_screen.dart';

class _FakeTomorrowNotifier extends TomorrowRiskAssessmentNotifier {
  final RiskAssessment fixed;
  _FakeTomorrowNotifier(this.fixed);
  @override
  Future<RiskAssessment> build() async => fixed;
  @override
  Future<void> refresh() async {
    state = AsyncValue.data(fixed);
  }
}

void main() {
  testWidgets('renders future-tense Why chips for tomorrow', (tester) async {
    final tomorrow = RiskAssessment(
      score: 62,
      band: RiskBand.high,
      contributors: [
        TriggerSignal(
          moduleId: 'pressure_drop',
          weight: 18,
          confidence: 1.0,
          explanation: 'Pressure dropping 6.1 hPa over next 24h',
        ),
        TriggerSignal(
          moduleId: 'humidity',
          weight: 6,
          confidence: 1.0,
          explanation: 'Humidity reaching 85%, rising 35% over next 24h',
        ),
      ],
      computedAt: DateTime.utc(2026, 6, 12, 6),
      configVersion: 1,
      targetDate: DateTime.utc(2026, 6, 13),
      horizon: RiskHorizon.tomorrow,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tomorrowRiskAssessmentProvider.overrideWith(() => _FakeTomorrowNotifier(tomorrow)),
          riskDisplayModeProvider.overrideWith((ref) async => RiskDisplayMode.numeric),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(routes: [
            GoRoute(path: '/', builder: (_, __) => const TomorrowDetailScreen()),
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tomorrow'), findsOneWidget);
    expect(find.text('62'), findsOneWidget);
    expect(find.text('Pressure dropping 6.1 hPa over next 24h'), findsOneWidget);
    expect(find.text('Humidity reaching 85%, rising 35% over next 24h'), findsOneWidget);
    // No log button — Tomorrow detail is read-only.
    expect(find.text('Log a migraine'), findsNothing);
  });
}
