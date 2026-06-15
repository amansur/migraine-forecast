import 'package:domain/domain.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/data/database.dart';
import 'package:migraine_forecast/data/sources/manual_sleep_source.dart';

void main() {
  late AppDatabase db;
  late DriftManualSleepSource source;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    source = DriftManualSleepSource(db);
  });
  tearDown(() => db.close());

  SleepRecord recordFor(DateTime night, {int hours = 7}) => SleepRecord(
        night: night,
        totalSleep: Duration(hours: hours),
        efficiency: 1.0,
        sleepStart: night.add(const Duration(hours: 22)),
      );

  test('upsert then recent returns the record', () async {
    final night = DateTime.utc(2026, 6, 12);
    await source.upsert(recordFor(night));
    final got = await source.recent(const Duration(days: 7), now: DateTime.utc(2026, 6, 13));
    expect(got, hasLength(1));
    expect(got.single.night, night);
    expect(got.single.totalSleep, const Duration(hours: 7));
  });

  test('upsert on existing night overwrites', () async {
    final night = DateTime.utc(2026, 6, 12);
    await source.upsert(recordFor(night, hours: 6));
    await source.upsert(recordFor(night, hours: 8));
    final got = await source.recent(const Duration(days: 7), now: DateTime.utc(2026, 6, 13));
    expect(got, hasLength(1));
    expect(got.single.totalSleep, const Duration(hours: 8));
  });

  test('delete by night removes the row', () async {
    final night = DateTime.utc(2026, 6, 12);
    await source.upsert(recordFor(night));
    await source.delete(night);
    expect(
      await source.recent(const Duration(days: 7), now: DateTime.utc(2026, 6, 13)),
      isEmpty,
    );
  });

  test('watchRecent emits on upsert', () async {
    final emissions = <int>[];
    final sub = source
        .watchRecent(const Duration(days: 7), now: DateTime.utc(2026, 6, 13))
        .listen((l) => emissions.add(l.length));
    await source.upsert(recordFor(DateTime.utc(2026, 6, 12)));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await sub.cancel();
    expect(emissions, contains(1));
  });

  test('null efficiency round-trips', () async {
    final night = DateTime.utc(2026, 6, 12);
    await source.upsert(SleepRecord(
      night: night,
      totalSleep: const Duration(hours: 7),
      efficiency: 0.0, // sentinel: source stores null, returns 1.0 by default
      sleepStart: night.add(const Duration(hours: 22)),
    ));
    final got = (await source.recent(const Duration(days: 7), now: DateTime.utc(2026, 6, 13))).single;
    // Engine consumes totalSleep + sleepStart; efficiency comes back as 1.0 (default) when stored null.
    expect(got.efficiency, 1.0);
  });
}
