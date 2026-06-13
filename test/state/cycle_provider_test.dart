import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/data/sources/journal_source.dart';
import 'package:migraine_forecast/state/cycle_provider.dart';
import 'package:migraine_forecast/state/providers.dart';

class _FakeJournal implements JournalSource {
  List<PeriodEvent> periods;
  List<PeriodDaySeverity> overrides;
  _FakeJournal({this.periods = const [], this.overrides = const []});

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
  @override Future<void> endPeriod(DateTime startedAt, DateTime endedAt) async {}
  @override Future<void> deletePeriod(DateTime startedAt) async {}
  @override Future<List<PeriodEvent>> recentPeriods(Duration window, {required DateTime now}) async => periods;
  @override Stream<List<PeriodEvent>> watchRecentPeriods(Duration window, {required DateTime now}) => Stream.value(periods);
  @override Future<void> upsertPeriodDaySeverity(PeriodDaySeverity override) async {
    overrides = [override, ...overrides.where((o) => !o.day.isAtSameMomentAs(override.day))];
  }
  @override Future<List<PeriodDaySeverity>> recentPeriodDaySeverities(Duration window, {required DateTime now}) async => overrides;
  @override Stream<List<PeriodDaySeverity>> watchRecentPeriodDaySeverities(Duration window, {required DateTime now}) => Stream.value(overrides);
}

ProviderContainer _container(_FakeJournal fake) {
  return ProviderContainer(overrides: [
    journalSourceProvider.overrideWithValue(fake),
  ]);
}

DateTime _d(int y, int m, int d) => DateTime.utc(y, m, d);

void main() {
  test('currentPeriodProvider returns in-progress period', () async {
    final ongoing = PeriodEvent(startedAt: _d(2026, 6, 10), baselineSeverity: 5);
    final fake = _FakeJournal(periods: [ongoing]);
    final c = _container(fake);
    addTearDown(c.dispose);

    // Force the stream to resolve
    await c.read(recentPeriodsProvider.future);
    expect(c.read(currentPeriodProvider), ongoing);
  });

  test('currentPeriodProvider returns null when most-recent has endedAt', () async {
    final fake = _FakeJournal(periods: [
      PeriodEvent(startedAt: _d(2026, 6, 10), endedAt: _d(2026, 6, 14), baselineSeverity: 5),
    ]);
    final c = _container(fake);
    addTearDown(c.dispose);
    await c.read(recentPeriodsProvider.future);
    expect(c.read(currentPeriodProvider), isNull);
  });

  test('dayPhaseProvider returns Unknown with <2 periods', () async {
    final fake = _FakeJournal(periods: [
      PeriodEvent(startedAt: _d(2026, 6, 1), endedAt: _d(2026, 6, 5), baselineSeverity: 5),
    ]);
    final c = _container(fake);
    addTearDown(c.dispose);
    await c.read(recentPeriodsProvider.future);
    await c.read(recentPeriodDaySeveritiesProvider.future);
    expect(c.read(dayPhaseProvider(_d(2026, 6, 10))), isA<PhaseUnknown>());
  });

  test('dayPhaseProvider returns Confirmed for non-latest anchor', () async {
    final fake = _FakeJournal(periods: [
      PeriodEvent(startedAt: _d(2026, 5, 1), endedAt: _d(2026, 5, 5), baselineSeverity: 5),
      PeriodEvent(startedAt: _d(2026, 5, 29), endedAt: _d(2026, 6, 2), baselineSeverity: 5),
    ]);
    final c = _container(fake);
    addTearDown(c.dispose);
    await c.read(recentPeriodsProvider.future);
    await c.read(recentPeriodDaySeveritiesProvider.future);
    expect(c.read(dayPhaseProvider(_d(2026, 5, 15))), isA<PhaseConfirmed>());
  });

  test('effectiveDaySeverityProvider: override beats baseline; null outside', () async {
    final fake = _FakeJournal(
      periods: [
        PeriodEvent(startedAt: _d(2026, 6, 10), endedAt: _d(2026, 6, 14), baselineSeverity: 5),
      ],
      overrides: [
        PeriodDaySeverity(day: _d(2026, 6, 11), severity: 9),
      ],
    );
    final c = _container(fake);
    addTearDown(c.dispose);
    await c.read(recentPeriodsProvider.future);
    await c.read(recentPeriodDaySeveritiesProvider.future);

    expect(c.read(effectiveDaySeverityProvider(_d(2026, 6, 11))), 9, reason: 'override');
    expect(c.read(effectiveDaySeverityProvider(_d(2026, 6, 12))), 5, reason: 'baseline');
    expect(c.read(effectiveDaySeverityProvider(_d(2026, 7, 1))), isNull, reason: 'outside');
  });

  test('effectiveDaySeverityProvider: in-progress period spans default 5 days', () async {
    final fake = _FakeJournal(periods: [
      PeriodEvent(startedAt: _d(2026, 6, 10), baselineSeverity: 6),
    ]);
    final c = _container(fake);
    addTearDown(c.dispose);
    await c.read(recentPeriodsProvider.future);
    await c.read(recentPeriodDaySeveritiesProvider.future);
    // 2026-06-14 = day 5
    expect(c.read(effectiveDaySeverityProvider(_d(2026, 6, 14))), 6);
    expect(c.read(effectiveDaySeverityProvider(_d(2026, 6, 15))), isNull);
  });
}
