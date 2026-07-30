/// Widget tests for the History day-detail location label sourced from the
/// stored per-day assessment coordinates.
library;

import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/data/database.dart' hide Attack, JournalEntry, RiskAssessment, PeriodDaySeverity;
import 'package:migraine_forecast/data/repos/assessment_repository.dart';
import 'package:migraine_forecast/data/sources/journal_source.dart';
import 'package:migraine_forecast/data/sources/reverse_geocoder.dart';
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

class _FakeReverse implements ReverseGeocoder {
  @override
  Future<String> label(double lat, double lon) async => 'Oakland, California';
}

void main() {
  final day = DateTime.utc(2026, 7, 20);

  Widget pumpTree(AssessmentRepository repo) => ProviderScope(
        overrides: [
          journalSourceProvider.overrideWithValue(_FakeJournal()),
          dayAssessmentProvider.overrideWith((ref, _) async => null),
          dayAttacksProvider.overrideWith((ref, _) => Stream.value(const <Attack>[])),
          locationOverridesRepoProvider.overrideWithValue(FakeLocationOverridesRepo()),
          assessmentRepoProvider.overrideWithValue(repo),
          reverseGeocoderProvider.overrideWithValue(_FakeReverse()),
        ],
        child: MaterialApp(home: Scaffold(body: DayDetailSheet(day: day))),
      );

  testWidgets('reverse-geocodes stored coords when name is null', (tester) async {
    final db = AppDatabase.memory();
    addTearDown(db.close);
    final repo = AssessmentRepository(db);
    await repo.save(RiskAssessment(
      score: 22,
      band: RiskBand.low,
      contributors: const [],
      computedAt: DateTime.utc(2026, 7, 20, 23),
      configVersion: 1,
      targetDate: day,
      horizon: RiskHorizon.today,
      resolvedLat: 37.8044,
      resolvedLon: -122.2712,
    ));

    await tester.pumpWidget(pumpTree(repo));
    await tester.pumpAndSettle();

    expect(find.text('Oakland, California (37.8044, -122.2712)'), findsOneWidget);
    expect(find.text('Use auto'), findsNothing);
  });

  testWidgets('uses stored locationName verbatim when present', (tester) async {
    final db = AppDatabase.memory();
    addTearDown(db.close);
    final repo = AssessmentRepository(db);
    await repo.save(RiskAssessment(
      score: 22,
      band: RiskBand.low,
      contributors: const [],
      computedAt: DateTime.utc(2026, 7, 20, 23),
      configVersion: 1,
      targetDate: day,
      horizon: RiskHorizon.today,
      resolvedLat: 51.5074,
      resolvedLon: -0.1278,
      locationName: 'London, England',
    ));

    await tester.pumpWidget(pumpTree(repo));
    await tester.pumpAndSettle();

    expect(find.text('London, England (51.5074, -0.1278)'), findsOneWidget);
  });
}
