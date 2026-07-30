import '../repos/settings_repo.dart';
import 'location_source.dart';

class PersistedManualLocationSource implements LocationSource {
  final SettingsRepo _settings;
  UserLocation? _cached;

  PersistedManualLocationSource(this._settings);

  Future<void> set({required double lat, required double lon, String? label}) async {
    _cached = UserLocation(lat: lat, lon: lon, label: label);
    await _settings.setString('manual_lat', lat.toString());
    await _settings.setString('manual_lon', lon.toString());
    await _settings.setString('manual_label', label ?? '');
  }

  Future<void> clear() async {
    _cached = null;
    await _settings.setString('manual_lat', '');
    await _settings.setString('manual_lon', '');
    await _settings.setString('manual_label', '');
  }

  @override
  Future<UserLocation?> current() async {
    if (_cached != null) return _cached;
    final latStr = await _settings.getString('manual_lat');
    final lonStr = await _settings.getString('manual_lon');
    if (latStr == null || latStr.isEmpty || lonStr == null || lonStr.isEmpty) return null;
    final lat = double.tryParse(latStr);
    final lon = double.tryParse(lonStr);
    if (lat == null || lon == null) return null;
    final label = await _settings.getString('manual_label');
    _cached = UserLocation(
      lat: lat,
      lon: lon,
      label: (label == null || label.isEmpty) ? null : label,
    );
    return _cached;
  }
}
