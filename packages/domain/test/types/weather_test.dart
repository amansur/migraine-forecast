import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('WeatherSeries', () {
    test('returns null delta for empty series', () {
      final s = const WeatherSeries(samples: []);
      expect(s.maxPressureDropOver(const Duration(hours: 24)), isNull);
    });

    test('computes max 24h pressure drop within window', () {
      final start = DateTime.utc(2026, 6, 10, 0);
      final samples = [
        WeatherSample(at: start, pressureMsl: 1015, temperatureC: 20, humidityPct: 50),
        WeatherSample(at: start.add(const Duration(hours: 12)), pressureMsl: 1012, temperatureC: 20, humidityPct: 50),
        WeatherSample(at: start.add(const Duration(hours: 24)), pressureMsl: 1008, temperatureC: 20, humidityPct: 50),
        WeatherSample(at: start.add(const Duration(hours: 36)), pressureMsl: 1005, temperatureC: 20, humidityPct: 50),
      ];
      final s = WeatherSeries(samples: samples);
      // Largest 24h drop ends at hour 36: 1012 -> 1005 = 7 hPa
      expect(s.maxPressureDropOver(const Duration(hours: 24)), closeTo(7.0, 0.01));
    });

    group('window-bounded helpers', () {
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

      test('maxPressureDropInWindow ignores out-of-window samples', () {
        // [t0, t0+24h] sees only the first three; max drop = 1015 - 1008 = 7
        final past = s.maxPressureDropInWindow(t0, t0.add(const Duration(hours: 24)));
        expect(past, closeTo(7.0, 0.01));
        // [t0+24h, t0+48h] sees last three; max drop = 1008 - 995 = 13
        final future = s.maxPressureDropInWindow(
          t0.add(const Duration(hours: 24)),
          t0.add(const Duration(hours: 48)),
        );
        expect(future, closeTo(13.0, 0.01));
      });

      test('tempSwingInWindow / tempTrendInWindow respect bounds', () {
        // Past [t0, t0+24h]: temps 15, 22, 20 -> swing 7, trend = 20 - 15 = 5
        expect(s.tempSwingInWindow(t0, t0.add(const Duration(hours: 24))), closeTo(7, 0.01));
        expect(s.tempTrendInWindow(t0, t0.add(const Duration(hours: 24))), closeTo(5, 0.01));
      });

      test('humidityTrendInWindow / maxHumidityInWindow respect bounds', () {
        // Past [t0, t0+24h]: 50 -> 70, max 70
        expect(s.humidityTrendInWindow(t0, t0.add(const Duration(hours: 24))), closeTo(20, 0.01));
        expect(s.maxHumidityInWindow(t0, t0.add(const Duration(hours: 24))), 70);
      });

      test('returns null when window has no samples', () {
        final out = t0.subtract(const Duration(days: 10));
        expect(s.maxPressureDropInWindow(out, out.add(const Duration(hours: 1))), isNull);
        expect(s.tempSwingInWindow(out, out.add(const Duration(hours: 1))), isNull);
        expect(s.humidityTrendInWindow(out, out.add(const Duration(hours: 1))), isNull);
      });
    });
  });
}
