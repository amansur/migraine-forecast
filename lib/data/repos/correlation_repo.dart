import 'dart:convert';

import 'package:domain/domain.dart';
import 'package:drift/drift.dart';

import '../database.dart';

class CorrelationRepo {
  final AppDatabase _db;
  CorrelationRepo(this._db);

  Future<List<Cohort>> buildCohorts({
    required DateTime windowStart,
    required DateTime windowEnd,
    required List<String> moduleIds,
  }) async {
    final s = windowStart.toUtc();
    final utcStart = DateTime.utc(s.year, s.month, s.day);
    final e = windowEnd.toUtc();
    final utcEnd = DateTime.utc(e.year, e.month, e.day).add(const Duration(days: 1));

    final assessmentRows = await (_db.select(_db.riskAssessments)
          ..where((t) =>
              t.targetDate.isBiggerOrEqualValue(utcStart) &
              t.targetDate.isSmallerThanValue(utcEnd)))
        .get();

    final firedDaysByModule = <String, Set<DateTime>>{
      for (final id in moduleIds) id: <DateTime>{},
    };
    final allDays = <DateTime>{};
    for (final row in assessmentRows) {
      final d = row.targetDate.toUtc();
      final day = DateTime.utc(d.year, d.month, d.day);
      allDays.add(day);
      final contributors = jsonDecode(row.contributorsJson) as List;
      for (final c in contributors) {
        final m = c as Map<String, Object?>;
        final moduleId = m['moduleId'] as String;
        final weight = (m['weight'] as num).toDouble();
        final confidence = (m['confidence'] as num).toDouble();
        if (weight * confidence > 0 && firedDaysByModule.containsKey(moduleId)) {
          firedDaysByModule[moduleId]!.add(day);
        }
      }
    }

    final attackRows = await (_db.select(_db.attacks)
          ..where((t) =>
              t.startedAt.isBiggerOrEqualValue(utcStart) &
              t.startedAt.isSmallerThanValue(utcEnd)))
        .get();
    final attackDays = <DateTime>{};
    for (final a in attackRows) {
      final d = a.startedAt.toUtc();
      attackDays.add(DateTime.utc(d.year, d.month, d.day));
    }

    return moduleIds.map((id) {
      final firedDays = firedDaysByModule[id] ?? <DateTime>{};
      final notFiredDays = allDays.difference(firedDays);
      final firedWithAttack = firedDays.intersection(attackDays).length;
      final notFiredWithAttack = notFiredDays.intersection(attackDays).length;
      return Cohort(
        exposureId: id,
        daysFiredWithAttack: firedWithAttack,
        daysFiredTotal: firedDays.length,
        daysNotFiredWithAttack: notFiredWithAttack,
        daysNotFiredTotal: notFiredDays.length,
      );
    }).toList();
  }
}
