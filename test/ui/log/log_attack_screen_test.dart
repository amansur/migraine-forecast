import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:migraine_weatherr/data/database.dart' hide Attack, JournalEntry, WeatherSnapshot, RiskAssessment, PeriodDaySeverity;
import 'package:migraine_weatherr/data/context_builder.dart' show UserTriggerFlagsRepo;
import 'package:migraine_weatherr/data/sources/fake_health_source.dart';
import 'package:migraine_weatherr/data/sources/journal_source.dart';
import 'package:migraine_weatherr/data/sources/manual_location_source.dart';
import 'package:migraine_weatherr/data/sources/weather_source.dart';
import 'package:migraine_weatherr/state/providers.dart';
import 'package:migraine_weatherr/state/risk_assessment_provider.dart';
import 'package:migraine_weatherr/ui/log/log_attack_screen.dart';

class _RecordingJournal implements JournalSource {
  Attack? lastAttack;
  int? lastAssessmentId;
  @override
  Future<int> addAttack(Attack attack, {int? riskAssessmentId}) async {
    lastAttack = attack;
    lastAssessmentId = riskAssessmentId;
    return 1;
  }
  @override Future<void> addEntry(JournalEntry entry) async {}
  @override Future<List<JournalEntry>> recentEntries(Duration window, {required DateTime now}) async => const [];
  @override
  Future<List<Attack>> recentAttacks(Duration window, {required DateTime now}) async => [];

  @override
  Stream<List<Attack>> watchRecentAttacks(Duration window, {required DateTime now}) => Stream.value([]);

  @override
  Future<void> deleteAttack(DateTime startedAt) async {}

  @override
  Future<void> updateAttack(Attack old, Attack updated) async {
    lastAttack = updated;
  }

  @override Future<int> addPeriod(PeriodEvent period) async => 1;
  @override Future<void> endPeriod(DateTime startedAt, DateTime endedAt) async {}
  @override Future<void> deletePeriod(DateTime startedAt) async {}
  @override Future<List<PeriodEvent>> recentPeriods(Duration window, {required DateTime now}) async => const [];
  @override Stream<List<PeriodEvent>> watchRecentPeriods(Duration window, {required DateTime now}) => Stream.value(const []);
  @override Future<void> upsertPeriodDaySeverity(PeriodDaySeverity override) async {}
  @override Future<List<PeriodDaySeverity>> recentPeriodDaySeverities(Duration window, {required DateTime now}) async => const [];
  @override Stream<List<PeriodDaySeverity>> watchRecentPeriodDaySeverities(Duration window, {required DateTime now}) => Stream.value(const []);
}

class _MockRiskAssessmentNotifier extends RiskAssessmentNotifier {
  @override
  Future<RiskAssessment> build() async => _dummy();

  @override
  Future<RiskAssessment> backfill(DateTime target) async => _dummy(target: target);

  RiskAssessment _dummy({DateTime? target}) => RiskAssessment(
        score: 0,
        band: RiskBand.low,
        contributors: const [],
        computedAt: DateTime.now(),
        configVersion: 1,
        targetDate: target ?? DateTime.now(),
        horizon: RiskHorizon.today,
      );
}

class _StubWeather implements WeatherSource {
  @override
  Future<WeatherSnapshot> fetch({required double lat, required double lon, required DateTime now}) async =>
      WeatherSnapshot(
        weather: const WeatherSeries(samples: []),
        airQuality: const AirQualitySeries(samples: []),
        fetchedAt: now,
      );
}

class _ThrowingBackfillNotifier extends RiskAssessmentNotifier {
  @override
  Future<RiskAssessment> build() async => RiskAssessment(
        score: 0,
        band: RiskBand.low,
        contributors: const [],
        computedAt: DateTime.now(),
        configVersion: 1,
        targetDate: DateTime.now(),
        horizon: RiskHorizon.today,
      );

  @override
  Future<RiskAssessment> backfill(DateTime target) {
    throw StateError('simulated weather failure');
  }
}

class _MemFlagsRepo implements UserTriggerFlagsRepo {
  UserTriggerFlags _f = const UserTriggerFlags();
  @override
  Future<UserTriggerFlags> load() async => _f;
  @override
  Future<void> save(UserTriggerFlags flags) async => _f = flags;
}

void main() {
  testWidgets('Submitting saves an attack via JournalSource', (tester) async {
    final journal = _RecordingJournal();
    final db = AppDatabase.memory();
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          journalSourceProvider.overrideWithValue(journal),
          riskAssessmentProvider.overrideWith(_MockRiskAssessmentNotifier.new),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(routes: [
            GoRoute(path: '/', builder: (_, __) => const LogAttackScreen()),
          ]),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(journal.lastAttack, isNotNull);
    expect(journal.lastAttack!.severity, inInclusiveRange(1, 10));
  });

  testWidgets('saves past-day attack with link to backfilled assessment', (tester) async {
    final db = AppDatabase.memory();
    addTearDown(db.close);
    final location = ManualLocationSource();
    await location.set(lat: 40.7, lon: -74.0);
    // Use a DriftJournalSource backed by the real DB so the assessment ID lookup works.
    // But we still capture what addAttack received via a recording wrapper.
    final journal = _RecordingJournal();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          journalSourceProvider.overrideWithValue(journal),
          weatherSourceProvider.overrideWithValue(_StubWeather()),
          healthSourceProvider.overrideWithValue(FakeHealthSource()),
          locationSourceProvider.overrideWithValue(location),
          flagsRepoProvider.overrideWithValue(_MemFlagsRepo()),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(routes: [
            GoRoute(
              path: '/',
              builder: (_, __) => LogAttackScreen(
                initialDate: DateTime.utc(2026, 6, 5),
              ),
            ),
          ]),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(journal.lastAttack, isNotNull);
    expect(journal.lastAssessmentId, isNotNull,
        reason: 'past-day save should link to the backfilled assessment row');
  });

  testWidgets('toggling "Still in progress" persists inProgress=true and clears end', (tester) async {
    final journal = _RecordingJournal();
    final db = AppDatabase.memory();
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          journalSourceProvider.overrideWithValue(journal),
          riskAssessmentProvider.overrideWith(_MockRiskAssessmentNotifier.new),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(routes: [
            GoRoute(path: '/', builder: (_, __) => const LogAttackScreen()),
          ]),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('still-in-progress-switch')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(journal.lastAttack, isNotNull);
    expect(journal.lastAttack!.inProgress, isTrue);
    expect(journal.lastAttack!.endedAt, isNull);
  });

  testWidgets('Open-Meteo failure surfaces SnackBar but attack still saves', (tester) async {
    final db = AppDatabase.memory();
    addTearDown(db.close);
    final journal = _RecordingJournal();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          journalSourceProvider.overrideWithValue(journal),
          riskAssessmentProvider.overrideWith(_ThrowingBackfillNotifier.new),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(routes: [
            GoRoute(
              path: '/',
              builder: (_, __) => LogAttackScreen(
                initialDate: DateTime.utc(2026, 6, 5),
              ),
            ),
          ]),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pump(); // surface the SnackBar
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.textContaining("Couldn't fetch weather"), findsOneWidget);
    await tester.pumpAndSettle();

    expect(journal.lastAttack, isNotNull,
        reason: 'attack must save even when backfill fails');
    expect(journal.lastAssessmentId, isNull,
        reason: 'failed backfill leaves the link null');
  });
}
