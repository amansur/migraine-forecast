import 'package:equatable/equatable.dart';

/// Identifies a class of input the engine needs for a given module.
class DataRequirement extends Equatable {
  final String id;     // e.g., "weather.pressure", "health.sleep"
  final String label;  // human-readable label for UI
  const DataRequirement({required this.id, required this.label});

  static const weatherPressure   = DataRequirement(id: 'weather.pressure',   label: 'Weather (pressure)');
  static const weatherHumidity   = DataRequirement(id: 'weather.humidity',   label: 'Weather (humidity)');
  static const weatherAirQuality = DataRequirement(id: 'weather.air_quality', label: 'Air quality');
  static const healthSleep       = DataRequirement(id: 'health.sleep',       label: 'Sleep data');
  static const healthHrv         = DataRequirement(id: 'health.hrv',         label: 'HRV data');
  static const healthMenstrual   = DataRequirement(id: 'health.menstrual',   label: 'Menstrual data');
  static const journalAlcohol    = DataRequirement(id: 'journal.alcohol',    label: 'Alcohol log');
  static const journalCaffeine   = DataRequirement(id: 'journal.caffeine',   label: 'Caffeine log');
  static const journalStress     = DataRequirement(id: 'journal.stress',     label: 'Stress log');
  static const journalHydration  = DataRequirement(id: 'journal.hydration',  label: 'Hydration log');
  static const attackHistory     = DataRequirement(id: 'attacks.history',    label: 'Attack history');

  @override
  List<Object?> get props => [id];
}
