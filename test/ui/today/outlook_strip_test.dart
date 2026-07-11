import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:migraine_forecast/state/outlook_provider.dart';
import 'package:migraine_forecast/ui/today/outlook_strip.dart';
import 'package:migraine_forecast/ui/today/tomorrow_detail_screen.dart';

RiskAssessment _ass(DateTime target, int score, RiskBand band) => RiskAssessment(
      score: score,
      band: band,
      contributors: const [],
      computedAt: DateTime.utc(2026, 7, 11),
      configVersion: 2,
      targetDate: target,
      horizon: RiskHorizon.outlook,
    );

void main() {
  final base = DateTime.utc(2026, 7, 13); // d+2 for a Jul 11 "today"
  final days = [
    for (var i = 0; i < 5; i++)
      _ass(base.add(Duration(days: i)), 10 + i * 15,
          i >= 3 ? RiskBand.high : RiskBand.low),
  ];

  Widget host() => ProviderScope(
        overrides: [
          outlookProvider.overrideWith((ref) async => days),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(routes: [
            GoRoute(path: '/', builder: (_, __) => const Scaffold(body: OutlookStrip())),
            GoRoute(path: '/outlook-day', builder: (context, state) {
              return TomorrowDetailScreen(assessment: state.extra as RiskAssessment);
            }),
          ]),
        ),
      );

  testWidgets('shows five weekday chips with scores', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    for (var i = 0; i < 5; i++) {
      final d = base.add(Duration(days: i));
      expect(find.text(DateFormat.E().format(DateTime(d.year, d.month, d.day))),
          findsOneWidget);
      expect(find.text('${10 + i * 15}'), findsOneWidget);
    }
  });

  testWidgets('tapping a chip opens the day detail titled with the weekday',
      (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('outlook-2026-07-13')));
    await tester.pumpAndSettle();
    // 2026-07-13 is a Monday.
    expect(find.text('Monday'), findsOneWidget);
  });
}
