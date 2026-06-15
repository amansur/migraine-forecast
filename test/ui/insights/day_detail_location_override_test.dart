/// Widget tests for the location-override row in DayDetailSheet.
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

/// Fake repo backed by an in-memory map. Avoids drift's streaming polling
/// so the widget test doesn't leak pending timers.
class _FakeLocationOverridesRepo implements LocationOverridesRepo {
  final Map<DateTime, ({UserLocation loc, String displayName})> _byDay = {};

  _FakeLocationOverridesRepo();

  void seed(DateTime day, UserLocation loc, String displayName) {
    _byDay[_key(day)] = (loc: loc, displayName: displayName);
  }

  @override
  Future<UserLocation?> forDay(DateTime day) async => _byDay[_key(day)]?.loc;

  @override
  Future<void> set(DateTime day, UserLocation loc, String displayName) async {
    _byDay[_key(day)] = (loc: loc, displayName: displayName);
  }

  @override
  Future<void> clear(DateTime day) async {
    _byDay.remove(_key(day));
  }

  @override
  Stream<Map<DateTime, UserLocation>> watchAll() => Stream.value(
        {for (final e in _byDay.entries) e.key: e.value.loc},
      );

  @override
  Stream<DayLocationOverride?> watchForDay(DateTime day) {
    final entry = _byDay[_key(day)];
    if (entry == null) return Stream.value(null);
    return Stream.value(DayLocationOverride(
      day: _key(day),
      lat: entry.loc.lat,
      lon: entry.loc.lon,
      displayName: entry.displayName,
      setAt: DateTime.utc(2026, 1, 1),
    ));
  }

  static DateTime _key(DateTime d) {
    final u = d.toUtc();
    return DateTime.utc(u.year, u.month, u.day);
  }
}

void main() {
  final day = DateTime.utc(2026, 6, 1);

  Widget pumpTree(_FakeLocationOverridesRepo repo) => ProviderScope(
        overrides: [
          journalSourceProvider.overrideWithValue(_FakeJournal()),
          dayAssessmentProvider.overrideWith((ref, _) async => null),
          dayAttacksProvider.overrideWith((ref, _) => Stream.value(const <Attack>[])),
          locationOverridesRepoProvider.overrideWithValue(repo),
        ],
        child: MaterialApp(home: Scaffold(body: DayDetailSheet(day: day))),
      );

  testWidgets('shows Auto (GPS) when no override is set', (tester) async {
    await tester.pumpWidget(pumpTree(_FakeLocationOverridesRepo()));
    await tester.pumpAndSettle();
    expect(find.text('Auto (GPS)'), findsOneWidget);
    expect(find.text('Use auto'), findsNothing);
  });

  testWidgets('shows override display name when override is active', (tester) async {
    final repo = _FakeLocationOverridesRepo()
      ..seed(day, const UserLocation(lat: 51.5074, lon: -0.1278), 'London, UK');
    await tester.pumpWidget(pumpTree(repo));
    await tester.pumpAndSettle();
    expect(find.text('London, UK'), findsOneWidget);
    expect(find.text('Use auto'), findsOneWidget);
  });
}
