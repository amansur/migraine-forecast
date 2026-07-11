import 'package:equatable/equatable.dart';

import '../types/journal.dart';

class StreakStats extends Equatable {
  final int currentAttackFreeDays;
  final int longestAttackFreeDays;
  const StreakStats(
      {required this.currentAttackFreeDays, required this.longestAttackFreeDays});
  @override
  List<Object?> get props => [currentAttackFreeDays, longestAttackFreeDays];
}

/// [attackDays], [today] and [windowStart] are UTC midnights. The current
/// streak counts attack-free days up to and including [today].
StreakStats computeStreaks({
  required Set<DateTime> attackDays,
  required DateTime today,
  required DateTime windowStart,
}) {
  var current = 0;
  for (var d = today; !d.isBefore(windowStart); d = d.subtract(const Duration(days: 1))) {
    if (attackDays.contains(d)) break;
    current++;
  }
  var longest = 0, run = 0;
  for (var d = windowStart; !d.isAfter(today); d = d.add(const Duration(days: 1))) {
    if (attackDays.contains(d)) {
      run = 0;
    } else {
      run++;
      if (run > longest) longest = run;
    }
  }
  return StreakStats(currentAttackFreeDays: current, longestAttackFreeDays: longest);
}

enum DayPart { night, morning, afternoon, evening }

DayPart dayPartOf(DateTime t) {
  final h = t.hour;
  if (h < 6) return DayPart.night;
  if (h < 12) return DayPart.morning;
  if (h < 18) return DayPart.afternoon;
  return DayPart.evening;
}

/// Buckets attack start times by part of day. Buckets by the hour of the
/// DateTime as given — callers wanting the user's wall-clock must convert
/// with toLocal() first.
Map<DayPart, int> attackStartsByDayPart(Iterable<Attack> attacks) {
  final m = {for (final p in DayPart.values) p: 0};
  for (final a in attacks) {
    final part = dayPartOf(a.startedAt);
    m[part] = m[part]! + 1;
  }
  return m;
}
