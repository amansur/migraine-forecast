import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/lifecycle_observer.dart';
import '../state/risk_assessment_provider.dart';
import 'router.dart';
import 'theme.dart';

class MigraineWeatherrApp extends ConsumerStatefulWidget {
  const MigraineWeatherrApp({super.key});

  @override
  ConsumerState<MigraineWeatherrApp> createState() => _MigraineWeatherrAppState();
}

class _MigraineWeatherrAppState extends ConsumerState<MigraineWeatherrApp> {
  late final AppLifecycleObserver _observer;

  @override
  void initState() {
    super.initState();
    _observer = AppLifecycleObserver(
      staleAfter: const Duration(hours: 6),
      lastRefreshAt: () async {
        // Plan 5 will read the last RiskAssessment.computedAt; for now,
        // return null on first run so refresh is skipped.
        return null;
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
      title: 'Migraine Weatherr',
      theme: buildLightTheme(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
