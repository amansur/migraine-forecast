import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../state/onboarding_provider.dart';
import '../ui/insights/insights_screen.dart';
import '../ui/log/log_attack_screen.dart';
import '../ui/log/log_history_screen.dart';
import '../ui/onboarding/onboarding_screen.dart';
import '../ui/settings/settings_screen.dart';
import '../ui/today/today_screen.dart';
import '../ui/today/tomorrow_detail_screen.dart';

GoRouter buildRouter(WidgetRef ref) {
  return GoRouter(
    initialLocation: '/today',
    redirect: (context, state) {
      final completed = ref.read(onboardingCompletedProvider).asData?.value ?? false;
      final goingToOnboarding = state.matchedLocation == '/onboarding';
      if (!completed && !goingToOnboarding) return '/onboarding';
      if (completed && goingToOnboarding) return '/today';
      return null;
    },
    routes: [
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/today', builder: (_, __) => const TodayScreen()),
      GoRoute(path: '/tomorrow', builder: (_, __) => const TomorrowDetailScreen()),
      GoRoute(path: '/log', builder: (context, state) {
        final extra = state.extra;
        if (extra is Attack) {
          return LogAttackScreen(initialAttack: extra);
        }
        if (extra is DateTime) {
          return LogAttackScreen(initialDate: extra);
        }
        return const LogAttackScreen();
      }),
      GoRoute(path: '/log-history', builder: (_, __) => const LogHistoryScreen()),
      GoRoute(path: '/insights', builder: (_, __) => const InsightsScreen()),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
    ],
  );
}
