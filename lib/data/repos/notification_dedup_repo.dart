import 'package:domain/domain.dart';
import 'package:drift/drift.dart';

import '../database.dart';

class NotificationDedupRepo {
  final AppDatabase _db;
  NotificationDedupRepo(this._db);

  Future<bool> hasNotifiedFor({
    required DateTime date,
    required RiskHorizon horizon,
    required RiskBand band,
  }) async {
    final rows = await (_db.select(_db.notificationsSent)
          ..where((t) =>
              t.targetDate.equals(date) &
              t.horizon.equals(horizon.name) &
              t.band.equals(band.name))
          ..limit(1))
        .get();
    return rows.isNotEmpty;
  }

  Future<void> record({
    required DateTime date,
    required RiskHorizon horizon,
    required RiskBand band,
    required DateTime at,
  }) async {
    await _db.into(_db.notificationsSent).insert(
          NotificationsSentCompanion.insert(
            targetDate: date,
            horizon: horizon.name,
            band: band.name,
            sentAt: at,
          ),
        );
  }
}
