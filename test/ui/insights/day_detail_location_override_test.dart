/// Widget tests for the location-override row in DayDetailSheet.
library;

import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/data/sources/journal_source.dart';
import 'package:migraine_forecast/data/sources/location_source.dart';
import 'package:migraine_forecast/state/providers.dart';
import 'package:migraine_forecast/ui/insights/insights_screen.dart';

import '_fake_location_overrides_repo.dart';

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

  Widget pumpTree(FakeLocationOverridesRepo repo) => ProviderScope(
        overrides: [
          journalSourceProvider.overrideWithValue(_FakeJournal()),
          dayAssessmentProvider.overrideWith((ref, _) async => null),
          dayAttacksProvider.overrideWith((ref, _) => Stream.value(const <Attack>[])),
          locationOverridesRepoProvider.overrideWithValue(repo),
        ],
        child: MaterialApp(home: Scaffold(body: DayDetailSheet(day: day))),
      );

  testWidgets('shows Auto (GPS) when no override is set', (tester) async {
    await tester.pumpWidget(pumpTree(FakeLocationOverridesRepo()));
    await tester.pumpAndSettle();
    expect(find.text('Auto (GPS)'), findsOneWidget);
    expect(find.text('Use auto'), findsNothing);
  });

  testWidgets('shows override display name when override is active', (tester) async {
    final repo = FakeLocationOverridesRepo()
      ..seed(day, const UserLocation(lat: 51.5074, lon: -0.1278), 'London, UK');
    await tester.pumpWidget(pumpTree(repo));
    await tester.pumpAndSettle();
    expect(find.text('London, UK'), findsOneWidget);
    expect(find.text('Use auto'), findsOneWidget);
  });
}
