import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/state/correlation_provider.dart';
import 'package:migraine_forecast/ui/insights/weekday_card.dart';

CorrelationResult _result(String id,
    {required int firedWithAttack,
    required int firedTotal,
    CorrelationClassification classification =
        CorrelationClassification.inconclusive}) {
  final fired =
      WilsonInterval.compute(successes: firedWithAttack, trials: firedTotal);
  final notFired = WilsonInterval.compute(successes: 2, trials: 48);
  return CorrelationResult(
    exposureId: id,
    classification: classification,
    firedAttackRate: fired,
    notFiredAttackRate: notFired,
    lift: WilsonInterval.differenceLift(fired, notFired),
    totalAttacks: firedWithAttack + 2,
  );
}

void main() {
  Widget host(List<CorrelationResult> results) => ProviderScope(
        overrides: [
          weekdayResultsProvider.overrideWith((ref) async => results),
        ],
        child: const MaterialApp(home: Scaffold(body: WeekdayCard())),
      );

  testWidgets('shows seven rows and flags the personal-hit weekday', (tester) async {
    final results = [
      _result('weekday_1',
          firedWithAttack: 5,
          firedTotal: 8,
          classification: CorrelationClassification.personalHit),
      for (var wd = 2; wd <= 7; wd++)
        _result('weekday_$wd', firedWithAttack: 0, firedTotal: 8),
    ];
    await tester.pumpWidget(host(results));
    await tester.pumpAndSettle();
    expect(find.text('Attacks by weekday'), findsOneWidget);
    expect(find.text('Mon'), findsOneWidget);
    expect(find.text('Sun'), findsOneWidget);
    expect(find.text('pattern'), findsOneWidget);
  });

  testWidgets('hidden while weekdays lack observations', (tester) async {
    final results = [
      for (var wd = 1; wd <= 7; wd++)
        _result('weekday_$wd', firedWithAttack: 0, firedTotal: 2),
    ];
    await tester.pumpWidget(host(results));
    await tester.pumpAndSettle();
    expect(find.text('Attacks by weekday'), findsNothing);
  });
}
