import 'package:geocoding/geocoding.dart' as geo;

String formatCoords(double lat, double lon) =>
    '${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)}';

/// Turns coordinates into a short human-readable "City, Region" label.
abstract class ReverseGeocoder {
  Future<String> label(double lat, double lon);
}

/// Real implementation backed by the OS geocoder. Caches by coarse coordinate
/// key and always falls back to [formatCoords] on failure/empty results.
class PlatformReverseGeocoder implements ReverseGeocoder {
  final _cache = <String, String>{};

  @override
  Future<String> label(double lat, double lon) async {
    final key = '${lat.toStringAsFixed(3)},${lon.toStringAsFixed(3)}';
    final cached = _cache[key];
    if (cached != null) return cached;

    String result = formatCoords(lat, lon);
    try {
      final marks = await geo.placemarkFromCoordinates(lat, lon);
      if (marks.isNotEmpty) {
        final m = marks.first;
        final city = (m.locality?.isNotEmpty ?? false)
            ? m.locality!
            : (m.subAdministrativeArea ?? '');
        final region = m.administrativeArea ?? '';
        final parts = [city, region].where((s) => s.isNotEmpty).toList();
        if (parts.isNotEmpty) result = parts.join(', ');
      }
    } catch (_) {
      // Keep the coordinate fallback.
    }
    _cache[key] = result;
    return result;
  }
}
