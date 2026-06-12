import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:migraine_weatherr/state/insights_eligibility_provider.dart';
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
}
