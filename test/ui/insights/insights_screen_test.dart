import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:migraine_forecast/state/correlation_provider.dart';
import 'package:migraine_forecast/state/insights_eligibility_provider.dart';
import 'package:migraine_forecast/state/providers.dart';
import 'package:migraine_forecast/state/suggestions_provider.dart';
import 'package:migraine_forecast/ui/insights/insights_screen.dart';

void main() {
  testWidgets('shows calibrating state when ineligible', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          insightsEligibleProvider.overrideWith((ref) => Stream.value(false)),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(routes: [
            GoRoute(path: '/', builder: (_, __) => const InsightsScreen()),
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Calibrating'), findsOneWidget);
    expect(find.textContaining('first logged migraine'), findsOneWidget);
  });

  testWidgets('tapping a day shows the detail sheet', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          insightsEligibleProvider.overrideWith((ref) => Stream.value(true)),
          recentAttacksProvider.overrideWith((ref) => Stream.value([])),
          correlationResultsProvider.overrideWith((ref) async => []),
          suggestionsProvider.overrideWith((ref) async => []),
          dayAssessmentProvider.overrideWith((ref, date) async => null),
          dayAttacksProvider.overrideWith((ref, date) => Stream.value([])),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(routes: [
            GoRoute(path: '/', builder: (_, __) => const InsightsScreen()),
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Find a day in the heatmap (they are InkWells)
    final dayWidget = find.byType(InkWell).first;
    await tester.tap(dayWidget);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Risk Assessment'), findsOneWidget);
    expect(find.text('Logged Migraines'), findsOneWidget);
  });

  testWidgets('detail sheet shows "No end time recorded" when endedAt null and not inProgress',
      (tester) async {
    final attack = Attack(
      startedAt: DateTime.utc(2026, 6, 5, 12),
      endedAt: null,
      severity: 5,
      inProgress: false,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          insightsEligibleProvider.overrideWith((ref) => Stream.value(true)),
          recentAttacksProvider.overrideWith((ref) => Stream.value([attack])),
          correlationResultsProvider.overrideWith((ref) async => []),
          suggestionsProvider.overrideWith((ref) async => []),
          dayAssessmentProvider.overrideWith((ref, date) async => null),
          dayAttacksProvider.overrideWith((ref, date) => Stream.value([attack])),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(routes: [
            GoRoute(path: '/', builder: (_, __) => const InsightsScreen()),
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap a day to open the detail sheet
    final dayWidget = find.byType(InkWell).first;
    await tester.tap(dayWidget);
    await tester.pumpAndSettle();

    expect(find.textContaining('In progress'), findsNothing);
    expect(find.textContaining('No end time recorded'), findsOneWidget);
  });

  testWidgets('detail sheet shows "In progress" only when inProgress=true', (tester) async {
    final attack = Attack(
      startedAt: DateTime.utc(2026, 6, 5, 12),
      endedAt: null,
      severity: 5,
      inProgress: true,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          insightsEligibleProvider.overrideWith((ref) => Stream.value(true)),
          recentAttacksProvider.overrideWith((ref) => Stream.value([attack])),
          correlationResultsProvider.overrideWith((ref) async => []),
          suggestionsProvider.overrideWith((ref) async => []),
          dayAssessmentProvider.overrideWith((ref, date) async => null),
          dayAttacksProvider.overrideWith((ref, date) => Stream.value([attack])),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(routes: [
            GoRoute(path: '/', builder: (_, __) => const InsightsScreen()),
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap a day to open the detail sheet
    final dayWidget = find.byType(InkWell).first;
    await tester.tap(dayWidget);
    await tester.pumpAndSettle();

    expect(find.textContaining('In progress'), findsOneWidget);
  });
}
