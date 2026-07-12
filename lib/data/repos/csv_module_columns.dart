/// Module ids that get per-module contribution/explanation columns in the
/// risk-assessments CSV. Shared by [ExportRepo] and [ImportRepo] so the two
/// can't drift apart.
///
/// Order is the CSV column order — append new modules at the end so older
/// exports keep their column layout (import resolves columns by header name,
/// so order changes wouldn't break correctness, only diff-friendliness).
/// Must cover every id in `allTriggerModules()`; a test enforces this.
const csvModuleColumns = [
  'pressure_drop', 'humidity', 'temp_swing', 'air_quality',
  'stress', 'sleep_deficit', 'alcohol', 'caffeine', 'hydration', 'menstrual_phase',
  'skipped_meals', 'wind',
  'hrv_letdown', 'refractory', 'intraday_pressure_swing',
];
