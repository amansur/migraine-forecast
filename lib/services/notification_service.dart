import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;
  NotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(settings);
    _initialized = true;
  }

  /// Returns true if permission is granted.
  Future<bool> requestPermissions() async {
    final iOSPlugin = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    final iosGranted =
        await iOSPlugin?.requestPermissions(alert: true, sound: true);
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final androidGranted =
        await androidPlugin?.requestNotificationsPermission();
    return (iosGranted ?? true) && (androidGranted ?? true);
  }

  /// One-shot schedule at the absolute instant [fireAtLocal] (a local
  /// wall-clock DateTime). Expressed in tz.UTC — for non-recurring schedules
  /// only the instant matters, which sidesteps needing a plugin to resolve
  /// the device's IANA zone name for tz.local. Inexact mode avoids the
  /// Android 12+ exact-alarm permission.
  Future<void> scheduleCheckIn({
    required int notificationId,
    required DateTime fireAtLocal,
    required String title,
    required String body,
  }) async {
    if (!_initialized) return; // see cancelScheduled
    await _plugin.zonedSchedule(
      notificationId,
      title,
      body,
      tz.TZDateTime.from(fireAtLocal, tz.UTC),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'checkin',
          'Morning check-ins',
          channelDescription: 'Asks how a high-risk day went',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(presentAlert: true),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Cancels a pending scheduled notification. No-op if none is pending or
  /// the plugin was never initialized (nothing can be pending then — and in
  /// widget tests the un-mocked platform channel would hang forever).
  Future<void> cancelScheduled(int notificationId) async {
    if (!_initialized) return;
    await _plugin.cancel(notificationId);
  }

  Future<void> showHighRisk({
    required int notificationId,
    required String title,
    required String body,
  }) async {
    await _plugin.show(
      notificationId,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'high_risk',
          'High risk alerts',
          channelDescription: 'Daily migraine risk alerts',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
      ),
    );
  }
}
