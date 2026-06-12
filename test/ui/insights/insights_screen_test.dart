import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:migraine_weatherr/state/correlation_provider.dart';
import 'package:migraine_weatherr/state/insights_eligibility_provider.dart';
import 'package:migraine_weatherr/state/providers.dart';
import 'package:migraine_weatherr/state/suggestions_provider.dart';
import 'package:migraine_weatherr/ui/insights/insights_screen.dart';

void main() {
  testWidgets('shows calibrating state when ineligible', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          insightsEligibleProvider.overrideWith((ref) => Stream.value(false)),
          attackCountProvider.overrideWith((ref) => Stream.value(1)),
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
    expect(find.textContaining('logged 1 so far'), findsOneWidget);
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
}
