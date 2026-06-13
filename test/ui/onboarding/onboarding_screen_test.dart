import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:migraine_forecast/data/context_builder.dart';
import 'package:migraine_forecast/services/permission_service.dart';
import 'package:migraine_forecast/state/providers.dart';
import 'package:migraine_forecast/state/onboarding_provider.dart';
import 'package:migraine_forecast/ui/onboarding/onboarding_screen.dart';

class _MemFlagsRepo implements UserTriggerFlagsRepo {
  UserTriggerFlags _f = const UserTriggerFlags();
  @override Future<UserTriggerFlags> load() async => _f;
  @override Future<void> save(UserTriggerFlags flags) async => _f = flags;
}

class _StubPermissionService extends PermissionService {
  _StubPermissionService() : super.forTesting();
  @override
  Future<bool> requestLocation() async => true;
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
          permissionServiceProvider.overrideWithValue(_StubPermissionService()),
          markOnboardingCompletedProvider.overrideWithValue(() async { onboardingDone = true; }),
          onboardingCompletedProvider.overrideWith((ref) => Future.value(onboardingDone)),
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
