import 'package:geolocator/geolocator.dart';

class PermissionService {
  bool _locationGranted = false;
  final bool _notificationsGranted = false;

  PermissionService();
  PermissionService.forTesting();

  bool get locationGranted => _locationGranted;
  bool get notificationsGranted => _notificationsGranted;

  void markLocationGranted() => _locationGranted = true;

  /// Real-device path: requests location permission. Tests skip this.
  Future<bool> requestLocation() async {
    var p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) {
      p = await Geolocator.requestPermission();
    }
    final granted = p == LocationPermission.whileInUse || p == LocationPermission.always;
    if (granted) _locationGranted = true;
    return granted;
  }
}
