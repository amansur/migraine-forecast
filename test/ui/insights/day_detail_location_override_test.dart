/// Widget tests for the location-override row in DayDetailSheet.
///
/// Verifies:
/// - Row shows 'Auto (GPS)' when no override is set.
/// - Row shows the override display name when one is active.
/// - 'Use auto' button is present only when an override is active.
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/data/database.dart'
    hide JournalEntry, WeatherSnapshot, RiskAssessment, Attack, PeriodDaySeverity;
import 'package:migraine_forecast/data/repos/location_overrides_repo.dart';
import 'package:migraine_forecast/data/sources/journal_source.dart';
import 'package:migraine_forecast/data/sources/location_source.dart';
import 'package:migraine_forecast/state/providers.dart';
import 'package:migraine_forecast/ui/insights/insights_screen.dart';

class _FakeJournal implements JournalSource {
  @override Future<int> addAttack(Attack attack, {int? riskAssessmentId}) async => 1;
  @override Future<void> addEntry(JournalEntry entry) async {}
  @override Future<void> updateEntry(JournalEntry entry) async {}
  @override Future<void> deleteEntry(int id) async {}
  @override Future<List<JournalEntry>> recentEntries(Duration w, {required DateTime now}) async => [];
  @override Stream<List<JournalEntry>> watchRecentEntries(Duration w, {required DateTime now}) => Stream.value([]);
  @override Future<List<Attack>> recentAttacks(Duration w, {required DateTime now}) async => [];
  @override Stream<List<Attack>> watchRecentAttacks(Duration w, {required DateTime now}) => Stream.value([]);
  @override Future<void> deleteAttack(DateTime s) async {}
  @override Future<void> updateAttack(Attack o, Attack u) async {}
  @override Future<int> addPeriod(PeriodEvent p) async => 1;
  @override Future<void> endPeriod(DateTime s, DateTime e) async {}
  @override Future<void> deletePeriod(DateTime s) async {}
  @override Future<List<PeriodEvent>> recentPeriods(Duration w, {required DateTime now}) async => [];
  @override Stream<List<PeriodEvent>> watchRecentPeriods(Duration w, {required DateTime now}) => Stream.value([]);
  @override Future<void> upsertPeriodDaySeverity(PeriodDaySeverity o) async {}
  @override Future<List<PeriodDaySeverity>> recentPeriodDaySeverities(Duration w, {required DateTime now}) async => [];
  @override Stream<List<PeriodDaySeverity>> watchRecentPeriodDaySeverities(Duration w, {required DateTime now}) => Stream.value([]);
}

void main() {
  final day = DateTime.utc(2026, 6, 1);

  testWidgets('shows Auto (GPS) when no override is set', (tester) async {
    await tester.pumpWidget(const _PumpSheet());
    await tester.pumpAndSettle();
    expect(find.text('Auto (GPS)'), findsOneWidget);
    expect(find.text('Use auto'), findsNothing);
  });

  testWidgets('shows override display name when override is active', (tester) async {
    await tester.pumpWidget(_PumpSheet(
      seed: (repo) => repo.set(day, const UserLocation(lat: 51.5074, lon: -0.1278), 'London, UK'),
    ));
    await tester.pumpAndSettle();
    expect(find.text('London, UK'), findsOneWidget);
    expect(find.text('Use auto'), findsOneWidget);
  });
}

class _PumpSheet extends StatefulWidget {
  final Future<void> Function(LocationOverridesRepo repo)? seed;
  const _PumpSheet({this.seed});

  @override
  State<_PumpSheet> createState() => _PumpSheetState();
}

class _PumpSheetState extends State<_PumpSheet> {
  late final AppDatabase _db;
  late final LocationOverridesRepo _repo;
  late final Future<void> _ready;

  @override
  void initState() {
    super.initState();
    _db = AppDatabase.memory();
    _repo = LocationOverridesRepo(_db);
    _ready = widget.seed?.call(_repo) ?? Future.value();
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
        journalSourceProvider.overrideWithValue(_FakeJournal()),
        dayAssessmentProvider.overrideWith((ref, _) async => null),
        dayAttacksProvider.overrideWith((ref, _) => Stream.value(const <Attack>[])),
        locationOverridesRepoProvider.overrideWithValue(_repo),
      ],
      child: MaterialApp(
        home: Builder(builder: (ctx) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            await _ready;
            if (!ctx.mounted) return;
            showModalBottomSheet<void>(
              context: ctx,
              isScrollControlled: true,
              builder: (_) => DayDetailSheet(day: DateTime.utc(2026, 6, 1)),
            );
          });
          return const Scaffold(body: SizedBox.expand());
        }),
      ),
    );
  }
}
