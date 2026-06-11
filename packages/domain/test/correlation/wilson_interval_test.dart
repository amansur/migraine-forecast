import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('WilsonInterval', () {
    test('empty trial returns (0,1) wide interval', () {
      final ci = WilsonInterval.compute(successes: 0, trials: 0);
      expect(ci.low, 0.0);
      expect(ci.high, 1.0);
    });

    test('all-success at n=10, z=1.645 (90%)', () {
      final ci = WilsonInterval.compute(successes: 10, trials: 10);
      expect(ci.low, greaterThan(0.7));
      expect(ci.high, 1.0);
    });

    test('half-and-half at n=20 returns a symmetric-ish interval around 0.5', () {
      final ci = WilsonInterval.compute(successes: 10, trials: 20);
      expect(ci.point, 0.5);
      expect(ci.low, closeTo(0.32, 0.05));
      expect(ci.high, closeTo(0.68, 0.05));
    });

    test('rare success: 1 of 30 has low CI bound near 0', () {
      final ci = WilsonInterval.compute(successes: 1, trials: 30);
      expect(ci.low, lessThan(0.05));
      expect(ci.high, greaterThan(0.05));
      expect(ci.high, lessThan(0.2));
    });

    test('liftDifference returns the right direction and width', () {
      final fired = WilsonInterval.compute(successes: 18, trials: 20);
      final notFired = WilsonInterval.compute(successes: 6, trials: 20);
      final lift = WilsonInterval.differenceLift(fired, notFired);
      expect(lift.point, closeTo(0.6, 0.01));
      expect(lift.low, greaterThan(0.3));
      expect(lift.high, lessThan(1.0));
    });
  });
}
