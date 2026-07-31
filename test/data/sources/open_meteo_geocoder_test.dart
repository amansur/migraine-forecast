import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:migraine_forecast/data/sources/open_meteo/open_meteo_geocoder.dart';

void main() {
  test('parses admin2 and distinguishes same-name places by county + coords',
      () async {
    final client = MockClient((req) async => http.Response(
          '{"results":['
          '{"name":"Brooklyn","admin1":"New York","admin2":"Kings County","country":"United States","latitude":40.6501,"longitude":-73.9496},'
          '{"name":"Brooklyn","admin1":"New York","admin2":"Erie County","country":"United States","latitude":42.4331,"longitude":-78.7484}'
          ']}',
          200,
        ));
    final results = await OpenMeteoGeocoder(client).search('Brooklyn');

    expect(results, hasLength(2));
    // Same display name...
    expect(results[0].displayName, 'Brooklyn, New York, United States');
    expect(results[1].displayName, 'Brooklyn, New York, United States');
    // ...but distinguishable detail lines.
    expect(results[0].detail, 'Kings County · 40.6501, -73.9496');
    expect(results[1].detail, 'Erie County · 42.4331, -78.7484');
  });

  test('detail falls back to coords when admin2 is absent', () {
    const r = GeocodingResult(
      name: 'Reno',
      admin1: 'Nevada',
      country: 'United States',
      lat: 39.5,
      lon: -119.8,
    );
    expect(r.detail, '39.5000, -119.8000');
  });
}
