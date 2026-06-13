import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

/// Recent logged periods (last 365 days, newest first).
final recentPeriodsProvider = StreamProvider<List<PeriodEvent>>((ref) {
  final journal = ref.watch(journalSourceProvider);
  return journal.watchRecentPeriods(const Duration(days: 365), now: DateTime.now().toUtc());
});

/// Recent per-day severity overrides (last 365 days).
final recentPeriodDaySeveritiesProvider = StreamProvider<List<PeriodDaySeverity>>((ref) {
  final journal = ref.watch(journalSourceProvider);
  return journal.watchRecentPeriodDaySeverities(const Duration(days: 365), now: DateTime.now().toUtc());
});

/// The in-progress period (most recent with null endedAt), or null.
final currentPeriodProvider = Provider<PeriodEvent?>((ref) {
  final periods = ref.watch(recentPeriodsProvider).asData?.value ?? const <PeriodEvent>[];
  for (final p in periods) {
    if (p.endedAt == null) return p;
  }
  return null;
});

/// Phase result for a given day.
final dayPhaseProvider = Provider.family<PhaseResult, DateTime>((ref, day) {
  final periods = ref.watch(recentPeriodsProvider).asData?.value ?? const <PeriodEvent>[];
  final overrides = ref.watch(recentPeriodDaySeveritiesProvider).asData?.value ??
      const <PeriodDaySeverity>[];
  return phaseFor(day, periods: periods, overrides: overrides);
});

/// Effective severity for a day inside a logged period: override if present,
/// else parent baselineSeverity. Returns null if [day] is outside any logged
/// period.
final effectiveDaySeverityProvider = Provider.family<int?, DateTime>((ref, day) {
  final periods = ref.watch(recentPeriodsProvider).asData?.value ?? const <PeriodEvent>[];
  final overrides = ref.watch(recentPeriodDaySeveritiesProvider).asData?.value ??
      const <PeriodDaySeverity>[];
  final target = DateTime.utc(day.year, day.month, day.day);

  for (final ov in overrides) {
    final od = ov.day.toUtc();
    if (DateTime.utc(od.year, od.month, od.day).isAtSameMomentAs(target)) {
      return ov.severity;
    }
  }

  for (final p in periods) {
    final start = p.startedAt.toUtc();
    final startDay = DateTime.utc(start.year, start.month, start.day);
    final end = p.endedAt?.toUtc() ?? startDay.add(const Duration(days: 4));
    final endDay = DateTime.utc(end.year, end.month, end.day);
    if (!target.isBefore(startDay) && !target.isAfter(endDay)) {
      return p.baselineSeverity;
    }
  }
  return null;
});
