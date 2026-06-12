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
  String formatExplanation(String explanation) {
    var s = explanation;
    if (temperatureUnit == TemperatureUnit.fahrenheit) {
      // Temperature deltas (swings, ranges) — multiply only, no offset
      s = s.replaceAllMapped(
        RegExp(r'(-?\d+\.?\d*)°ΔC'),
        (m) {
          final c = double.parse(m.group(1)!);
          return '${(c * 9 / 5).toStringAsFixed(1)}°F';
        },
      );
      // Absolute temperatures
      s = s.replaceAllMapped(
        RegExp(r'(-?\d+\.?\d*)°C'),
        (m) {
          final c = double.parse(m.group(1)!);
          return '${(c * 9 / 5 + 32).toStringAsFixed(1)}°F';
        },
      );
    } else {
      // Strip the Δ marker for Celsius display
      s = s.replaceAll('°ΔC', '°C');
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
      return '${f.toStringAsFixed(1)}°F';
    }
    return '${celsius.toStringAsFixed(1)}°C';
  }

  String formatPressure(double hpa) {
    if (pressureUnit == PressureUnit.mmhg) {
      final mmhg = hpa * 0.750062;
      return '${mmhg.toStringAsFixed(1)} mmHg';
    }
    return '${hpa.toStringAsFixed(1)} hPa';
  }
}
