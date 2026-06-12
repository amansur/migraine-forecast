enum TemperatureUnit { celsius, fahrenheit }
enum PressureUnit { hpa, mmhg }

class UnitFormatter {
  final TemperatureUnit temperatureUnit;
  final PressureUnit pressureUnit;

  const UnitFormatter({
    this.temperatureUnit = TemperatureUnit.celsius,
    this.pressureUnit = PressureUnit.hpa,
  });

  /// Converts °C/°ΔC and hPa values in a domain explanation string to the user's preferred units.
  /// Temperatures are rounded to whole degrees for display; the underlying values keep full precision.
  String formatExplanation(String explanation) {
    var s = explanation;
    if (temperatureUnit == TemperatureUnit.fahrenheit) {
      // Temperature deltas (swings, ranges) — multiply only, no offset
      s = s.replaceAllMapped(
        RegExp(r'(-?\d+\.?\d*)°ΔC'),
        (m) {
          final c = double.parse(m.group(1)!);
          return '${(c * 9 / 5).round()}°F';
        },
      );
      // Absolute temperatures
      s = s.replaceAllMapped(
        RegExp(r'(-?\d+\.?\d*)°C'),
        (m) {
          final c = double.parse(m.group(1)!);
          return '${(c * 9 / 5 + 32).round()}°F';
        },
      );
    } else {
      // Round Celsius (delta or absolute) to whole degrees for display.
      s = s.replaceAllMapped(
        RegExp(r'(-?\d+\.?\d*)°(?:Δ)?C'),
        (m) => '${double.parse(m.group(1)!).round()}°C',
      );
    }
    if (pressureUnit == PressureUnit.mmhg) {
      s = s.replaceAllMapped(
        RegExp(r'(\d+\.?\d*) hPa'),
        (m) {
          final hpa = double.parse(m.group(1)!);
          final mmhg = hpa * 0.750062;
          return '${mmhg.toStringAsFixed(1)} mmHg';
        },
      );
    }
    return s;
  }

  String formatTemperature(double celsius) {
    if (temperatureUnit == TemperatureUnit.fahrenheit) {
      final f = celsius * 9 / 5 + 32;
      return '${f.round()}°F';
    }
    return '${celsius.round()}°C';
  }

  String formatPressure(double hpa) {
    if (pressureUnit == PressureUnit.mmhg) {
      final mmhg = hpa * 0.750062;
      return '${mmhg.toStringAsFixed(1)} mmHg';
    }
    return '${hpa.toStringAsFixed(1)} hPa';
  }
}
