import 'dart:convert';

import 'package:domain/domain.dart';
import 'package:drift/drift.dart';

import '../database.dart';

class CorrelationRepo {
  final AppDatabase _db;
  CorrelationRepo(this._db);

  Future<List<ModuleCohort>> buildCohorts({
    required DateTime windowStart,
    required DateTime windowEnd,
    required List<String> moduleIds,
  }) async {
    final assessmentRows = await (_db.select(_db.riskAssessments)
          ..where((t) =>
              t.targetDate.isBiggerOrEqualValue(windowStart) &
              t.targetDate.isSmallerThanValue(windowEnd)))
        .get();

    final firedDaysByModule = <String, Set<DateTime>>{
      for (final id in moduleIds) id: <DateTime>{},
    };
    final allDays = <DateTime>{};
    for (final row in assessmentRows) {
      final day = DateTime.utc(row.targetDate.year, row.targetDate.month, row.targetDate.day);
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
              t.startedAt.isBiggerOrEqualValue(windowStart) &
              t.startedAt.isSmallerThanValue(windowEnd)))
        .get();
    final attackDays = <DateTime>{};
    for (final a in attackRows) {
      attackDays.add(DateTime.utc(a.startedAt.year, a.startedAt.month, a.startedAt.day));
    }

    return moduleIds.map((id) {
      final firedDays = firedDaysByModule[id] ?? <DateTime>{};
      final notFiredDays = allDays.difference(firedDays);
      final firedWithAttack = firedDays.intersection(attackDays).length;
      final notFiredWithAttack = notFiredDays.intersection(attackDays).length;
      return ModuleCohort(
        moduleId: id,
        daysFiredWithAttack: firedWithAttack,
        daysFiredTotal: firedDays.length,
        daysNotFiredWithAttack: notFiredWithAttack,
        daysNotFiredTotal: notFiredDays.length,
      );
    }).toList();
  }
}
