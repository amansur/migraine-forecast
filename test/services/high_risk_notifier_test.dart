import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/data/database.dart' hide Attack, JournalEntry, WeatherSnapshot, RiskAssessment;
import 'package:migraine_forecast/data/repos/notification_dedup_repo.dart';
import 'package:migraine_forecast/services/high_risk_notifier.dart';
import 'package:migraine_forecast/services/notification_service.dart';

class _FakeNotifications implements NotificationService {
  final calls = <_Call>[];
  @override Future<void> init() async {}
  @override Future<bool> requestPermissions() async => true;
  @override
  Future<void> showHighRisk({required int notificationId, required String title, required String body}) async {
    calls.add(_Call(id: notificationId, title: title, body: body));
  }
  @override
  Future<void> scheduleCheckIn({required int notificationId, required DateTime fireAtLocal, required String title, required String body}) async {}
}

class _Call {
  final int id;
  final String title;
  final String body;
  _Call({required this.id, required this.title, required this.body});
}

RiskAssessment _ass(int score, RiskBand band, {RiskHorizon horizon = RiskHorizon.today}) => RiskAssessment(
      score: score,
      band: band,
      contributors: const [],
      computedAt: DateTime.utc(2026, 6, 11, 6),
      configVersion: 1,
      targetDate: DateTime.utc(2026, 6, 11),
      horizon: horizon,
    );

void main() {
  late AppDatabase db;
  late NotificationDedupRepo dedup;
  late _FakeNotifications notifications;
  late HighRiskNotifier notifier;
  setUp(() {
    db = AppDatabase.memory();
    dedup = NotificationDedupRepo(db);
    notifications = _FakeNotifications();
    notifier = HighRiskNotifier(notifications: notifications, dedup: dedup);
  });
  tearDown(() => db.close());

  test('does nothing for low/moderate bands', () async {
    await notifier.maybeNotify(_ass(20, RiskBand.low), enabled: true);
    await notifier.maybeNotify(_ass(40, RiskBand.moderate), enabled: true);
    expect(notifications.calls, isEmpty);
  });

  test('does nothing if notifications disabled', () async {
    await notifier.maybeNotify(_ass(60, RiskBand.high), enabled: false);
    expect(notifications.calls, isEmpty);
  });

  test('fires once for high band, then dedups', () async {
    await notifier.maybeNotify(_ass(60, RiskBand.high), enabled: true);
    await notifier.maybeNotify(_ass(60, RiskBand.high), enabled: true);
    expect(notifications.calls, hasLength(1));
  });

  test('escalation from high → veryHigh fires a second notification', () async {
    await notifier.maybeNotify(_ass(60, RiskBand.high), enabled: true);
    await notifier.maybeNotify(_ass(80, RiskBand.veryHigh), enabled: true);
    expect(notifications.calls, hasLength(2));
  });
}
