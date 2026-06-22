import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/data/sources/manual_sleep_source.dart';
import 'package:migraine_forecast/state/manual_sleep_provider.dart';
import 'package:migraine_forecast/ui/log/sleep_entry_sheet.dart';

class _FakeManual implements ManualSleepSource {
  final upserted = <SleepRecord>[];
  final deleted = <DateTime>[];
  @override
  Future<void> upsert(SleepRecord r) async => upserted.add(r);
  @override
  Future<void> delete(DateTime n) async => deleted.add(n);
  @override
  Future<List<SleepRecord>> recent(Duration w, {required DateTime now}) async => const [];
  @override
  Stream<List<SleepRecord>> watchRecent(Duration w, {required DateTime now}) =>
      Stream.value(const []);
}

Future<void> _pumpSheet(WidgetTester tester, _FakeManual fake, {SleepRecord? initial}) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [manualSleepSourceProvider.overrideWithValue(fake)],
    child: MaterialApp(home: Scaffold(body: SleepEntrySheet(initial: initial))),
  ));
}

void main() {
  testWidgets('default 22:00→06:00 computes 8h sleep', (tester) async {
    final fake = _FakeManual();
    await _pumpSheet(tester, fake);
    await tester.tap(find.byKey(const Key('sleep-save')));
    await tester.pump();
    expect(fake.upserted, hasLength(1));
    expect(fake.upserted.single.totalSleep, const Duration(hours: 8));
  });

  testWidgets('out-of-range duration disables save', (tester) async {
    final fake = _FakeManual();
    // Compose an initial record with 30min sleep → still invalid because
    // the sheet will internally derive duration from start/end times.
    await _pumpSheet(tester, fake, initial: SleepRecord(
      night: DateTime.utc(2026, 6, 12),
      sleepStart: DateTime.utc(2026, 6, 12, 23, 30),
      totalSleep: const Duration(minutes: 30),
      efficiency: 1.0,
    ));
    final btn = tester.widget<FilledButton>(find.byKey(const Key('sleep-save')));
    expect(btn.onPressed, isNull);
  });

  testWidgets('cross-midnight times produce positive duration', (tester) async {
    final fake = _FakeManual();
    await _pumpSheet(tester, fake);
    // The sheet's default already crosses midnight; verify night PK is the
    // calendar date of bedtime.
    await tester.tap(find.byKey(const Key('sleep-save')));
    await tester.pump();
    final r = fake.upserted.single;
    expect(r.totalSleep.inHours, greaterThan(0));
    expect(r.night, DateTime.utc(r.sleepStart.toUtc().year, r.sleepStart.toUtc().month, r.sleepStart.toUtc().day));
  });
}
