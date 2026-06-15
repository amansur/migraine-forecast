import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/data/database.dart'
    hide JournalEntry, WeatherSnapshot, RiskAssessment, Attack;
import 'package:migraine_forecast/data/repos/location_overrides_repo.dart';
import 'package:migraine_forecast/data/sources/journal_source.dart';
import 'package:migraine_forecast/state/providers.dart';
import 'package:migraine_forecast/ui/insights/insights_screen.dart';


class _FakeJournal implements JournalSource {
  List<PeriodEvent> periods;
  final List<PeriodDaySeverity> upserts = [];
  final List<PeriodEvent> addedPeriods = [];
  final List<({DateTime startedAt, DateTime endedAt})> ends = [];
  final List<DateTime> deletedStarts = [];

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
  }
  @override Future<void> deletePeriod(DateTime startedAt) async {
    deletedStarts.add(startedAt);
    periods = periods.where((p) => !p.startedAt.isAtSameMomentAs(startedAt)).toList();
  }
  @override Future<List<PeriodEvent>> recentPeriods(Duration window, {required DateTime now}) async => periods;
  @override Stream<List<PeriodEvent>> watchRecentPeriods(Duration window, {required DateTime now}) => Stream.value(periods);
  @override Future<void> upsertPeriodDaySeverity(PeriodDaySeverity override) async {
    upserts.add(override);
  }
  @override Future<List<PeriodDaySeverity>> recentPeriodDaySeverities(Duration window, {required DateTime now}) async => const [];
  @override Stream<List<PeriodDaySeverity>> watchRecentPeriodDaySeverities(Duration window, {required DateTime now}) => Stream.value(const []);
}

