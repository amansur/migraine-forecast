import '../modules/air_quality.dart';
import '../modules/alcohol.dart';
import '../modules/caffeine.dart';
import '../modules/humidity.dart';
import '../modules/hrv_letdown.dart';
import '../modules/hydration.dart';
import '../modules/intraday_pressure_swing.dart';
import '../modules/menstrual_phase.dart';
import '../modules/pressure_drop.dart';
import '../modules/refractory.dart';
import '../modules/skipped_meal.dart';
import '../modules/sleep_deficit.dart';
import '../modules/stress.dart';
import '../modules/temp_swing.dart';
import 'trigger_module.dart';

/// The single source of truth for the engine's module set. Both the app's
/// riskEngineProvider and the background scheduler construct engines from
/// this list — they had already drifted apart once (the scheduler was
/// missing intraday_pressure_swing) before it existed.
List<TriggerModule> allTriggerModules() => [
      PressureDropModule(),
      HumidityModule(),
      TempSwingModule(),
      AirQualityModule(),
      SleepDeficitModule(),
      HrvLetdownModule(),
      MenstrualPhaseModule(),
      RefractoryModule(),
      AlcoholModule(),
      CaffeineModule(),
      StressModule(),
      HydrationModule(),
      IntradayPressureSwingModule(),
      SkippedMealModule(),
    ];
