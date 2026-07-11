import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/state/correlation_provider.dart';
import 'package:migraine_forecast/ui/insights/interaction_card.dart';

InteractionResult _interaction(String a, String b) {
  final fired = WilsonInterval.compute(successes: 13, trials: 20);
  final notFired = WilsonInterval.compute(successes: 16, trials: 140);
  return InteractionResult(
    idA: a,
    idB: b,
    pair: CorrelationResult(
      exposureId: '$a+$b',
      classification: CorrelationClassification.personalHit,
      firedAttackRate: fired,
      notFiredAttackRate: notFired,
      lift: WilsonInterval.differenceLift(fired, notFired),
      totalAttacks: 29,
    ),
    singleLiftA: 0.22,
    singleLiftB: 0.22,
  );
}

void main() {
  Widget host(List<InteractionResult> results) => ProviderScope(
        overrides: [
          interactionResultsProvider.overrideWith((ref) async => results),
        ],
        child: const MaterialApp(home: Scaffold(body: InteractionCard())),
      );

  testWidgets('renders pair labels with hedged copy', (tester) async {
    await tester.pumpWidget(host([_interaction('alcohol', 'sleep_deficit')]));
    await tester.pumpAndSettle();
    expect(find.text('Trigger combinations'), findsOneWidget);
    expect(find.text('Alcohol + Sleep'), findsOneWidget);
    expect(find.textContaining('65% of the 20 days'), findsOneWidget);
    expect(find.textContaining('not proof'), findsOneWidget);
  });

  testWidgets('hidden when no qualifying pairs', (tester) async {
    await tester.pumpWidget(host(const []));
    await tester.pumpAndSettle();
    expect(find.text('Trigger combinations'), findsNothing);
  });
}
