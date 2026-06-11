import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_weatherr/data/sources/manual_location_source.dart';

void main() {
  test('round-trips a set location', () async {
    final src = ManualLocationSource();
    expect(await src.current(), isNull);
    await src.set(lat: 40.7128, lon: -74.0060, label: 'New York');
    final loc = await src.current();
    expect(loc?.lat, 40.7128);
    expect(loc?.lon, -74.0060);
    expect(loc?.label, 'New York');
  });
}
