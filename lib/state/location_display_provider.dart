import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/sources/reverse_geocoder.dart';
import 'providers.dart';
import 'settings_provider.dart';

class LocationDisplay {
  final String name;
  final String? coords;
  final bool isAuto;
  final bool isSet;
  const LocationDisplay({
    required this.name,
    required this.coords,
    required this.isAuto,
    required this.isSet,
  });
}

/// Resolves the *current* effective location into a display model:
/// manual label if set, else reverse-geocoded live GPS, else "Location not set".
final effectiveLocationProvider = FutureProvider<LocationDisplay>((ref) async {
  final manual = await ref.watch(manualLocationProvider.future);
  if (manual != null) {
    return LocationDisplay(
      name: manual.label ?? formatCoords(manual.lat, manual.lon),
      coords: formatCoords(manual.lat, manual.lon),
      isAuto: false,
      isSet: true,
    );
  }
  final gps = await ref.watch(locationSourceProvider).current();
  if (gps == null) {
    return const LocationDisplay(
      name: 'Location not set',
      coords: null,
      isAuto: true,
      isSet: false,
    );
  }
  final name = await ref.watch(reverseGeocoderProvider).label(gps.lat, gps.lon);
  return LocationDisplay(
    name: name,
    coords: formatCoords(gps.lat, gps.lon),
    isAuto: true,
    isSet: true,
  );
});
