import 'dart:convert';
import 'package:http/http.dart' as http;

class GeocodingResult {
  final String name;
  final String? admin1; // state / region
  final String? admin2; // county / district — disambiguates same-name places
  final String? country;
  final double lat;
  final double lon;

  const GeocodingResult({
    required this.name,
    required this.lat,
    required this.lon,
    this.admin1,
    this.admin2,
    this.country,
  });

  String get displayName => [name, admin1, country].where((s) => s != null && s.isNotEmpty).join(', ');

  /// A secondary line to tell apart results that share a [displayName]
  /// (e.g. two "Brooklyn, New York" in different counties): county + coords.
  String get detail => [
        if (admin2 != null && admin2!.isNotEmpty) admin2,
        '${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)}',
      ].join(' · ');
}

class OpenMeteoGeocoder {
  final http.Client client;
  OpenMeteoGeocoder(this.client);

  Future<List<GeocodingResult>> search(String query) async {
    if (query.trim().isEmpty) return [];
    final uri = Uri.parse('https://geocoding-api.open-meteo.com/v1/search')
        .replace(queryParameters: {'name': query.trim(), 'count': '5', 'language': 'en', 'format': 'json'});
    final res = await client.get(uri);
    if (res.statusCode >= 400) return [];
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final results = data['results'] as List<dynamic>? ?? [];
    return results.map((r) => GeocodingResult(
          name: r['name'] as String? ?? '',
          admin1: r['admin1'] as String?,
          admin2: r['admin2'] as String?,
          country: r['country'] as String?,
          lat: (r['latitude'] as num).toDouble(),
          lon: (r['longitude'] as num).toDouble(),
        )).toList();
  }
}
