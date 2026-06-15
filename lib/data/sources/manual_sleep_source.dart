import 'package:domain/domain.dart';
import 'package:drift/drift.dart';

import '../database.dart';

abstract class ManualSleepSource {
  Future<void> upsert(SleepRecord record);
  Future<void> delete(DateTime night);
  Future<List<SleepRecord>> recent(Duration window, {required DateTime now});
  Stream<List<SleepRecord>> watchRecent(Duration window, {required DateTime now});
}

class DriftManualSleepSource implements ManualSleepSource {
  final AppDatabase _db;
  DriftManualSleepSource(this._db);

  @override
  Future<void> upsert(SleepRecord record) async {
    await _db.into(_db.manualSleepRecords).insertOnConflictUpdate(
          ManualSleepRecordsCompanion.insert(
            night: record.night.toUtc(),
            sleepStart: record.sleepStart.toUtc(),
            totalSleepMinutes: record.totalSleep.inMinutes,
            efficiency: const Value.absent(), // MVP: efficiency not captured manually
          ),
        );
  }

  @override
  Future<void> delete(DateTime night) async {
    final utc = DateTime.utc(night.year, night.month, night.day);
    await (_db.delete(_db.manualSleepRecords)..where((t) => t.night.equals(utc))).go();
  }

  @override
  Future<List<SleepRecord>> recent(Duration window, {required DateTime now}) async {
    final utcNow = now.toUtc();
    final cutoff = utcNow.subtract(window);
    final rows = await (_db.select(_db.manualSleepRecords)
          ..where((t) => t.night.isBiggerOrEqualValue(cutoff) & t.night.isSmallerOrEqualValue(utcNow))
          ..orderBy([(t) => OrderingTerm.desc(t.night)]))
        .get();
    return rows.map(_toDomain).toList();
  }

  @override
  Stream<List<SleepRecord>> watchRecent(Duration window, {required DateTime now}) {
    final utcNow = now.toUtc();
    final cutoff = utcNow.subtract(window);
    final q = _db.select(_db.manualSleepRecords)
      ..where((t) => t.night.isBiggerOrEqualValue(cutoff) & t.night.isSmallerOrEqualValue(utcNow))
      ..orderBy([(t) => OrderingTerm.desc(t.night)]);
    return q.watch().map((rows) => rows.map(_toDomain).toList());
  }

  SleepRecord _toDomain(ManualSleepRecord r) => SleepRecord(
        night: r.night.toUtc(),
        sleepStart: r.sleepStart.toUtc(),
        totalSleep: Duration(minutes: r.totalSleepMinutes),
        efficiency: r.efficiency ?? 1.0,
      );
}
