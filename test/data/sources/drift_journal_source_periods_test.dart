import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_weatherr/data/database.dart' hide Attack, JournalEntry, PeriodDaySeverity;
import 'package:migraine_weatherr/data/sources/drift_journal_source.dart';

void main() {
  late AppDatabase db;
  late DriftJournalSource source;

  setUp(() {
    db = AppDatabase.memory();
    source = DriftJournalSource(db);
  });
  tearDown(() => db.close());

  group('PeriodEvent', () {
    test('round-trips an in-progress period', () async {
      final start = DateTime.utc(2026, 6, 10, 8);
      await source.addPeriod(PeriodEvent(startedAt: start, baselineSeverity: 5));
      final list = await source.recentPeriods(
        const Duration(days: 30),
        now: DateTime.utc(2026, 6, 12, 0),
      );
      expect(list, hasLength(1));
      expect(list.first.startedAt, start);
      expect(list.first.endedAt, isNull);
      expect(list.first.baselineSeverity, 5);
    });

    test('endPeriod writes endedAt', () async {
      final start = DateTime.utc(2026, 6, 10);
      await source.addPeriod(PeriodEvent(startedAt: start, baselineSeverity: 4));
      await source.endPeriod(start, DateTime.utc(2026, 6, 14));
      final list = await source.recentPeriods(
        const Duration(days: 30),
        now: DateTime.utc(2026, 6, 20),
      );
      expect(list.first.endedAt, DateTime.utc(2026, 6, 14));
    });

    test('recentPeriods filters by window', () async {
      await source.addPeriod(PeriodEvent(
          startedAt: DateTime.utc(2026, 1, 1),
          endedAt: DateTime.utc(2026, 1, 5),
          baselineSeverity: 5));
      final list = await source.recentPeriods(
        const Duration(days: 30),
        now: DateTime.utc(2026, 6, 10),
      );
      expect(list, isEmpty);
    });

    test('watchRecentPeriods emits on insert', () async {
      final stream = source.watchRecentPeriods(
        const Duration(days: 60),
        now: DateTime.utc(2026, 6, 20),
      );
      final emissions = <List<PeriodEvent>>[];
      final sub = stream.listen(emissions.add);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await source.addPeriod(PeriodEvent(
          startedAt: DateTime.utc(2026, 6, 10), baselineSeverity: 6));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await sub.cancel();
      expect(emissions.last, hasLength(1));
    });

    test('deletePeriod removes the row', () async {
      final start = DateTime.utc(2026, 6, 10);
      await source.addPeriod(PeriodEvent(startedAt: start, baselineSeverity: 5));
      await source.deletePeriod(start);
      final list = await source.recentPeriods(
        const Duration(days: 30),
        now: DateTime.utc(2026, 6, 12),
      );
      expect(list, isEmpty);
    });
  });

  group('PeriodDaySeverity overrides', () {
    test('upsert inserts then updates same day', () async {
      final day = DateTime.utc(2026, 6, 11);
      await source.upsertPeriodDaySeverity(PeriodDaySeverity(day: day, severity: 7));
      await source.upsertPeriodDaySeverity(PeriodDaySeverity(day: day, severity: 9));
      final list = await source.recentPeriodDaySeverities(
        const Duration(days: 30),
        now: DateTime.utc(2026, 6, 20),
      );
      expect(list, hasLength(1));
      expect(list.first.severity, 9);
    });

    test('multiple days coexist', () async {
      await source.upsertPeriodDaySeverity(
          PeriodDaySeverity(day: DateTime.utc(2026, 6, 11), severity: 6));
      await source.upsertPeriodDaySeverity(
          PeriodDaySeverity(day: DateTime.utc(2026, 6, 12), severity: 8));
      final list = await source.recentPeriodDaySeverities(
        const Duration(days: 30),
        now: DateTime.utc(2026, 6, 20),
      );
      expect(list, hasLength(2));
    });
  });
}
