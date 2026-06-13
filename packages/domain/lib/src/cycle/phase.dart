import 'package:equatable/equatable.dart';

import '../types/journal.dart';

enum CyclePhase { menses, follicular, ovulatory, luteal }

sealed class PhaseResult extends Equatable {
  const PhaseResult();
}

class PhaseUnknown extends PhaseResult {
  const PhaseUnknown();
  @override
  List<Object?> get props => const [];
}

class PhaseConfirmed extends PhaseResult {
  final CyclePhase phase;
  final int dayOfCycle;
  const PhaseConfirmed(this.phase, this.dayOfCycle);
  @override
  List<Object?> get props => [phase, dayOfCycle];
}

class PhasePredicted extends PhaseResult {
  final CyclePhase phase;
  final int dayOfCycle;
  const PhasePredicted(this.phase, this.dayOfCycle);
  @override
  List<Object?> get props => [phase, dayOfCycle];
}

/// Biological minimum we'll accept as a meaningful cycle length. Below this,
/// the phase boundary math collapses (follicular/ovulatory windows go to
/// zero or negative) and the ribbon would show only menses + luteal. Two
/// period starts <21 days apart almost always indicate a logging mistake
/// (e.g. tapping "Log period" twice in the same week) rather than a real
/// short cycle, so we treat them as no usable signal.
const int _minCycleDays = 21;

/// Mean gap (days) between the last ≤6 consecutive period starts. Null if
/// fewer than 2 periods are logged OR the mean is below the biological
/// minimum (see [_minCycleDays]).
int? meanCycleLength(List<PeriodEvent> periods) {
  if (periods.length < 2) return null;
  final sorted = [...periods]..sort((a, b) => a.startedAt.compareTo(b.startedAt));
  final gaps = <int>[];
  for (var i = 1; i < sorted.length; i++) {
    gaps.add(sorted[i].startedAt.difference(sorted[i - 1].startedAt).inDays);
  }
  final recent = gaps.length <= 6 ? gaps : gaps.sublist(gaps.length - 6);
  final mean = recent.reduce((a, b) => a + b) / recent.length;
  final rounded = mean.round();
  if (rounded < _minCycleDays) return null;
  return rounded;
}

DateTime _utcDay(DateTime d) {
  final u = d.toUtc();
  return DateTime.utc(u.year, u.month, u.day);
}

/// Derives the cycle phase for [day] given logged [periods]. [overrides] is
/// accepted for API symmetry with future scoring; phase derivation does not
/// depend on per-day severity.
PhaseResult phaseFor(
  DateTime day, {
  required List<PeriodEvent> periods,
  required List<PeriodDaySeverity> overrides,
}) {
  final cycleLen = meanCycleLength(periods);
  if (cycleLen == null) return const PhaseUnknown();

  final target = _utcDay(day);
  final sorted = [...periods]..sort((a, b) => a.startedAt.compareTo(b.startedAt));

  // Find nearest preceding period start (anchor).
  PeriodEvent? anchor;
  for (final p in sorted) {
    final s = _utcDay(p.startedAt);
    if (!s.isAfter(target)) {
      anchor = p;
    } else {
      break;
    }
  }
  if (anchor == null) return const PhaseUnknown();

  final anchorStart = _utcDay(anchor.startedAt);
  final dayOffset = target.difference(anchorStart).inDays; // 0-based
  final dayOfCycle = dayOffset + 1; // 1-based for display

  // Menses end (1-based, inclusive): from anchor.endedAt if present, else 5.
  final mensesEnd = anchor.endedAt != null
      ? _utcDay(anchor.endedAt!).difference(anchorStart).inDays + 1
      : 5;
  final follicularEnd = cycleLen - 16; // inclusive
  final ovulatoryEnd = cycleLen - 12; // inclusive

  CyclePhase phase;
  if (dayOfCycle <= mensesEnd) {
    phase = CyclePhase.menses;
  } else if (dayOfCycle <= follicularEnd) {
    phase = CyclePhase.follicular;
  } else if (dayOfCycle <= ovulatoryEnd) {
    phase = CyclePhase.ovulatory;
  } else {
    phase = CyclePhase.luteal;
  }

  // A day is Confirmed if its span is bounded by two observed starts —
  // i.e., the anchor is NOT the most recent logged start. Days anchored by
  // the most recent start project forward and are Predicted.
  final mostRecent = _utcDay(sorted.last.startedAt);
  final isMostRecentAnchor = anchorStart.isAtSameMomentAs(mostRecent);
  return isMostRecentAnchor
      ? PhasePredicted(phase, dayOfCycle)
      : PhaseConfirmed(phase, dayOfCycle);
}
