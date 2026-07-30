import 'dart:convert';

import 'package:http/http.dart' as http;

String formatCoords(double lat, double lon) =>
    '${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)}';

/// Turns coordinates into a short human-readable "City, Region" label.
abstract class ReverseGeocoder {
  Future<String> label(double lat, double lon);
}

/// Reverse-geocodes over HTTP so it works on every platform (mobile, web,
/// desktop). The OS-level `geocoding` plugin only supports Android/iOS and
/// needs Google Play services on Android, so it silently failed elsewhere.
///
/// Uses BigDataCloud's keyless `reverse-geocode-client` endpoint. Caches by
/// coarse coordinate key and always falls back to [formatCoords] on
/// failure/empty results.
class HttpReverseGeocoder implements ReverseGeocoder {
  final http.Client client;
  final _cache = <String, String>{};

  HttpReverseGeocoder(this.client);

  @override
  Future<String> label(double lat, double lon) async {
    final key = '${lat.toStringAsFixed(3)},${lon.toStringAsFixed(3)}';
    final cached = _cache[key];
    if (cached != null) return cached;

    String result = formatCoords(lat, lon);
    try {
      final uri = Uri.parse(
              'https://api.bigdatacloud.net/data/reverse-geocode-client')
          .replace(queryParameters: {
        'latitude': lat.toString(),
        'longitude': lon.toString(),
        'localityLanguage': 'en',
      });
      final res = await client.get(uri);
      if (res.statusCode < 400) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final city = _firstNonEmpty([
          data['city'] as String?,
          data['locality'] as String?,
        ]);
        final region = data['principalSubdivision'] as String?;
        final parts = [city, region]
            .where((s) => s != null && s.isNotEmpty)
            .cast<String>()
            .toList();
        if (parts.isNotEmpty) result = parts.join(', ');
      }
    } catch (_) {
      // Keep the coordinate fallback.
    }
    _cache[key] = result;
    return result;
  }

  static String? _firstNonEmpty(List<String?> values) {
    for (final v in values) {
      if (v != null && v.isNotEmpty) return v;
    }
    return null;
  }
}
