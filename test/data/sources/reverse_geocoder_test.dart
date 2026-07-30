import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:migraine_forecast/data/sources/reverse_geocoder.dart';

void main() {
  test('formatCoords renders 4dp lat, lon', () {
    expect(formatCoords(37.80442, -122.27119), '37.8044, -122.2712');
  });

  test('parses locality + principalSubdivision into "Locality, Region"', () async {
    final client = MockClient((req) async {
      expect(req.url.host, 'api.bigdatacloud.net');
      return http.Response(
        '{"city":"Oakland","locality":"Oakland","principalSubdivision":"California","countryName":"United States"}',
        200,
      );
    });
    final g = HttpReverseGeocoder(client);
    expect(await g.label(37.8044, -122.2712), 'Oakland, California');
  });

  test('prefers the more specific locality over the broader city', () async {
    // Brooklyn coords: BigDataCloud returns locality "Brooklyn" but the
    // broader city "New York City". We want the borough.
    final client = MockClient((req) async => http.Response(
          '{"city":"New York City","locality":"Brooklyn","principalSubdivision":"New York"}',
          200,
        ));
    final g = HttpReverseGeocoder(client);
    expect(await g.label(40.6609, -73.9613), 'Brooklyn, New York');
  });

  test('falls back to city when locality is empty', () async {
    final client = MockClient((req) async => http.Response(
          '{"city":"Reno","locality":"","principalSubdivision":"Nevada"}',
          200,
        ));
    final g = HttpReverseGeocoder(client);
    expect(await g.label(39.5, -119.8), 'Reno, Nevada');
  });

  test('falls back to coords on HTTP error', () async {
    final client = MockClient((req) async => http.Response('nope', 500));
    final g = HttpReverseGeocoder(client);
    expect(await g.label(40.66, -73.96), '40.6600, -73.9600');
  });

  test('falls back to coords when response has no place fields', () async {
    final client = MockClient((req) async => http.Response('{}', 200));
    final g = HttpReverseGeocoder(client);
    expect(await g.label(40.66, -73.96), '40.6600, -73.9600');
  });

  test('caches by coarse key — one network call for repeated coords', () async {
    var calls = 0;
    final client = MockClient((req) async {
      calls++;
      return http.Response(
        '{"city":"Oakland","principalSubdivision":"California"}',
        200,
      );
    });
    final g = HttpReverseGeocoder(client);
    await g.label(37.80440, -122.27120);
    await g.label(37.80441, -122.27119); // same 3dp key
    expect(calls, 1);
  });
}
