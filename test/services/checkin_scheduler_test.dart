import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/services/checkin_scheduler.dart';
import 'package:migraine_forecast/services/notification_service.dart';

class _FakeNotifications implements NotificationService {
  final scheduled = <({int id, DateTime fireAt, String title})>[];
  final cancelled = <int>[];
  @override
  Future<void> init() async {}
  @override
  Future<bool> requestPermissions() async => true;
  @override
  Future<void> showHighRisk(
      {required int notificationId,
      required String title,
      required String body}) async {}
  @override
  Future<void> scheduleCheckIn(
      {required int notificationId,
      required DateTime fireAtLocal,
      required String title,
      required String body}) async {
    scheduled.add((id: notificationId, fireAt: fireAtLocal, title: title));
  }

  @override
  Future<void> cancelScheduled(int notificationId) async {
    cancelled.add(notificationId);
  }
}

RiskAssessment _ass(RiskBand band, DateTime target) => RiskAssessment(
      score: band == RiskBand.low ? 5 : 80,
      band: band,
      contributors: const [],
      computedAt: DateTime.utc(2026, 7, 11, 8),
      configVersion: 2,
      targetDate: target,
      horizon: RiskHorizon.today,
    );

void main() {
  final today = DateTime.utc(2026, 7, 11);
  final now = DateTime(2026, 7, 11, 14, 30);

  test('high band schedules tomorrow 9am local with the deterministic day id',
      () async {
    final fake = _FakeNotifications();
    await CheckinScheduler(fake).sync(
        ass: _ass(RiskBand.high, today), enabled: true, now: now);
    expect(fake.scheduled, hasLength(1));
    expect(fake.scheduled.single.fireAt, DateTime(2026, 7, 12, 9));
    expect(fake.scheduled.single.id, CheckinScheduler.idFor(today));
    expect(fake.cancelled, isEmpty);
  });

  test('idFor is deterministic and distinct per day', () {
    expect(CheckinScheduler.idFor(today), CheckinScheduler.idFor(today));
    expect(CheckinScheduler.idFor(today),
        isNot(CheckinScheduler.idFor(today.add(const Duration(days: 1)))));
  });

  test('band downgrade cancels the pending schedule', () async {
    final fake = _FakeNotifications();
    await CheckinScheduler(fake).sync(
        ass: _ass(RiskBand.moderate, today), enabled: true, now: now);
    expect(fake.scheduled, isEmpty);
    expect(fake.cancelled, [CheckinScheduler.idFor(today)]);
  });

  test('notifications disabled cancels instead of scheduling', () async {
    final fake = _FakeNotifications();
    await CheckinScheduler(fake).sync(
        ass: _ass(RiskBand.veryHigh, today), enabled: false, now: now);
    expect(fake.scheduled, isEmpty);
    expect(fake.cancelled, [CheckinScheduler.idFor(today)]);
  });

  test('9am schedule normalizes across month end', () async {
    final fake = _FakeNotifications();
    await CheckinScheduler(fake).sync(
        ass: _ass(RiskBand.high, DateTime.utc(2026, 7, 31)),
        enabled: true,
        now: DateTime(2026, 7, 31, 20));
    expect(fake.scheduled.single.fireAt, DateTime(2026, 8, 1, 9));
  });
}
