import 'package:domain/domain.dart';

import '../database.dart';
import 'day_timeline_repo.dart';

class CorrelationRepo {
  final AppDatabase _db;
  CorrelationRepo(this._db);

  Future<List<Cohort>> buildCohorts({
    required DateTime windowStart,
    required DateTime windowEnd,
    required List<String> moduleIds,
  }) async {
    final timeline = await DayTimelineRepo(_db)
        .buildTimeline(windowStart: windowStart, windowEnd: windowEnd);
    return [
      for (final id in moduleIds) buildCohort(timeline, Exposure.moduleFired(id)),
    ];
  }
}
