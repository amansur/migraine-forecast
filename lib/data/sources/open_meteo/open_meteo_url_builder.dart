class OpenMeteoUrlBuilder {
  static Uri forecast({
    required double lat,
    required double lon,
    int pastDays = 1,
  }) =>
      Uri.https('api.open-meteo.com', '/v1/forecast', {
        'latitude': lat.toString(),
        'longitude': lon.toString(),
        'hourly': 'pressure_msl,temperature_2m,relative_humidity_2m',
        'forecast_days': '3',
        'past_days': pastDays.toString(),
        'timezone': 'UTC',
      });

  static Uri archive({
    required double lat,
    required double lon,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    String fmt(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    return Uri.https('archive-api.open-meteo.com', '/v1/archive', {
      'latitude': lat.toString(),
      'longitude': lon.toString(),
      'start_date': fmt(startDate),
      'end_date': fmt(endDate),
      'hourly': 'pressure_msl,temperature_2m,relative_humidity_2m',
      'timezone': 'UTC',
    });
  }

  static Uri airQuality({
    required double lat,
    required double lon,
    int pastDays = 1,
  }) =>
      Uri.https('air-quality-api.open-meteo.com', '/v1/air-quality', {
        'latitude': lat.toString(),
        'longitude': lon.toString(),
        'hourly': 'pm2_5',
        'forecast_days': '2',
        'past_days': pastDays.toString(),
        'timezone': 'UTC',
      });
}
