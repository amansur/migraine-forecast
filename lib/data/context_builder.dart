import 'package:domain/domain.dart';

import 'database.dart' hide WeatherSnapshot;
import 'repos/baseline_snapshot_builder.dart';
import 'repos/location_overrides_repo.dart';
import 'sources/health_source.dart';
import 'sources/journal_source.dart';
import 'sources/location_source.dart';
import 'sources/weather_source.dart';

abstract class UserTriggerFlagsRepo {
  Future<UserTriggerFlags> load();
  Future<void> save(UserTriggerFlags flags);
}

class ContextBuilder {
  final WeatherSource weather;
  final HealthSource health;
  final JournalSource journal;
  final LocationSource location;
  final UserTriggerFlagsRepo flagsRepo;
  final BaselineSnapshotBuilder baselineBuilder;
  final AppDatabase db;
  /// Optional. When provided, [build] resolves the effective location for
  /// [target] from this repo first (falls back to [location] if no override).
  final LocationOverridesRepo? locationOverrides;

  const ContextBuilder({
    required this.weather,
    required this.health,
    required this.journal,
    required this.location,
    required this.flagsRepo,
    required this.baselineBuilder,
    required this.db,
    this.locationOverrides,
  });

  Future<EvaluationContext> build({required DateTime now, required DateTime target}) async {
    // Resolve effective location: per-day override takes priority over live GPS.
    final overrideLoc = await locationOverrides?.forDay(target);
    final loc = overrideLoc ?? await location.current();
    WeatherSnapshot? weatherSnap;
    if (loc != null) {
      try {
        // Pass `target` as `now` so OpenMeteoWeatherSource computes the correct
        // pastDays / uses the archive API for days > 30 days ago.
        weatherSnap = await weather.fetch(lat: loc.lat, lon: loc.lon, now: target);
      } catch (_) {
        // Foreground risk should degrade gracefully when weather is unavailable
        // (we can still score from sleep/HRV/journal). Backfill callers that
        // need weather to be present should check ctx.weather != null after.
        weatherSnap = null;
      }
    }

    final metrics = await health.recentMetrics(window: const Duration(days: 30));
    final journalEntries = await journal.recentEntries(const Duration(days: 7), now: now);
    final attacks = await journal.recentAttacks(const Duration(days: 14), now: now);
    final flags = await flagsRepo.load();

    final baselines = baselineBuilder.build(
      sleep: metrics.recentSleep,
      hrv: metrics.recentHrv,
      pastDailyCaffeineMg: const [],   // Plan 5 will derive these from journal history
      pastPressures: const [],
    );

    return EvaluationContext(
      now: now,
      targetDate: target,
      weather: weatherSnap?.weather,
      airQuality: weatherSnap?.airQuality,
      health: metrics,
      recentJournal: journalEntries,
      recentAttacks: attacks,
      userFlags: flags,
      baselines: baselines,
    );
  }
}
