import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../services/lifecycle_observer.dart';
import '../state/onboarding_provider.dart';
import '../state/providers.dart';
import '../state/risk_assessment_provider.dart';
import '../state/settings_provider.dart';
import 'router.dart';
import 'theme.dart';

class MigraineForecastApp extends ConsumerStatefulWidget {
  const MigraineForecastApp({super.key});

  @override
  ConsumerState<MigraineForecastApp> createState() => _MigraineForecastAppState();
}

class _MigraineForecastAppState extends ConsumerState<MigraineForecastApp> {
  late final AppLifecycleObserver _observer;
  late final GoRouter _router;
  // Notifies the router to re-run its redirect when onboarding state changes.
  final ValueNotifier<int> _routerRefresh = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    // Build the router once. Rebuilding it on every theme/palette change would
    // create a fresh GoRouter and reset navigation to initialLocation, kicking
    // the user off whatever screen they were on (e.g. Settings).
    _router = buildRouter(ref, refreshListenable: _routerRefresh);
    _observer = AppLifecycleObserver(
      staleAfter: const Duration(hours: 6),
      lastRefreshAt: () async {
        return ref.read(assessmentRepoProvider).latestComputedAt();
      },
      refresh: () async {
        await ref.read(riskAssessmentProvider.notifier).refresh();
      },
    );
    WidgetsBinding.instance.addObserver(_observer);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_observer);
    _routerRefresh.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Bump the router refresh when onboarding completion resolves/changes so the
    // memoized router re-evaluates its redirect.
    ref.listen(onboardingCompletedProvider, (_, __) => _routerRefresh.value++);
    final hasActiveAttack = ref.watch(activeAttackProvider).asData?.value ?? false;
    final mode = ref.watch(comfortModeProvider).asData?.value ?? ComfortMode.auto;
    final paletteChoice =
        ref.watch(darkPaletteProvider).asData?.value ?? DarkPaletteChoice.classic;
    final comfort = mode == ComfortMode.always || (mode == ComfortMode.auto && hasActiveAttack);
    final activeTheme =
        comfort ? buildComfortTheme(paletteFor(paletteChoice)) : buildLightTheme();
    return MaterialApp.router(
      title: 'Migraine Forecast',
      theme: activeTheme,
      darkTheme: activeTheme,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
