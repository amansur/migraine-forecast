import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_weatherr/data/sources/open_meteo/open_meteo_url_builder.dart';

void main() {
  test('forecast URL includes required hourly params', () {
    final uri = OpenMeteoUrlBuilder.forecast(lat: 40.7, lon: -74.0);
    expect(uri.host, 'api.open-meteo.com');
    expect(uri.path, '/v1/forecast');
    expect(uri.queryParameters['latitude'], '40.7');
    expect(uri.queryParameters['longitude'], '-74.0');
    final hourly = uri.queryParameters['hourly']!;
    expect(hourly, contains('pressure_msl'));
    expect(hourly, contains('temperature_2m'));
    expect(hourly, contains('relative_humidity_2m'));
    expect(uri.queryParameters['forecast_days'], '3');
    expect(uri.queryParameters['past_days'], '1');
    expect(uri.queryParameters['timezone'], 'UTC');
  });

  test('air quality URL targets the AQ endpoint', () {
    final uri = OpenMeteoUrlBuilder.airQuality(lat: 40.7, lon: -74.0);
    expect(uri.host, 'air-quality-api.open-meteo.com');
    expect(uri.path, '/v1/air-quality');
    expect(uri.queryParameters['hourly'], contains('pm2_5'));
    expect(uri.queryParameters['forecast_days'], '2');
  });
}
