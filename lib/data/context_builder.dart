import 'package:domain/domain.dart';

import 'database.dart' hide WeatherSnapshot;
import 'repos/baseline_snapshot_builder.dart';
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

  const ContextBuilder({
    required this.weather,
    required this.health,
    required this.journal,
    required this.location,
    required this.flagsRepo,
    required this.baselineBuilder,
    required this.db,
  });

  Future<EvaluationContext> build({required DateTime now, required DateTime target}) async {
    final loc = await location.current();
    WeatherSnapshot? weatherSnap;
    if (loc != null) {
      try {
        weatherSnap = await weather.fetch(lat: loc.lat, lon: loc.lon, now: now);
      } catch (_) {
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
