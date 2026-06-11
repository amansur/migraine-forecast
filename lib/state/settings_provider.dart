import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

enum RiskDisplayMode { gauge, numeric, weatherIcon }

final riskDisplayModeProvider = FutureProvider<RiskDisplayMode>((ref) async {
  final s = await ref.watch(settingsRepoProvider).getString('display_mode');
  return RiskDisplayMode.values.firstWhere(
    (m) => m.name == s,
    orElse: () => RiskDisplayMode.gauge,
  );
});

final setRiskDisplayModeProvider = Provider<Future<void> Function(RiskDisplayMode)>((ref) {
  return (mode) async {
    await ref.read(settingsRepoProvider).setString('display_mode', mode.name);
    ref.invalidate(riskDisplayModeProvider);
  };
});

final notificationsEnabledProvider = FutureProvider<bool>((ref) async {
  return ref.watch(settingsRepoProvider).getBool('notifications_enabled');
});

final setNotificationsEnabledProvider = Provider<Future<void> Function(bool)>((ref) {
  return (enabled) async {
    await ref.read(settingsRepoProvider).setBool('notifications_enabled', enabled);
    ref.invalidate(notificationsEnabledProvider);
  };
});
