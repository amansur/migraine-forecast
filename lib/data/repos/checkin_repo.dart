import 'package:drift/drift.dart';

import '../database.dart';

class CheckinRepo {
  final AppDatabase _db;
  CheckinRepo(this._db);

  Future<DayCheckin?> forDay(DateTime day) =>
      (_db.select(_db.dayCheckins)..where((t) => t.day.equals(day)))
          .getSingleOrNull();

  Future<void> record(
          {required DateTime day, required bool hadAttack, required DateTime at}) =>
      _db.into(_db.dayCheckins).insert(
            DayCheckinsCompanion.insert(day: day, hadAttack: hadAttack, answeredAt: at),
            mode: InsertMode.insertOrReplace,
          );
}
