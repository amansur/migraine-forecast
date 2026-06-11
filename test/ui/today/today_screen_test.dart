import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:migraine_weatherr/state/risk_assessment_provider.dart';
import 'package:migraine_weatherr/state/settings_provider.dart';
import 'package:migraine_weatherr/ui/today/today_screen.dart';

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

RiskAssessment _ass({int score = 58, RiskBand band = RiskBand.high, List<TriggerSignal> contributors = const []}) =>
    RiskAssessment(
      score: score,
      band: band,
      contributors: contributors,
      computedAt: DateTime.utc(2026, 6, 10, 6),
      configVersion: 1,
      targetDate: DateTime.utc(2026, 6, 10),
      horizon: RiskHorizon.today,
    );

void main() {
  testWidgets('renders score and contributors', (tester) async {
    final today = _ass(
      score: 58,
      contributors: [
        TriggerSignal(moduleId: 'pressure_drop', weight: 18, confidence: 1.0, explanation: 'Pressure dropping 7 hPa'),
        TriggerSignal(moduleId: 'sleep_deficit', weight: 10, confidence: 1.0, explanation: '4.5h sleep'),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          riskAssessmentProvider.overrideWith(() => _FakeNotifier(today)),
          tomorrowRiskAssessmentProvider.overrideWith(() => _FakeTomorrowNotifier(_ass(score: 30, band: RiskBand.moderate))),
          riskDisplayModeProvider.overrideWith((ref) async => RiskDisplayMode.numeric),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(routes: [
            GoRoute(path: '/', builder: (_, __) => const TodayScreen()),
            GoRoute(path: '/log', builder: (_, __) => const SizedBox()),
            GoRoute(path: '/settings', builder: (_, __) => const SizedBox()),
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('58'), findsOneWidget);
    expect(find.text('High'), findsOneWidget);
    expect(find.text('Pressure dropping 7 hPa'), findsOneWidget);
    expect(find.textContaining('Tomorrow'), findsOneWidget);
  });

  testWidgets('renders onboarding card for zero-confidence assessment', (tester) async {
    final ass = RiskAssessment(
      score: 0,
      band: RiskBand.low,
      contributors: [TriggerSignal.zero(moduleId: 'x', reason: 'no data')],
      computedAt: DateTime.utc(2026, 6, 10),
      configVersion: 1,
      targetDate: DateTime.utc(2026, 6, 10),
      horizon: RiskHorizon.today,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          riskAssessmentProvider.overrideWith(() => _FakeNotifier(ass)),
          tomorrowRiskAssessmentProvider.overrideWith(() => _FakeTomorrowNotifier(ass)),
          riskDisplayModeProvider.overrideWith((ref) async => RiskDisplayMode.gauge),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(routes: [
            GoRoute(path: '/', builder: (_, __) => const TodayScreen()),
            GoRoute(path: '/settings', builder: (_, __) => const SizedBox()),
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Set up your personal risk profile'), findsOneWidget);
  });
}
