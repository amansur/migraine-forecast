/// Single source of truth for module-id → display label. New trigger modules
/// must be added here (and to contributor_order.dart).
const moduleLabels = <String, String>{
  'pressure_drop': 'Pressure changes',
  'humidity': 'Humidity',
  'temp_swing': 'Temp swing',
  'air_quality': 'Air quality',
  'sleep_deficit': 'Sleep',
  'hrv_letdown': 'HRV / stress let-down',
  'menstrual_phase': 'Menstrual cycle',
  'refractory': 'Recent attack',
  'alcohol': 'Alcohol',
  'caffeine': 'Caffeine',
  'stress': 'Stress',
  'hydration': 'Hydration',
  'intraday_pressure_swing': 'Pressure volatility',
  'skipped_meals': 'Skipped meals',
  'wind': 'Strong wind',
};

String moduleLabel(String id) => moduleLabels[id] ?? id;
