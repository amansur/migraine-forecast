import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:migraine_weatherr/data/context_builder.dart';
import 'package:migraine_weatherr/state/providers.dart';
import 'package:migraine_weatherr/state/onboarding_provider.dart';
import 'package:migraine_weatherr/ui/onboarding/onboarding_screen.dart';

class _MemFlagsRepo implements UserTriggerFlagsRepo {
  UserTriggerFlags _f = const UserTriggerFlags();
  @override Future<UserTriggerFlags> load() async => _f;
  @override Future<void> save(UserTriggerFlags flags) async => _f = flags;
}

void main() {
  testWidgets('tapping triggers then Finish persists flags + marks onboarding completed', (tester) async {
    final flagsRepo = _MemFlagsRepo();
    bool onboardingDone = false;

    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/today', builder: (_, __) => const Scaffold(body: Text('Today'))),
    ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          flagsRepoProvider.overrideWithValue(flagsRepo),
          markOnboardingCompletedProvider.overrideWithValue(() async { onboardingDone = true; }),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Stress'));
    await tester.tap(find.text('Weather'));
    await tester.tap(find.text('Finish'));
    await tester.pumpAndSettle();

    final saved = await flagsRepo.load();
    expect(saved.flaggedModuleIds, contains('stress'));
    expect(saved.flaggedModuleIds, contains('pressure_drop'));
    expect(onboardingDone, isTrue);
  });
}
