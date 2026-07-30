import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:migraine_forecast/state/location_display_provider.dart';
import 'package:migraine_forecast/state/risk_assessment_provider.dart';
import 'package:migraine_forecast/state/settings_provider.dart';
import 'package:migraine_forecast/ui/today/today_screen.dart';

class _FakeNotifier extends RiskAssessmentNotifier {
  final RiskAssessment fixed;
  _FakeNotifier(this.fixed);
  @override
  Future<RiskAssessment> build() async => fixed;
  @override
  Future<void> refresh() async {
    state = AsyncValue.data(fixed);
  }
}

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

RiskAssessment _ass() => RiskAssessment(
      score: 30,
      band: RiskBand.moderate,
      contributors: [
        TriggerSignal(
            moduleId: 'pressure_drop',
            weight: 10,
            confidence: 1.0,
            explanation: 'Pressure dropping'),
      ],
      computedAt: DateTime.utc(2026, 7, 20, 6),
      configVersion: 1,
      targetDate: DateTime.utc(2026, 7, 20),
      horizon: RiskHorizon.today,
    );

void main() {
  testWidgets('Today shows the current location name', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          riskAssessmentProvider.overrideWith(() => _FakeNotifier(_ass())),
          tomorrowRiskAssessmentProvider
              .overrideWith(() => _FakeTomorrowNotifier(_ass())),
          riskDisplayModeProvider
              .overrideWith((ref) async => RiskDisplayMode.numeric),
          effectiveLocationProvider.overrideWith((ref) async =>
              const LocationDisplay(
                  name: 'Oakland, California',
                  coords: '37.8044, -122.2712',
                  isAuto: true,
                  isSet: true)),
        ],
        child: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MaterialApp.router(
            routerConfig: GoRouter(routes: [
              GoRoute(path: '/', builder: (_, __) => const TodayScreen()),
              GoRoute(path: '/log', builder: (_, __) => const SizedBox()),
              GoRoute(path: '/settings', builder: (_, __) => const SizedBox()),
            ]),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Oakland, California'), findsOneWidget);
    expect(find.textContaining('Current location'), findsOneWidget);
    // Coordinates are visible to the user.
    expect(find.text('37.8044, -122.2712'), findsOneWidget);
  });
}
