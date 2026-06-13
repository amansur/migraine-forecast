import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:migraine_weatherr/data/sources/journal_source.dart';
import 'package:migraine_weatherr/state/providers.dart';
import 'package:migraine_weatherr/state/risk_assessment_provider.dart';
import 'package:migraine_weatherr/state/settings_provider.dart';
import 'package:migraine_weatherr/ui/today/today_screen.dart';

class _FakeNotifier extends RiskAssessmentNotifier {
  final RiskAssessment fixed;
  _FakeNotifier(this.fixed);
  @override Future<RiskAssessment> build() async => fixed;
  @override Future<void> refresh() async { state = AsyncValue.data(fixed); }
}

class _FakeTomorrow extends TomorrowRiskAssessmentNotifier {
  final RiskAssessment fixed;
  _FakeTomorrow(this.fixed);
  @override Future<RiskAssessment> build() async => fixed;
  @override Future<void> refresh() async { state = AsyncValue.data(fixed); }
}

class _FakeJournal implements JournalSource {
  List<PeriodEvent> periods;
  final List<({DateTime startedAt, DateTime endedAt})> ends = [];
  _FakeJournal({this.periods = const []});

  @override Future<int> addAttack(Attack attack, {int? riskAssessmentId}) async => 1;
  @override Future<void> addEntry(JournalEntry entry) async {}
  @override Future<List<JournalEntry>> recentEntries(Duration window, {required DateTime now}) async => const [];
  @override Future<List<Attack>> recentAttacks(Duration window, {required DateTime now}) async => const [];
  @override Stream<List<Attack>> watchRecentAttacks(Duration window, {required DateTime now}) => Stream.value(const []);
  @override Future<void> deleteAttack(DateTime startedAt) async {}
  @override Future<void> updateAttack(Attack old, Attack updated) async {}

  @override Future<int> addPeriod(PeriodEvent period) async {
    periods = [period, ...periods];
    return 1;
  }
  @override Future<void> endPeriod(DateTime startedAt, DateTime endedAt) async {
    ends.add((startedAt: startedAt, endedAt: endedAt));
    periods = periods
        .map((p) => p.startedAt.isAtSameMomentAs(startedAt)
            ? PeriodEvent(startedAt: p.startedAt, endedAt: endedAt, baselineSeverity: p.baselineSeverity)
            : p)
        .toList();
  }
  @override Future<void> deletePeriod(DateTime startedAt) async {}
  @override Future<List<PeriodEvent>> recentPeriods(Duration window, {required DateTime now}) async => periods;
  @override Stream<List<PeriodEvent>> watchRecentPeriods(Duration window, {required DateTime now}) => Stream.value(periods);
  @override Future<void> upsertPeriodDaySeverity(PeriodDaySeverity override) async {}
  @override Future<List<PeriodDaySeverity>> recentPeriodDaySeverities(Duration window, {required DateTime now}) async => const [];
  @override Stream<List<PeriodDaySeverity>> watchRecentPeriodDaySeverities(Duration window, {required DateTime now}) => Stream.value(const []);
}

RiskAssessment _ass() => RiskAssessment(
      score: 30,
      band: RiskBand.moderate,
      contributors: const [],
      computedAt: DateTime.utc(2026, 6, 10, 6),
      configVersion: 1,
      targetDate: DateTime.utc(2026, 6, 10),
      horizon: RiskHorizon.today,
    );

Widget _wrap(_FakeJournal fake) {
  return ProviderScope(
    overrides: [
      journalSourceProvider.overrideWithValue(fake),
      riskAssessmentProvider.overrideWith(() => _FakeNotifier(_ass())),
      tomorrowRiskAssessmentProvider.overrideWith(() => _FakeTomorrow(_ass())),
      riskDisplayModeProvider.overrideWith((ref) async => RiskDisplayMode.numeric),
    ],
    child: MaterialApp.router(
      routerConfig: GoRouter(routes: [
        GoRoute(path: '/', builder: (_, __) => const TodayScreen()),
        GoRoute(path: '/log', builder: (_, __) => const SizedBox()),
        GoRoute(path: '/settings', builder: (_, __) => const SizedBox()),
      ]),
    ),
  );
}

void main() {
  testWidgets('label is "Log period" when no in-progress period', (tester) async {
    final fake = _FakeJournal();
    await tester.pumpWidget(_wrap(fake));
    await tester.pumpAndSettle();
    expect(find.text('Log period'), findsOneWidget);
    expect(find.text('End period'), findsNothing);
  });

  testWidgets('label is "End period" when most recent period is in progress', (tester) async {
    final fake = _FakeJournal(periods: [
      PeriodEvent(startedAt: DateTime.utc(2026, 6, 10), baselineSeverity: 5),
    ]);
    await tester.pumpWidget(_wrap(fake));
    await tester.pumpAndSettle();
    expect(find.text('End period'), findsOneWidget);
  });

  testWidgets('tapping "Log period" opens severity dialog and persists on confirm', (tester) async {
    final fake = _FakeJournal();
    await tester.pumpWidget(_wrap(fake));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('period-button')));
    await tester.pumpAndSettle();

    expect(find.text('Baseline severity'), findsOneWidget);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(fake.periods, hasLength(1));
    expect(fake.periods.first.baselineSeverity, 5);
    expect(fake.periods.first.endedAt, isNull);
  });

  testWidgets('tapping "End period" writes endedAt without opening dialog', (tester) async {
    final fake = _FakeJournal(periods: [
      PeriodEvent(startedAt: DateTime.utc(2026, 6, 10), baselineSeverity: 5),
    ]);
    await tester.pumpWidget(_wrap(fake));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('period-button')));
    await tester.pumpAndSettle();

    expect(find.text('Baseline severity'), findsNothing);
    expect(fake.ends, hasLength(1));
    expect(fake.ends.first.startedAt, DateTime.utc(2026, 6, 10));
  });
}
