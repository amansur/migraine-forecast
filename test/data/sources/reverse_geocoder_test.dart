import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/data/sources/reverse_geocoder.dart';

class _FakeGeocoder extends ReverseGeocoder {
  final String? Function(double, double) resolve;
  int calls = 0;
  _FakeGeocoder(this.resolve);

  @override
  Future<String> label(double lat, double lon) async {
    calls++;
    final name = resolve(lat, lon);
    return name ?? formatCoords(lat, lon);
  }
}

void main() {
  test('formatCoords renders 4dp lat, lon', () {
    expect(formatCoords(37.80442, -122.27119), '37.8044, -122.2712');
  });

  test('fake falls back to coords when name is null', () async {
    final g = _FakeGeocoder((_, __) => null);
    expect(await g.label(37.8044, -122.2712), '37.8044, -122.2712');
  });

  test('fake returns a resolved name when available', () async {
    final g = _FakeGeocoder((_, __) => 'Oakland, California');
    expect(await g.label(37.8044, -122.2712), 'Oakland, California');
  });
}
