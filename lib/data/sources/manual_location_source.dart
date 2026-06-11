import 'location_source.dart';

/// In-memory location store. The device-GPS implementation is wired in Plan 3
/// using `geolocator`; for Plan 2 tests + headless usage, callers set the
/// location explicitly.
class ManualLocationSource implements LocationSource {
  UserLocation? _value;

  Future<void> set({required double lat, required double lon, String? label}) async {
    _value = UserLocation(lat: lat, lon: lon, label: label);
  }

  @override
  Future<UserLocation?> current() async => _value;
}
