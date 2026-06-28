import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/sources/location_source.dart';
import 'mascot_character.dart';
import '../ui/shared/unit_formatter.dart';
import 'providers.dart';
import 'risk_assessment_provider.dart';

enum HealthSourcePreference { oura, appleHealth }

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

/// Cycle tracking is opt-in — defaults to false on a fresh install. The
/// "on" state is stored explicitly as "true" in settings.
final cycleTrackingEnabledProvider = FutureProvider<bool>((ref) async {
  final s = await ref.watch(settingsRepoProvider).getString('cycle_tracking_enabled');
  return s == 'true';
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

enum ComfortMode { off, auto, always }

final comfortModeProvider = FutureProvider<ComfortMode>((ref) async {
  final repo = ref.watch(settingsRepoProvider);
  final raw = await repo.getString('comfort_mode');
  if (raw != null) {
    return ComfortMode.values.firstWhere(
      (m) => m.name == raw,
      orElse: () => ComfortMode.auto,
    );
  }
  final legacy = await repo.getString('auto_comfort_mode');
  return legacy == 'false' ? ComfortMode.off : ComfortMode.auto;
});

final setComfortModeProvider = Provider<Future<void> Function(ComfortMode)>((ref) {
  return (mode) async {
    await ref.read(settingsRepoProvider).setString('comfort_mode', mode.name);
    ref.invalidate(comfortModeProvider);
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

final healthSourcePreferenceProvider = StateNotifierProvider<
    HealthSourcePreferenceNotifier,
    HealthSourcePreference>((ref) {
  return HealthSourcePreferenceNotifier();
});

// TODO(oura): persist via SettingsRepo. Currently resets on app restart.
// Migrating requires switching to FutureProvider<HealthSourcePreference> +
// a setter provider (matching the pattern used by riskDisplayModeProvider),
// which changes the type at all UI call sites.
class HealthSourcePreferenceNotifier extends StateNotifier<HealthSourcePreference> {
  HealthSourcePreferenceNotifier() : super(HealthSourcePreference.appleHealth);

  void setPreference(HealthSourcePreference preference) {
    state = preference;
  }
}

final healthMetricsRefreshingProvider = StateProvider<bool>((ref) => false);

final mascotCharacterProvider = FutureProvider<MascotCharacter>((ref) async {
  final s = await ref.watch(settingsRepoProvider).getString('mascot_character');
  return MascotCharacter.values.firstWhere(
    (c) => c.name == s,
    orElse: () => kDefaultMascotCharacter,
  );
});

final setMascotCharacterProvider = Provider<Future<void> Function(MascotCharacter)>((ref) {
  return (character) async {
    await ref.read(settingsRepoProvider).setString('mascot_character', character.name);
    ref.invalidate(mascotCharacterProvider);
  };
});
