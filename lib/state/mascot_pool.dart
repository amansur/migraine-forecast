import 'package:domain/domain.dart';

String _p(String name) => 'assets/mascots/$name.png';

/// Mood-matched mascot pool per risk band. Icons may appear in several
/// bands. Sliced from assets/icons.png (see tool/slice_mascots.py).
final Map<RiskBand, List<String>> kMascotPool = {
  RiskBand.low: [
    _p('sun'), _p('big_star'), _p('small_flower'), _p('butterfly'),
  ],
  RiskBand.moderate: [
    _p('berry_pot'), _p('fish'), _p('teacup'), _p('notebook'),
    _p('potted_plant'), _p('snail'),
  ],
  RiskBand.high: [
    _p('sprout'), _p('cat'), _p('sleepy_cloud'),
  ],
  RiskBand.veryHigh: [
    _p('raining_cloud'), _p('sad_flower'), _p('sleepy_cloud'),
  ],
};

/// Picks today's mascot for [band]: deterministic for a given local
/// calendar date + band, changes daily. Cadence is intentionally isolated
/// here — to change it (per-launch, manual shuffle), swap the seed.
String mascotAssetFor(RiskBand band, {DateTime? date}) {
  final d = date ?? DateTime.now();
  final pool = kMascotPool[band]!;
  assert(pool.isNotEmpty);
  final seed = d.year * 10000 + d.month * 100 + d.day + band.index * 31;
  return pool[seed % pool.length];
}

/// Every pooled asset path, deduped — used for startup pre-caching.
List<String> allMascotAssetPaths() =>
    {for (final paths in kMascotPool.values) ...paths}.toList();
