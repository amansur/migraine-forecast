import 'package:domain/domain.dart';

abstract class JournalSource {
  Future<void> addEntry(JournalEntry entry);
  Future<List<JournalEntry>> recentEntries(Duration window, {required DateTime now});
  Future<int> addAttack(Attack attack, {int? riskAssessmentId});
  Future<List<Attack>> recentAttacks(Duration window, {required DateTime now});
  Stream<List<Attack>> watchRecentAttacks(Duration window, {required DateTime now});
}
