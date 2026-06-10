import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('BaselineStore', () {
    test('sleep median over 7 days', () {
      final hours = [7.0, 6.5, 8.0, 5.5, 7.5, 6.0, 7.0];
      final store = BaselineStore();
      final median = store.medianSleepHours(hours);
      expect(median, 7.0);
    });

    test('returns null when fewer than `minSamples` data points', () {
      final store = BaselineStore();
      expect(store.hrvRmssdBaseline([50.0, 52.0], minSamples: 10), isNull);
    });

    test('hrv baseline is a median over the trailing window', () {
      final store = BaselineStore();
      final values = List.generate(14, (i) => (40 + i).toDouble());
      final baseline = store.hrvRmssdBaseline(values, minSamples: 10);
      expect(baseline, 46.5); // median of 40..53 = (46+47)/2
    });

    test('pressure baseline uses recent samples median', () {
      final store = BaselineStore();
      final pressures = [1015.0, 1014.5, 1016.0, 1013.0, 1015.5];
      expect(store.pressureBaseline(pressures), 1015.0);
    });
  });
}
