class OpenMeteoUrlBuilder {
  static Uri forecast({required double lat, required double lon}) =>
      Uri.https('api.open-meteo.com', '/v1/forecast', {
        'latitude': lat.toString(),
        'longitude': lon.toString(),
        'hourly': 'pressure_msl,temperature_2m,relative_humidity_2m',
        'forecast_days': '3',
        'past_days': '1',
        'timezone': 'UTC',
      });

  static Uri airQuality({required double lat, required double lon}) =>
      Uri.https('air-quality-api.open-meteo.com', '/v1/air-quality', {
        'latitude': lat.toString(),
        'longitude': lon.toString(),
        'hourly': 'pm2_5',
        'forecast_days': '2',
        'timezone': 'UTC',
      });
}
