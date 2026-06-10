import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('WeatherSeries', () {
    test('returns null delta for empty series', () {
      final s = WeatherSeries(samples: const []);
      expect(s.maxPressureDropOver(Duration(hours: 24)), isNull);
    });

    test('computes max 24h pressure drop within window', () {
      final start = DateTime.utc(2026, 6, 10, 0);
      final samples = [
        WeatherSample(at: start, pressureMsl: 1015, temperatureC: 20, humidityPct: 50),
        WeatherSample(at: start.add(Duration(hours: 12)), pressureMsl: 1012, temperatureC: 20, humidityPct: 50),
        WeatherSample(at: start.add(Duration(hours: 24)), pressureMsl: 1008, temperatureC: 20, humidityPct: 50),
        WeatherSample(at: start.add(Duration(hours: 36)), pressureMsl: 1005, temperatureC: 20, humidityPct: 50),
      ];
      final s = WeatherSeries(samples: samples);
      // Largest 24h drop ends at hour 36: 1012 -> 1005 = 7 hPa
      expect(s.maxPressureDropOver(Duration(hours: 24)), closeTo(7.0, 0.01));
    });
  });
}
