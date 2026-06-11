import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

final onboardingCompletedProvider = FutureProvider<bool>((ref) async {
  final settings = ref.watch(settingsRepoProvider);
  return settings.getBool('onboarding_completed');
});

final markOnboardingCompletedProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    await ref.read(settingsRepoProvider).setBool('onboarding_completed', true);
    ref.invalidate(onboardingCompletedProvider);
  };
});
