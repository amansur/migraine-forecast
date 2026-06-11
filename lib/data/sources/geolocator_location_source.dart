import 'package:geolocator/geolocator.dart';

import 'location_source.dart';
import 'manual_location_source.dart';

/// Returns the device's last known or current GPS fix, falling back to a
/// manually-set location if GPS is unavailable or permission is denied.
class GeolocatorLocationSource implements LocationSource {
  final LocationSource fallback;
  GeolocatorLocationSource({LocationSource? fallback})
      : fallback = fallback ?? ManualLocationSource();

  @override
  Future<UserLocation?> current() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return fallback.current();
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
      );
      return UserLocation(lat: pos.latitude, lon: pos.longitude);
    } catch (_) {
      return fallback.current();
    }
  }
}
