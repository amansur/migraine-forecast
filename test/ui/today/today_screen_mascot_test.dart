import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:migraine_forecast/state/risk_assessment_provider.dart';
import 'package:migraine_forecast/ui/shared/mascot/mascot_widget.dart';
import 'package:migraine_forecast/ui/today/today_screen.dart';

class _FakeNotifier extends RiskAssessmentNotifier {
  final RiskAssessment fixed;
  _FakeNotifier(this.fixed);
  @override
  Future<RiskAssessment> build() async => fixed;
  @override
  Future<void> refresh() async => state = AsyncValue.data(fixed);
}

class _FakeTomorrowNotifier extends TomorrowRiskAssessmentNotifier {
  final RiskAssessment fixed;
  _FakeTomorrowNotifier(this.fixed);
  @override
  Future<RiskAssessment> build() async => fixed;
  @override
  Future<void> refresh() async => state = AsyncValue.data(fixed);
}

RiskAssessment _ass(RiskBand band) => RiskAssessment(
      score: 58,
      band: band,
      contributors: const [],
      computedAt: DateTime.utc(2026, 6, 10, 6),
      configVersion: 1,
      targetDate: DateTime.utc(2026, 6, 10),
      horizon: RiskHorizon.today,
    );

void main() {
  testWidgets('mascot appears above the risk display with current band', (tester) async {
    final today = _ass(RiskBand.high);
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => const TodayScreen()),
      GoRoute(path: '/settings', builder: (_, __) => const Scaffold(body: Text('SETTINGS'))),
    ]);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        riskAssessmentProvider.overrideWith(() => _FakeNotifier(today)),
        tomorrowRiskAssessmentProvider.overrideWith(() => _FakeTomorrowNotifier(_ass(RiskBand.moderate))),
      ],
      child: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: MaterialApp.router(routerConfig: router),
      ),
    ));
    await tester.pump();

    expect(find.byType(MascotWidget), findsOneWidget);
    final mascot = tester.widget<MascotWidget>(find.byType(MascotWidget));
    expect(mascot.band, RiskBand.high);
  });
}
