import 'dart:math' as math;

/// 90% Wilson score interval for a binomial proportion.
class WilsonInterval {
  final double low;
  final double point;
  final double high;
  final int trials;
  const WilsonInterval({
    required this.low,
    required this.point,
    required this.high,
    required this.trials,
  });

  static const double _z90 = 1.6448536269514722;

  static WilsonInterval compute({required int successes, required int trials}) {
    if (trials == 0) {
      return const WilsonInterval(low: 0, point: 0, high: 1, trials: 0);
    }
    final z = _z90;
    final n = trials.toDouble();
    final p = successes / n;
    final z2 = z * z;
    final denom = 1 + z2 / n;
    final centre = p + z2 / (2 * n);
    final spread = z * math.sqrt((p * (1 - p) + z2 / (4 * n)) / n);
    final low = ((centre - spread) / denom).clamp(0.0, 1.0).toDouble();
    final high = ((centre + spread) / denom).clamp(0.0, 1.0).toDouble();
    return WilsonInterval(low: low, point: p, high: high, trials: trials);
  }

  static LiftInterval differenceLift(WilsonInterval a, WilsonInterval b) {
    final point = a.point - b.point;
    final halfA = (a.high - a.low) / 2.0;
    final halfB = (b.high - b.low) / 2.0;
    final width = math.sqrt(halfA * halfA + halfB * halfB);
    return LiftInterval(
      point: point,
      low: point - width,
      high: point + width,
      a: a,
      b: b,
    );
  }
}

class LiftInterval {
  final double point;
  final double low;
  final double high;
  final WilsonInterval a;
  final WilsonInterval b;
  const LiftInterval({
    required this.point,
    required this.low,
    required this.high,
    required this.a,
    required this.b,
  });

  bool get excludesZero => low > 0 || high < 0;
  bool get pointBelowZero => point < 0 && high < 0;
}
