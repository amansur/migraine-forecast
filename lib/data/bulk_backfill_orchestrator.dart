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
/// - One network fetch primes the weather cache with past_days = 92 (today + 2
///   padding). All per-day [ContextBuilder.build] calls reuse that cached row.
/// - Days that already have a 'today' assessment are skipped (idempotent).
/// - A single-day error is logged but does not abort the run; partial backfill
///   is still useful.
/// - TODO(v2): for windows > 90 days, fall back to Open-Meteo Archive API
///   (archive-api.open-meteo.com/v1/archive).
class BulkBackfillOrchestrator {
  final ContextBuilder contextBuilder;
  final RiskEngine riskEngine;
  final RulesConfig rulesConfig;
  final AssessmentRepository assessmentRepo;
  final LocationSource locationSource;
  final WeatherSource weatherSource;

  bool _running = false;

  BulkBackfillOrchestrator({
    required this.contextBuilder,
    required this.riskEngine,
    required this.rulesConfig,
    required this.assessmentRepo,
    required this.locationSource,
    required this.weatherSource,
  });

  Future<BackfillReport> run({
    Duration window = const Duration(days: 90),
    void Function(int done, int total)? onProgress,
  }) async {
    if (_running) {
      return const BackfillReport(
        daysProcessed: 0,
        daysSkipped: 0,
        daysFailed: 0,
        weatherFetchSucceeded: false,
        firstError: 'backfill already running',
      );
    }
    _running = true;

    try {
      return await _run(window: window, onProgress: onProgress);
    } finally {
      _running = false;
    }
  }

  Future<BackfillReport> _run({
    required Duration window,
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

    // Prime the weather cache with one forced fetch covering the full window.
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

    try {
      await weatherSource.fetch(
        lat: loc.lat,
        lon: loc.lon,
        now: now,
        forceRefresh: true,
      );
    } catch (e) {
      debugPrint('BulkBackfillOrchestrator: weather prime failed: $e');
      return BackfillReport(
        daysProcessed: 0,
        daysSkipped: allDays.length,
        daysFailed: 0,
        weatherFetchSucceeded: false,
        firstError: e,
      );
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
      weatherFetchSucceeded: true,
      firstError: firstError,
    );
  }
}
