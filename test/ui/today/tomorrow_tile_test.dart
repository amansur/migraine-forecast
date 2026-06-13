import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:migraine_forecast/state/risk_assessment_provider.dart';
import 'package:migraine_forecast/ui/today/tomorrow_tile.dart';

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
  testWidgets('tap pushes /tomorrow', (tester) async {
    final tomorrow = RiskAssessment(
      score: 40,
      band: RiskBand.moderate,
      contributors: const [],
      computedAt: DateTime.utc(2026, 6, 12, 6),
      configVersion: 1,
      targetDate: DateTime.utc(2026, 6, 13),
      horizon: RiskHorizon.tomorrow,
    );

    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => const Scaffold(body: TomorrowTile())),
      GoRoute(path: '/tomorrow', builder: (_, __) => const Scaffold(body: Text('TOMORROW_DETAIL'))),
    ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tomorrowRiskAssessmentProvider.overrideWith(() => _FakeTomorrowNotifier(tomorrow)),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    expect(find.text('TOMORROW_DETAIL'), findsNothing);

    await tester.tap(find.byType(TomorrowTile));
    await tester.pumpAndSettle();

    expect(find.text('TOMORROW_DETAIL'), findsOneWidget);
  });
}
