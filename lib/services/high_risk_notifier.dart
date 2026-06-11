import 'package:domain/domain.dart';

import '../data/repos/notification_dedup_repo.dart';
import 'notification_service.dart';

class HighRiskNotifier {
  final NotificationService notifications;
  final NotificationDedupRepo dedup;
  final DateTime Function() clock;
  HighRiskNotifier({
    required this.notifications,
    required this.dedup,
    DateTime Function()? clock,
  }) : clock = clock ?? DateTime.now;

  Future<void> maybeNotify(RiskAssessment ass, {required bool enabled}) async {
    if (!enabled) return;
    if (ass.band != RiskBand.high && ass.band != RiskBand.veryHigh) return;
    final already = await dedup.hasNotifiedFor(
      date: ass.targetDate,
      horizon: ass.horizon,
      band: ass.band,
    );
    if (already) return;
    final (title, body) = _format(ass);
    await notifications.showHighRisk(
      notificationId: _idFor(ass),
      title: title,
      body: body,
    );
    await dedup.record(
      date: ass.targetDate,
      horizon: ass.horizon,
      band: ass.band,
      at: clock(),
    );
  }

  (String, String) _format(RiskAssessment ass) {
    final when = ass.horizon == RiskHorizon.today ? 'Today' : 'Tomorrow';
    final band = ass.band == RiskBand.veryHigh ? 'very high' : 'high';
    final top = ass.contributors.isEmpty ? '' : ' — ${ass.contributors.first.explanation}.';
    return ('${when}\'s migraine risk is $band', 'Score ${ass.score}/100$top');
  }

  int _idFor(RiskAssessment ass) {
    // Stable per (date, horizon, band) so OS replaces rather than stacking.
    return Object.hash(ass.targetDate.millisecondsSinceEpoch, ass.horizon.name, ass.band.name) & 0x7fffffff;
  }
}
