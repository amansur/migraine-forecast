import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:migraine_forecast/data/database.dart'
    hide Attack, JournalEntry, WeatherSnapshot, RiskAssessment;
import 'package:migraine_forecast/state/checkin_provider.dart';
import 'package:migraine_forecast/state/providers.dart';
import 'package:migraine_forecast/ui/today/checkin_card.dart';

void main() {
  final day = DateTime.utc(2026, 7, 10);

  Widget host(AppDatabase db, {DateTime? prompt}) => ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          checkinPromptProvider.overrideWith((ref) async => prompt),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(routes: [
            GoRoute(
                path: '/',
                builder: (_, __) => const Scaffold(body: CheckinCard())),
            GoRoute(
                path: '/log',
                builder: (_, __) =>
                    const Scaffold(body: Text('log-screen-stub'))),
          ]),
        ),
      );

  testWidgets('hidden when there is nothing to ask', (tester) async {
    final db = AppDatabase.memory();
    addTearDown(db.close);
    await tester.pumpWidget(host(db));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('checkin-card')), findsNothing);
  });

  testWidgets('answering No records a negative check-in', (tester) async {
    final db = AppDatabase.memory();
    addTearDown(db.close);
    await tester.pumpWidget(host(db, prompt: day));
    await tester.pumpAndSettle();
    expect(find.text('Yesterday was a high-risk day'), findsOneWidget);

    await tester.tap(find.byKey(const Key('checkin-no')));
    await tester.pumpAndSettle();

    final rows = await db.select(db.dayCheckins).get();
    expect(rows, hasLength(1));
    expect(rows.single.day, day);
    expect(rows.single.hadAttack, isFalse);
  });

  testWidgets('answering Yes records a positive check-in', (tester) async {
    final db = AppDatabase.memory();
    addTearDown(db.close);
    await tester.pumpWidget(host(db, prompt: day));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('checkin-yes')));
    await tester.pumpAndSettle();

    final rows = await db.select(db.dayCheckins).get();
    expect(rows, hasLength(1));
    expect(rows.single.hadAttack, isTrue);
  });
}
