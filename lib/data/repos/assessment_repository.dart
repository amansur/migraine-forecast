import 'dart:convert';

import 'package:domain/domain.dart';
import 'package:drift/drift.dart';

import '../database.dart' hide RiskAssessment;

class AssessmentRepository {
  final AppDatabase _db;
  AssessmentRepository(this._db);

  Future<int> save(RiskAssessment ass) async {
    return _db.into(_db.riskAssessments).insert(
          RiskAssessmentsCompanion.insert(
            targetDate: ass.targetDate,
            horizon: ass.horizon.name,
            score: ass.score,
            band: ass.band.name,
            computedAt: ass.computedAt,
            configVersion: ass.configVersion,
            contributorsJson: jsonEncode(ass.contributors
                .map((c) => {
                      'moduleId': c.moduleId,
                      'weight': c.weight,
                      'confidence': c.confidence,
                      'explanation': c.explanation,
                    })
                .toList()),
          ),
        );
  }

  Future<RiskAssessment?> latestForDate({
    required DateTime target,
    required RiskHorizon horizon,
  }) async {
    final rows = await (_db.select(_db.riskAssessments)
          ..where((t) => t.targetDate.equals(target) & t.horizon.equals(horizon.name))
          ..orderBy([(t) => OrderingTerm.desc(t.computedAt)])
          ..limit(1))
        .get();
    return rows.isEmpty ? null : _toDomain(rows.first);
  }

  Future<RiskAssessment?> activeAt(DateTime when) async {
    final rows = await (_db.select(_db.riskAssessments)
          ..where((t) => t.computedAt.isSmallerOrEqualValue(when))
          ..orderBy([(t) => OrderingTerm.desc(t.computedAt)])
          ..limit(1))
        .get();
    return rows.isEmpty ? null : _toDomain(rows.first);
  }

  RiskAssessment _toDomain(dynamic row) {
    final contributors = (jsonDecode(row.contributorsJson) as List)
        .map((e) {
          final m = e as Map<String, Object?>;
          return TriggerSignal(
            moduleId: m['moduleId'] as String,
            weight: (m['weight'] as num).toDouble(),
            confidence: (m['confidence'] as num).toDouble(),
            explanation: m['explanation'] as String,
          );
        })
        .toList();
    return RiskAssessment(
      score: row.score as int,
      band: RiskBand.values.firstWhere((b) => b.name == row.band),
      contributors: contributors,
      computedAt: row.computedAt as DateTime,
      configVersion: row.configVersion as int,
      targetDate: row.targetDate as DateTime,
      horizon: RiskHorizon.values.firstWhere((h) => h.name == row.horizon),
    );
  }
}
