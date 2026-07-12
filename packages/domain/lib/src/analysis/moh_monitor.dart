import '../types/medication.dart';

enum MohLevel { none, approaching, exceeded }

class MohStatus {
  final MohLevel level;
  final MedClass? medClass;
  final int daysUsed;
  final int thresholdDays;
  const MohStatus(
      {required this.level, this.medClass, this.daysUsed = 0, this.thresholdDays = 0});
}

/// Rolling 30-day approximation of the ICHD-3 medication-overuse-headache
/// criteria (ICHD-3 §8.2): ≥10 days/month for triptans and combination
/// analgesics, ≥15 days/month for simple analgesics (and unclassified
/// abortives, conservatively grouped with them). "Approaching" fires at 80%
/// of threshold. Preventives never count. When several classes qualify, the
/// worst level wins (ties keep the first in threshold-map order).
MohStatus assessMoh(List<MedicationDose> doses, DateTime now) {
  const thresholds = {
    MedClass.triptan: 10,
    MedClass.combination: 10,
    MedClass.simpleAnalgesic: 15,
    MedClass.other: 15,
  };
  final cutoff = now.subtract(const Duration(days: 30));
  MohStatus worst = const MohStatus(level: MohLevel.none);
  for (final entry in thresholds.entries) {
    // Bin by the user's LOCAL calendar day (the convention this codebase
    // uses everywhere) — UTC binning would split or merge evening doses
    // west of UTC, moving the count right at a medically-framed threshold.
    final days = <DateTime>{};
    for (final d in doses) {
      if (d.medClass != entry.key || d.at.isBefore(cutoff)) continue;
      final local = d.at.toLocal();
      days.add(DateTime.utc(local.year, local.month, local.day));
    }
    final used = days.length;
    final threshold = entry.value;
    final level = used >= threshold
        ? MohLevel.exceeded
        : used >= (threshold * 0.8).ceil()
            ? MohLevel.approaching
            : MohLevel.none;
    if (level.index > worst.level.index) {
      worst = MohStatus(
          level: level, medClass: entry.key, daysUsed: used, thresholdDays: threshold);
    }
  }
  return worst;
}
