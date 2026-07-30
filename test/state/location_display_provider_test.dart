import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:migraine_forecast/data/sources/location_source.dart';
import 'package:migraine_forecast/data/sources/reverse_geocoder.dart';
import 'package:migraine_forecast/state/providers.dart';
import 'package:migraine_forecast/state/settings_provider.dart';
import 'package:migraine_forecast/state/location_display_provider.dart';

class _FixedLocation implements LocationSource {
  final UserLocation? loc;
  _FixedLocation(this.loc);
  @override
  Future<UserLocation?> current() async => loc;
}

class _FakeReverse implements ReverseGeocoder {
  @override
  Future<String> label(double lat, double lon) async => 'Oakland, California';
}

void main() {
  Future<LocationDisplay> resolve(ProviderContainer c) =>
      c.read(effectiveLocationProvider.future);

  test('manual with label is used verbatim, not auto', () async {
    final c = ProviderContainer(overrides: [
      manualLocationProvider.overrideWith(
          (_) async => const UserLocation(
              lat: 37.8044, lon: -122.2712, label: 'Oakland, California')),
      locationSourceProvider.overrideWithValue(_FixedLocation(null)),
      reverseGeocoderProvider.overrideWithValue(_FakeReverse()),
    ]);
    addTearDown(c.dispose);

    final d = await resolve(c);
    expect(d.name, 'Oakland, California');
    expect(d.isAuto, isFalse);
    expect(d.isSet, isTrue);
    expect(d.coords, '37.8044, -122.2712');
  });

  test('no manual + GPS present is reverse-geocoded and marked auto', () async {
    final c = ProviderContainer(overrides: [
      manualLocationProvider.overrideWith((_) async => null),
      locationSourceProvider.overrideWithValue(
          _FixedLocation(const UserLocation(lat: 37.8044, lon: -122.2712))),
      reverseGeocoderProvider.overrideWithValue(_FakeReverse()),
    ]);
    addTearDown(c.dispose);

    final d = await resolve(c);
    expect(d.name, 'Oakland, California');
    expect(d.isAuto, isTrue);
    expect(d.isSet, isTrue);
    expect(d.coords, '37.8044, -122.2712');
  });

  test('no manual + no GPS is "Location not set"', () async {
    final c = ProviderContainer(overrides: [
      manualLocationProvider.overrideWith((_) async => null),
      locationSourceProvider.overrideWithValue(_FixedLocation(null)),
      reverseGeocoderProvider.overrideWithValue(_FakeReverse()),
    ]);
    addTearDown(c.dispose);

    final d = await resolve(c);
    expect(d.name, 'Location not set');
    expect(d.isSet, isFalse);
    expect(d.coords, isNull);
  });
}
