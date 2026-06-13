import 'package:domain/domain.dart';

abstract class JournalSource {
  Future<void> addEntry(JournalEntry entry);
  Future<List<JournalEntry>> recentEntries(Duration window, {required DateTime now});
  Future<int> addAttack(Attack attack, {int? riskAssessmentId});
  Future<List<Attack>> recentAttacks(Duration window, {required DateTime now});
  Stream<List<Attack>> watchRecentAttacks(Duration window, {required DateTime now});
  Future<void> deleteAttack(DateTime startedAt);
  Future<void> updateAttack(Attack old, Attack updated);

  // --- Period tracking ---
  Future<int> addPeriod(PeriodEvent period);
  Future<void> endPeriod(DateTime startedAt, DateTime endedAt);
  Future<void> deletePeriod(DateTime startedAt);
  Future<List<PeriodEvent>> recentPeriods(Duration window, {required DateTime now});
  Stream<List<PeriodEvent>> watchRecentPeriods(Duration window, {required DateTime now});

  Future<void> upsertPeriodDaySeverity(PeriodDaySeverity override);
  Future<List<PeriodDaySeverity>> recentPeriodDaySeverities(Duration window, {required DateTime now});
  Stream<List<PeriodDaySeverity>> watchRecentPeriodDaySeverities(Duration window, {required DateTime now});
}
