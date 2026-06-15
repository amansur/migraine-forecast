import 'package:domain/domain.dart';
import 'package:flutter/foundation.dart';

import 'context_builder.dart';
import 'repos/assessment_repository.dart';
import 'sources/location_source.dart';
import 'sources/weather_source.dart';

/// Summary returned by [BulkBackfillOrchestrator.run].
class BackfillReport {
  final int daysProcessed;
  final int daysSkipped;
  final int daysFailed;
  final bool weatherFetchSucceeded;
  final Object? firstError;

  const BackfillReport({
    required this.daysProcessed,
    required this.daysSkipped,
    required this.daysFailed,
    required this.weatherFetchSucceeded,
    this.firstError,
  });
}

/// Fills [RiskAssessments] rows for every calendar day in the backfill window
/// so the correlation engine has denominator data from day one.
///
/// Design notes:
/// - One network fetch primes the weather cache with past_days = window.inDays
///   (clamped to 90). All per-day [ContextBuilder.build] calls reuse that
///   cached row via the coverage-aware cache lookup — zero additional requests.
/// - Days that already have a 'today' assessment are skipped (idempotent).
/// - A single-day error is logged but does not abort the run; partial backfill
///   is still useful.
/// - Windows > 90 days: days beyond the forecast API limit fall back to
///   individual archive fetches inside [OpenMeteoWeatherSource].
class BulkBackfillOrchestrator {
  final ContextBuilder contextBuilder;
  final RiskEngine riskEngine;
  final RulesConfig rulesConfig;
  final AssessmentRepository assessmentRepo;
  final LocationSource locationSource;
  final WeatherSource weatherSource;

  BulkBackfillOrchestrator({
    required this.contextBuilder,
    required this.riskEngine,
    required this.rulesConfig,
    required this.assessmentRepo,
    required this.locationSource,
    required this.weatherSource,
  });

  // The inner `_running` guard that previously lived here was dead code:
  // `launchBackfill` constructs a fresh orchestrator on every call, so the
  // per-instance flag never observed re-entry. The real concurrency guard is
  // the module-level `_backfillRunning` flag in backfill_provider.dart.

  Future<BackfillReport> run({
    Duration window = const Duration(days: 90),
    void Function(int done, int total)? onProgress,
  }) async {
    final now = DateTime.now().toUtc();
    final today = DateTime.utc(now.year, now.month, now.day);
    final cutoff = today.subtract(window);

    // Build ordered set of UTC-midnight days in [cutoff, today).
    final allDays = <DateTime>[];
    var d = cutoff;
    while (d.isBefore(today)) {
      allDays.add(d);
      d = d.add(const Duration(days: 1));
    }

    // Determine which days already have an assessment.
    final existing = await assessmentRepo.existingDatesInWindow(
      cutoff: cutoff,
      horizon: RiskHorizon.today,
    );
    final missingDays = allDays.where((day) => !existing.contains(day)).toList();

    if (missingDays.isEmpty) {
      return BackfillReport(
        daysProcessed: 0,
        daysSkipped: allDays.length,
        daysFailed: 0,
        weatherFetchSucceeded: true,
      );
    }

    // ContextBuilder.build pulls location and weather per-day; an upfront
    // location null-check still gives a clean early return when permissions
    // are denied so we don't waste 90 iterations.
    final loc = await locationSource.current();
    if (loc == null) {
      return BackfillReport(
        daysProcessed: 0,
        daysSkipped: allDays.length,
        daysFailed: 0,
        weatherFetchSucceeded: false,
        firstError: 'location unavailable',
      );
    }

    // Prime the weather cache with a single wide fetch covering the full window.
    // The per-day loop's ContextBuilder.build calls then find this row via the
    // coverage-aware cache lookup and make zero additional network requests.
    //
    // The window is clamped to 90 (forecast API max). Days > 90 ago will fall
    // back to individual archive fetches inside OpenMeteoWeatherSource.
    bool weatherFetchSucceeded = true;
    try {
      await weatherSource.fetch(
        lat: loc.lat,
        lon: loc.lon,
        now: now,
        forceRefresh: true,
        pastDays: window.inDays.clamp(1, 90),
      );
    } catch (e, st) {
      weatherFetchSucceeded = false;
      debugPrint('BulkBackfillOrchestrator: prime fetch failed: $e\n$st');
      // Continue — per-day loop falls back to stale cache or individual fetches.
    }

    int processed = 0;
    Object? firstError;

    for (final day in missingDays) {
      try {
        final endOfDay = DateTime.utc(day.year, day.month, day.day, 23, 59, 59);
        final ctx = await contextBuilder.build(now: endOfDay, target: day);

        // Skip days where weather is unavailable (cache miss for that sub-range).
        // Health data degrades naturally for days > 30 days ago (no sleep/HRV);
        // this is expected and reflected in contributor confidence scores.
        final raw = riskEngine.evaluate(ctx, rulesConfig, horizon: RiskHorizon.today);
        final assessment = RiskAssessment(
          score: raw.score,
          band: raw.band,
          contributors: raw.contributors,
          computedAt: raw.computedAt,
          configVersion: raw.configVersion,
          targetDate: raw.targetDate,
          horizon: raw.horizon,
          backfilled: true,
        );
        await assessmentRepo.save(assessment);
        processed++;
        onProgress?.call(processed, missingDays.length);
      } catch (e, st) {
        firstError ??= e;
        debugPrint('BulkBackfillOrchestrator: failed for $day: $e\n$st');
      }
    }

    return BackfillReport(
      daysProcessed: processed,
      daysSkipped: allDays.length - missingDays.length,
      daysFailed: missingDays.length - processed,
      weatherFetchSucceeded: weatherFetchSucceeded,
      firstError: firstError,
    );
  }
}
