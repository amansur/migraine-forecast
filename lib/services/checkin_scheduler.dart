import 'package:domain/domain.dart';

import 'notification_service.dart';

/// Keeps the next-morning check-in notification in sync with the day's
/// latest today-horizon assessment: high/veryHigh schedules tomorrow 9am
/// local, anything else cancels a previously scheduled one (band downgrades
/// during the day must not leave a stale "yesterday was high risk" prompt).
class CheckinScheduler {
  final NotificationService notifications;
  const CheckinScheduler(this.notifications);

  /// Deterministic across app restarts (unlike Object.hash) so recomputes
  /// after a relaunch replace the pending schedule instead of duplicating it.
  /// The 900M offset makes collisions with HighRiskNotifier's hashed ids
  /// astronomically unlikely (its ids span all of [0, 2^31), so true
  /// disjointness is impossible — ~2e4/2^31 odds per notification).
  static int idFor(DateTime dayKey) =>
      900000000 + dayKey.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;

  /// [ass] must be a today-horizon assessment; [now] is the local wall clock.
  Future<void> sync({
    required RiskAssessment ass,
    required bool enabled,
    required DateTime now,
  }) async {
    assert(ass.horizon == RiskHorizon.today);
    final id = idFor(ass.targetDate);
    final isHigh = ass.band == RiskBand.high || ass.band == RiskBand.veryHigh;
    if (enabled && isHigh) {
      await notifications.scheduleCheckIn(
        notificationId: id,
        fireAtLocal: DateTime(now.year, now.month, now.day + 1, 9),
        title: 'How did yesterday go?',
        body: 'Yesterday was high risk — log whether you got a migraine.',
      );
    } else {
      await notifications.cancelScheduled(id);
    }
  }
}
