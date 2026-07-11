import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/services/notification_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class _MockPlugin extends Mock implements FlutterLocalNotificationsPlugin {}

void main() {
  setUpAll(() {
    tzdata.initializeTimeZones();
    registerFallbackValue(const NotificationDetails());
    registerFallbackValue(AndroidScheduleMode.inexactAllowWhileIdle);
    registerFallbackValue(UILocalNotificationDateInterpretation.absoluteTime);
    registerFallbackValue(tz.TZDateTime.utc(2026));
  });

  test('scheduleCheckIn schedules at the exact instant with inexact mode', () async {
    final plugin = _MockPlugin();
    when(() => plugin.zonedSchedule(
          any(),
          any(),
          any(),
          any(),
          any(),
          androidScheduleMode: any(named: 'androidScheduleMode'),
          uiLocalNotificationDateInterpretation:
              any(named: 'uiLocalNotificationDateInterpretation'),
          payload: any(named: 'payload'),
          matchDateTimeComponents: any(named: 'matchDateTimeComponents'),
        )).thenAnswer((_) async {});

    final service = NotificationService(plugin: plugin);
    // Local wall-clock 9am tomorrow; the service must schedule the same
    // absolute instant (expressed in any zone).
    final fireAt = DateTime(2026, 7, 12, 9);
    await service.scheduleCheckIn(
      notificationId: 42,
      fireAtLocal: fireAt,
      title: 'How did yesterday go?',
      body: 'Log whether you got a migraine.',
    );

    final captured = verify(() => plugin.zonedSchedule(
          42,
          'How did yesterday go?',
          'Log whether you got a migraine.',
          captureAny(),
          any(),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              any(named: 'uiLocalNotificationDateInterpretation'),
          payload: any(named: 'payload'),
          matchDateTimeComponents: any(named: 'matchDateTimeComponents'),
        )).captured;
    final scheduled = captured.single as tz.TZDateTime;
    expect(scheduled.millisecondsSinceEpoch, fireAt.millisecondsSinceEpoch);
  });
}
