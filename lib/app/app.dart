import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'theme.dart';

class MigraineWeatherrApp extends ConsumerWidget {
  const MigraineWeatherrApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = buildRouter(ref);
    return MaterialApp.router(
      title: 'Migraine Weatherr',
      theme: buildLightTheme(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
