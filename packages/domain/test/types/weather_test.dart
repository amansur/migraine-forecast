import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('WeatherSeries', () {
    final t0 = DateTime.utc(2026, 6, 10, 0);
    final s = WeatherSeries(samples: [
      // Past 24h relative to t0+24h
      WeatherSample(at: t0, pressureMsl: 1015, temperatureC: 15, humidityPct: 50),
      WeatherSample(at: t0.add(const Duration(hours: 12)), pressureMsl: 1010, temperatureC: 22, humidityPct: 60),
      WeatherSample(at: t0.add(const Duration(hours: 24)), pressureMsl: 1008, temperatureC: 20, humidityPct: 70),
      // Forecast samples
      WeatherSample(at: t0.add(const Duration(hours: 36)), pressureMsl: 1000, temperatureC: 25, humidityPct: 85),
      WeatherSample(at: t0.add(const Duration(hours: 48)), pressureMsl: 995, temperatureC: 18, humidityPct: 90),
    ]);

    test('returns null delta for empty series', () {
      const empty = WeatherSeries(samples: []);
      expect(
        empty.maxPressureDropAround(t0, const Duration(hours: 24), now: t0),
        isNull,
      );
    });

    test('past window: anchor at now sees only the trailing samples', () {
      // anchor = t0+24h, now = t0+24h => past [t0, t0+24h]
      final anchor = t0.add(const Duration(hours: 24));
      // 1015 -> 1008 = 7
      expect(s.maxPressureDropAround(anchor, const Duration(hours: 24), now: anchor), closeTo(7.0, 0.01));
      // temps 15, 22, 20 -> swing 7, trend = 20 - 15 = 5
      expect(s.tempSwingAround(anchor, const Duration(hours: 24), now: anchor), closeTo(7, 0.01));
      expect(s.tempTrendAround(anchor, const Duration(hours: 24), now: anchor), closeTo(5, 0.01));
      // humidity 50 -> 70, max 70
      expect(s.humidityTrendAround(anchor, const Duration(hours: 24), now: anchor), closeTo(20, 0.01));
      expect(s.maxHumidityAround(anchor, const Duration(hours: 24), now: anchor), 70);
    });

    test('future window: anchor after now sees forecast samples', () {
      // anchor = t0+24h, now = t0 => future [t0+24h, t0+48h]
      final anchor = t0.add(const Duration(hours: 24));
      // 1008 -> 995 = 13
      expect(s.maxPressureDropAround(anchor, const Duration(hours: 24), now: t0), closeTo(13.0, 0.01));
    });

    test('returns null when window has no samples', () {
      final out = t0.subtract(const Duration(days: 10));
      expect(s.maxPressureDropAround(out, const Duration(hours: 1), now: out), isNull);
      expect(s.tempSwingAround(out, const Duration(hours: 1), now: out), isNull);
      expect(s.humidityTrendAround(out, const Duration(hours: 1), now: out), isNull);
    });
  });
}
