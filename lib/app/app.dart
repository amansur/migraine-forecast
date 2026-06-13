import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/lifecycle_observer.dart';
import '../state/providers.dart';
import '../state/risk_assessment_provider.dart';
import 'router.dart';
import 'theme.dart';

class MigraineForecastApp extends ConsumerStatefulWidget {
  const MigraineForecastApp({super.key});

  @override
  ConsumerState<MigraineForecastApp> createState() => _MigraineForecastAppState();
}

class _MigraineForecastAppState extends ConsumerState<MigraineForecastApp> {
  late final AppLifecycleObserver _observer;

  @override
  void initState() {
    super.initState();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = buildRouter(ref);
    return MaterialApp.router(
      title: 'Migraine Forecast',
      theme: buildLightTheme(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
