import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:migraine_forecast/data/context_builder.dart';
import 'package:migraine_forecast/data/sources/journal_source.dart';
import 'package:migraine_forecast/state/providers.dart';
import 'package:migraine_forecast/state/settings_provider.dart';
import 'package:migraine_forecast/ui/settings/settings_screen.dart';
import 'package:migraine_forecast/state/mascot_character.dart';
import 'package:migraine_forecast/ui/shared/mascot/mascot_widget.dart';

class _MemFlagsRepo implements UserTriggerFlagsRepo {
  UserTriggerFlags _f = const UserTriggerFlags(flaggedModuleIds: {});
  @override Future<UserTriggerFlags> load() async => _f;
  @override Future<void> save(UserTriggerFlags flags) async => _f = flags;
}

class _FakeJournal implements JournalSource {
  @override Future<int> addAttack(Attack attack, {int? riskAssessmentId}) async => 1;
  @override Future<void> addEntry(JournalEntry entry) async {}
  @override Future<void> updateEntry(JournalEntry entry) async {}
  @override Future<void> deleteEntry(int id) async {}
  @override Future<List<JournalEntry>> recentEntries(Duration window, {required DateTime now}) async => const [];
  @override Stream<List<JournalEntry>> watchRecentEntries(Duration window, {required DateTime now}) => Stream.value(const []);
  @override Future<List<Attack>> recentAttacks(Duration window, {required DateTime now}) async => const [];
  @override Stream<List<Attack>> watchRecentAttacks(Duration window, {required DateTime now}) => Stream.value(const []);
  @override Future<void> deleteAttack(DateTime startedAt) async {}
  @override Future<void> updateAttack(Attack old, Attack updated) async {}
  @override Future<int> addPeriod(PeriodEvent period) async => 1;
  @override Future<void> endPeriod(DateTime startedAt, DateTime endedAt) async {}
  @override Future<void> deletePeriod(DateTime startedAt) async {}
  @override Future<List<PeriodEvent>> recentPeriods(Duration window, {required DateTime now}) async => const [];
  @override Stream<List<PeriodEvent>> watchRecentPeriods(Duration window, {required DateTime now}) => Stream.value(const []);
  @override Future<void> upsertPeriodDaySeverity(PeriodDaySeverity override) async {}
  @override Future<List<PeriodDaySeverity>> recentPeriodDaySeverities(Duration window, {required DateTime now}) async => const [];
  @override Stream<List<PeriodDaySeverity>> watchRecentPeriodDaySeverities(Duration window, {required DateTime now}) => Stream.value(const []);
}

void main() {
  testWidgets('toggling a trigger flag celebrates (mascot present, no crash)', (tester) async {
    // Use a tall viewport so the settings list items don't overflow off-screen.
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        flagsRepoProvider.overrideWithValue(_MemFlagsRepo()),
        journalSourceProvider.overrideWithValue(_FakeJournal()),
        riskDisplayModeProvider.overrideWith((ref) async => RiskDisplayMode.gauge),
        notificationsEnabledProvider.overrideWith((ref) async => false),
        mascotCharacterProvider.overrideWith((ref) async => MascotCharacter.kitty),
      ],
      child: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: MaterialApp.router(
          routerConfig: GoRouter(routes: [
            GoRoute(path: '/', builder: (_, __) => const SettingsScreen()),
          ]),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    // Mascot is visible at the top before any scrolling.
    expect(find.byType(MascotWidget), findsOneWidget);

    // Scroll the ListView until the trigger section is visible, then expand it.
    await tester.scrollUntilVisible(find.text('Pressure changes'), 100);
    await tester.tap(find.text('Pressure changes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('I think this triggers me'));

    // Allow the save + celebrate cycle to complete without crashing.
    await tester.pumpAndSettle();
  });
}
