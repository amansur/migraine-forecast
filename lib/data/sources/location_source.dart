class UserLocation {
  final double lat;
  final double lon;
  final String? label;
  const UserLocation({required this.lat, required this.lon, this.label});
}

abstract class LocationSource {
  Future<UserLocation?> current();
}
