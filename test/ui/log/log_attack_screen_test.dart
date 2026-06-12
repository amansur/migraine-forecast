import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:migraine_weatherr/data/database.dart' hide Attack, JournalEntry, WeatherSnapshot, RiskAssessment;
import 'package:migraine_weatherr/data/sources/journal_source.dart';
import 'package:migraine_weatherr/state/providers.dart';
import 'package:migraine_weatherr/ui/log/log_attack_screen.dart';

class _RecordingJournal implements JournalSource {
  Attack? lastAttack;
  int? lastAssessmentId;
  @override
  Future<int> addAttack(Attack attack, {int? riskAssessmentId}) async {
    lastAttack = attack;
    lastAssessmentId = riskAssessmentId;
    return 1;
  }
  @override Future<void> addEntry(JournalEntry entry) async {}
  @override Future<List<JournalEntry>> recentEntries(Duration window, {required DateTime now}) async => const [];
  @override
  Future<List<Attack>> recentAttacks(Duration window, {required DateTime now}) async => [];

  @override
  Stream<List<Attack>> watchRecentAttacks(Duration window, {required DateTime now}) => Stream.value([]);
  }
void main() {
  testWidgets('Submitting saves an attack via JournalSource', (tester) async {
    final journal = _RecordingJournal();
    final db = AppDatabase.memory();
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          journalSourceProvider.overrideWithValue(journal),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(routes: [
            GoRoute(path: '/', builder: (_, __) => const LogAttackScreen()),
          ]),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(journal.lastAttack, isNotNull);
    expect(journal.lastAttack!.severity, inInclusiveRange(1, 10));
  });
}