void main() {
  final today = DateTime.utc(2026, 6, 12);

  testWidgets('cycle row omitted when phase Unknown', (tester) async {
    final fake = _FakeJournal();
    await tester.pumpWidget(_PumpSheet(fake: fake, day: today));
    await tester.pumpAndSettle();
    expect(find.textContaining('Day '), findsNothing);
  });

  testWidgets('cycle row shown for Confirmed phase (non-menses, non-tappable)', (tester) async {
    final fake = _FakeJournal(periods: [
      PeriodEvent(startedAt: DateTime.utc(2026, 4, 3), endedAt: DateTime.utc(2026, 4, 7), baselineSeverity: 5),
      PeriodEvent(startedAt: DateTime.utc(2026, 5, 1), endedAt: DateTime.utc(2026, 5, 5), baselineSeverity: 5),
    ]);
    await tester.pumpWidget(_PumpSheet(fake: fake, day: DateTime.utc(2026, 4, 15))); // confirmed
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('cycle-row-tap')), findsNothing);
    expect(find.textContaining('Day 13'), findsOneWidget);
    expect(find.textContaining('Ovulatory'), findsOneWidget);
  });

  testWidgets('cycle row tappable in menses (confirmed) and upserts override', (tester) async {
    final fake = _FakeJournal(periods: [
      PeriodEvent(startedAt: DateTime.utc(2026, 4, 3), endedAt: DateTime.utc(2026, 4, 7), baselineSeverity: 5),
      PeriodEvent(startedAt: DateTime.utc(2026, 5, 1), endedAt: DateTime.utc(2026, 5, 5), baselineSeverity: 5),
    ]);
    // 2026-04-04 = day 2 of the first cycle, menses, anchor-not-latest -> Confirmed.
    await tester.pumpWidget(_PumpSheet(fake: fake, day: DateTime.utc(2026, 4, 4)));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('cycle-row-tap')), findsOneWidget);
    expect(find.textContaining('Severity 5'), findsOneWidget);

    await tester.tap(find.byKey(const Key('cycle-row-tap')));
    await tester.pumpAndSettle();
    expect(find.text('Severity for this day'), findsOneWidget);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(fake.upserts, hasLength(1));
    expect(fake.upserts.first.day, DateTime.utc(2026, 4, 4));
  });

  testWidgets('mark-period-start shows when no period overlaps the day', (tester) async {
    final fake = _FakeJournal();
    await tester.pumpWidget(_PumpSheet(fake: fake, day: today));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('mark-period-start')), findsOneWidget);

    await tester.tap(find.byKey(const Key('mark-period-start')));
    await tester.pumpAndSettle();
    expect(find.text('Baseline severity'), findsOneWidget);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(fake.addedPeriods, hasLength(1));
  });

  testWidgets('mark-period-end shows when in-progress period started before the day', (tester) async {
    final fake = _FakeJournal(periods: [
      PeriodEvent(startedAt: DateTime.utc(2026, 6, 10), baselineSeverity: 5),
    ]);
    await tester.pumpWidget(_PumpSheet(fake: fake, day: DateTime.utc(2026, 6, 12)));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('mark-period-end')), findsOneWidget);

    await tester.tap(find.byKey(const Key('mark-period-end')));
    await tester.pumpAndSettle();
    expect(fake.ends, hasLength(1));
  });

  testWidgets('remove-period on a day overlapping a closed period deletes on confirm', (tester) async {
    final fake = _FakeJournal(periods: [
      PeriodEvent(
          startedAt: DateTime.utc(2026, 6, 10),
          endedAt: DateTime.utc(2026, 6, 14),
          baselineSeverity: 5),
    ]);
    await tester.pumpWidget(_PumpSheet(fake: fake, day: DateTime.utc(2026, 6, 12)));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('remove-period')), findsOneWidget);
    expect(find.byKey(const Key('mark-period-start')), findsNothing);

    await tester.tap(find.byKey(const Key('remove-period')));
    await tester.pumpAndSettle();
    expect(find.text('Remove this period?'), findsOneWidget);

    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    expect(fake.deletedStarts, [DateTime.utc(2026, 6, 10)]);
  });

  testWidgets('remove-period and mark-period-end both show on a day inside an in-progress period', (tester) async {
    final fake = _FakeJournal(periods: [
      PeriodEvent(startedAt: DateTime.utc(2026, 6, 10), baselineSeverity: 5),
    ]);
    await tester.pumpWidget(_PumpSheet(fake: fake, day: DateTime.utc(2026, 6, 12)));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('mark-period-end')), findsOneWidget);
    expect(find.byKey(const Key('remove-period')), findsOneWidget);
    expect(find.byKey(const Key('mark-period-start')), findsNothing);
  });
}

/// Helper widget that immediately pushes the day-detail sheet so the test
/// doesn't need to find and tap a heatmap cell.
///
/// Provides an in-memory [LocationOverridesRepo] override so the
/// _LocationOverrideRow doesn't try to open a real on-disk database.
class _PumpSheet extends StatefulWidget {
  final _FakeJournal fake;
  final DateTime day;
  const _PumpSheet({required this.fake, required this.day});

  @override
  State<_PumpSheet> createState() => _PumpSheetState();
}

class _PumpSheetState extends State<_PumpSheet> {
  late final AppDatabase _db;
  late final LocationOverridesRepo _repo;

  @override
  void initState() {
    super.initState();
    _db = AppDatabase.memory();
    _repo = LocationOverridesRepo(_db);
  }

  @override
  void dispose() {
    _db.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        journalSourceProvider.overrideWithValue(widget.fake),
        dayAssessmentProvider.overrideWith((ref, _) async => null),
        dayAttacksProvider.overrideWith((ref, _) => Stream.value(const <Attack>[])),
        locationOverridesRepoProvider.overrideWithValue(_repo),
      ],
      child: MaterialApp(
        home: Builder(builder: (ctx) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            showModalBottomSheet<void>(
              context: ctx,
              isScrollControlled: true,
              builder: (_) => DayDetailSheet(day: widget.day),
            );
          });
          return const Scaffold(body: SizedBox.expand());
        }),
      ),
    );
  }
}
