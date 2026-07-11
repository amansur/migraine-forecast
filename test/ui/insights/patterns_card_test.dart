import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/state/insights_eligibility_provider.dart';
import 'package:migraine_forecast/ui/insights/patterns_card.dart';

void main() {
  Widget host(List<Attack> attacks) => ProviderScope(
        overrides: [
          recentAttacksProvider.overrideWith((ref) => Stream.value(attacks)),
        ],
        child: const MaterialApp(home: Scaffold(body: PatternsCard())),
      );

  testWidgets('shows streaks and time-of-day counts', (tester) async {
    // Local times so the card's toLocal() is a no-op.
    final attacks = [
      Attack(startedAt: DateTime(2026, 7, 1, 7), severity: 5), // morning
      Attack(startedAt: DateTime(2026, 7, 2, 13), severity: 4), // afternoon
    ];
    await tester.pumpWidget(host(attacks));
    await tester.pumpAndSettle();
    expect(find.text('Patterns'), findsOneWidget);
    expect(find.textContaining('days attack-free'), findsOneWidget);
    expect(find.text('Morning'), findsOneWidget);
    // Two single-count buckets (morning, afternoon) and two zero buckets.
    expect(find.text('1'), findsNWidgets(2));
    expect(find.text('0'), findsNWidgets(2));
  });

  testWidgets('renders nothing without attacks', (tester) async {
    await tester.pumpWidget(host(const []));
    await tester.pumpAndSettle();
    expect(find.text('Patterns'), findsNothing);
  });
}
