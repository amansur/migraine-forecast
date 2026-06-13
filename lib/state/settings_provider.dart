import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/sources/location_source.dart';
import '../ui/shared/unit_formatter.dart';
import 'providers.dart';
import 'risk_assessment_provider.dart';

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

/// Cycle tracking is opt-out — defaults to true on a fresh install. The
/// "off" state is stored explicitly as "false" in settings.
final cycleTrackingEnabledProvider = FutureProvider<bool>((ref) async {
  final s = await ref.watch(settingsRepoProvider).getString('cycle_tracking_enabled');
  return s != 'false';
});

final setCycleTrackingEnabledProvider = Provider<Future<void> Function(bool)>((ref) {
  return (enabled) async {
    await ref.read(settingsRepoProvider).setBool('cycle_tracking_enabled', enabled);
    ref.invalidate(cycleTrackingEnabledProvider);
  };
});

final setNotificationsEnabledProvider = Provider<Future<void> Function(bool)>((ref) {
  return (enabled) async {
    await ref.read(settingsRepoProvider).setBool('notifications_enabled', enabled);
    ref.invalidate(notificationsEnabledProvider);
  };
});

final temperatureUnitProvider = FutureProvider<TemperatureUnit>((ref) async {
  final s = await ref.watch(settingsRepoProvider).getString('temperature_unit');
  return s == 'celsius' ? TemperatureUnit.celsius : TemperatureUnit.fahrenheit;
});

final setTemperatureUnitProvider = Provider<Future<void> Function(TemperatureUnit)>((ref) {
  return (unit) async {
    await ref.read(settingsRepoProvider).setString('temperature_unit', unit.name);
    ref.invalidate(temperatureUnitProvider);
    ref.invalidate(unitFormatterProvider);
  };
});

final pressureUnitProvider = FutureProvider<PressureUnit>((ref) async {
  final s = await ref.watch(settingsRepoProvider).getString('pressure_unit');
  return s == 'hpa' ? PressureUnit.hpa : PressureUnit.mmhg;
});

final setPressureUnitProvider = Provider<Future<void> Function(PressureUnit)>((ref) {
  return (unit) async {
    await ref.read(settingsRepoProvider).setString('pressure_unit', unit.name);
    ref.invalidate(pressureUnitProvider);
    ref.invalidate(unitFormatterProvider);
  };
});

final unitFormatterProvider = FutureProvider<UnitFormatter>((ref) async {
  final temp = await ref.watch(temperatureUnitProvider.future);
  final pressure = await ref.watch(pressureUnitProvider.future);
  return UnitFormatter(temperatureUnit: temp, pressureUnit: pressure);
});

final manualLocationProvider = FutureProvider<UserLocation?>((ref) async {
  return ref.watch(manualLocationSourceProvider).current();
});

final setManualLocationProvider = Provider<Future<void> Function(double lat, double lon)>((ref) {
  return (lat, lon) async {
    await ref.read(manualLocationSourceProvider).set(lat: lat, lon: lon);
    ref.invalidate(manualLocationProvider);
    ref.invalidate(riskAssessmentProvider);
    ref.invalidate(tomorrowRiskAssessmentProvider);
  };
});

final clearManualLocationProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    await ref.read(manualLocationSourceProvider).clear();
    ref.invalidate(manualLocationProvider);
    ref.invalidate(riskAssessmentProvider);
    ref.invalidate(tomorrowRiskAssessmentProvider);
  };
});
