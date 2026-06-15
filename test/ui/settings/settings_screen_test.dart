import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:migraine_forecast/data/context_builder.dart';
import 'package:migraine_forecast/data/sources/journal_source.dart';
import 'package:migraine_forecast/state/providers.dart';
import 'package:migraine_forecast/state/settings_provider.dart';
import 'package:migraine_forecast/ui/settings/settings_screen.dart';

class _MemFlagsRepo implements UserTriggerFlagsRepo {
  UserTriggerFlags _f = const UserTriggerFlags(flaggedModuleIds: {'stress'});
  @override Future<UserTriggerFlags> load() async => _f;
  @override Future<void> save(UserTriggerFlags flags) async => _f = flags;
}

class _FakeJournal implements JournalSource {
  List<PeriodEvent> periods;
  final List<PeriodEvent> addedPeriods = [];
  final List<DateTime> deletedStarts = [];
  final List<({DateTime startedAt, DateTime endedAt})> ends = [];
  _FakeJournal({this.periods = const []});

  @override Future<int> addAttack(Attack attack, {int? riskAssessmentId}) async => 1;
  @override Future<void> addEntry(JournalEntry entry) async {}
  @override Future<void> updateEntry(JournalEntry entry) async {}
  @override Future<void> deleteEntry(int id) async {}
  @override Future<List<JournalEntry>> recentEntries(Duration window, {required DateTime now}) async => const [];
  @override Stream<List<JournalEntry>> watchRecentEntries(Duration window, {required DateTime now}) => Stream.value(const []);
  @override Future<List<Attack>> recentAttacks(Duration window, {required DateTime now}) async => const [];
  @override Stream<List<Attack>> watchRecentAttacks(Duration window, {required DateTime now}) => Stream.value(const []);
  @override Future<void> deleteAttack(DateTime startedAt) async {}
  @override Future<void> updateAttack(Attack old, Attack updated) async {}

  @override Future<int> addPeriod(PeriodEvent period) async {
    addedPeriods.add(period);
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
  @override Future<void> deletePeriod(DateTime startedAt) async {
    deletedStarts.add(startedAt);
    periods = periods.where((p) => !p.startedAt.isAtSameMomentAs(startedAt)).toList();
  }
  @override Future<List<PeriodEvent>> recentPeriods(Duration window, {required DateTime now}) async => periods;
  @override Stream<List<PeriodEvent>> watchRecentPeriods(Duration window, {required DateTime now}) => Stream.value(periods);
  @override Future<void> upsertPeriodDaySeverity(PeriodDaySeverity override) async {}
  @override Future<List<PeriodDaySeverity>> recentPeriodDaySeverities(Duration window, {required DateTime now}) async => const [];
  @override Stream<List<PeriodDaySeverity>> watchRecentPeriodDaySeverities(Duration window, {required DateTime now}) => Stream.value(const []);
}

Widget _wrap({required _FakeJournal fake}) {
  return ProviderScope(
    overrides: [
      flagsRepoProvider.overrideWithValue(_MemFlagsRepo()),
      journalSourceProvider.overrideWithValue(fake),
      riskDisplayModeProvider.overrideWith((ref) async => RiskDisplayMode.gauge),
      notificationsEnabledProvider.overrideWith((ref) async => false),
    ],
    child: MaterialApp.router(
      routerConfig: GoRouter(routes: [
        GoRoute(path: '/', builder: (_, __) => const SettingsScreen()),
      ]),
    ),
  );
}

void main() {
  testWidgets('renders trigger list and reflects flagged state', (tester) async {
    await tester.pumpWidget(_wrap(fake: _FakeJournal()));
    await tester.pumpAndSettle();
    expect(find.text('Stress'), findsOneWidget);
    expect(find.text('Pressure changes'), findsOneWidget);
  });

  testWidgets('Cycle section shows Log period when none active', (tester) async {
    final fake = _FakeJournal();
    await tester.pumpWidget(_wrap(fake: fake));
    await tester.pumpAndSettle();
    expect(find.text('Log period'), findsOneWidget);
    expect(find.text('No periods logged yet.'), findsOneWidget);
  });

  testWidgets('Cycle section "Log period" persists baseline severity', (tester) async {
    final fake = _FakeJournal();
    await tester.pumpWidget(_wrap(fake: fake));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('settings-period-button')));
    await tester.pumpAndSettle();
    expect(find.text('Baseline severity'), findsOneWidget);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(fake.addedPeriods, hasLength(1));
  });

  testWidgets('Cycle section flips to "End period" when one is in progress', (tester) async {
    final fake = _FakeJournal(periods: [
      PeriodEvent(startedAt: DateTime.utc(2026, 6, 10), baselineSeverity: 5),
    ]);
    await tester.pumpWidget(_wrap(fake: fake));
    await tester.pumpAndSettle();
    expect(find.text('End period'), findsOneWidget);
  });

  testWidgets('Cycle section lists periods and delete confirms + deletes', (tester) async {
    final start = DateTime.utc(2026, 6, 10);
    final fake = _FakeJournal(periods: [
      PeriodEvent(startedAt: start, endedAt: DateTime.utc(2026, 6, 14), baselineSeverity: 5),
    ]);
    await tester.pumpWidget(_wrap(fake: fake));
    await tester.pumpAndSettle();

    expect(find.byKey(Key('period-row-${start.toIso8601String()}')), findsOneWidget);

    await tester.tap(find.byKey(Key('period-delete-${start.toIso8601String()}')));
    await tester.pumpAndSettle();
    expect(find.text('Remove this period?'), findsOneWidget);

    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    expect(fake.deletedStarts, [start]);
  });
}
