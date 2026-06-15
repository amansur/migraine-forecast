import 'package:equatable/equatable.dart';

enum DataSource { oura, appleHealth, healthConnect, manual }

class SleepRecord extends Equatable {
  final DateTime night;            // local "night" the sleep belongs to (date-only at UTC midnight)
  final Duration totalSleep;
  final double efficiency;         // 0..1, fraction of in-bed time asleep
  final DateTime sleepStart;       // when the user fell asleep
  const SleepRecord({
    required this.night,
    required this.totalSleep,
    required this.efficiency,
    required this.sleepStart,
  });
  @override
  List<Object?> get props => [night, totalSleep, efficiency, sleepStart];
}

class HrvSample extends Equatable {
  final DateTime at;
  final double rmssdMs;
  const HrvSample({required this.at, required this.rmssdMs});
  @override
  List<Object?> get props => [at, rmssdMs];
}

class MenstrualEvent extends Equatable {
  final DateTime onsetDate;  // UTC midnight of cycle day 1
  const MenstrualEvent({required this.onsetDate});
  @override
  List<Object?> get props => [onsetDate];
}

class HealthMetrics extends Equatable {
  final List<SleepRecord> recentSleep;    // descending by night, most recent first
  final List<HrvSample> recentHrv;        // descending by at
  final List<MenstrualEvent> menstrualHistory; // descending by onsetDate

  // Oura Ring fields
  final int? sleepScore;                  // Oura sleep score (0-100)
  final int? lowestHeartRate;             // lowest HR during sleep (bpm)
  final int? sleepInterruptions;          // restless periods (count)
  final int? activityScore;               // activity score (0-100)
  final int? readinessScore;              // readiness score (0-100)
  final double? temperatureDeviation;     // temp deviation
  final double? averageHeartRate;         // average HR during sleep
  final int? averageHrv;                  // average HRV

  // Metadata fields
  final DataSource source;                // data source
  final DateTime? lastFetched;             // when data was last fetched

  const HealthMetrics({
    this.recentSleep = const [],
    this.recentHrv = const [],
    this.menstrualHistory = const [],
    this.sleepScore,
    this.lowestHeartRate,
    this.sleepInterruptions,
    this.activityScore,
    this.readinessScore,
    this.temperatureDeviation,
    this.averageHeartRate,
    this.averageHrv,
    required this.source,
    this.lastFetched,
  });

  /// Returns true if critical metrics (sleep/hrv) are present
  bool isComplete() {
    return (recentSleep.isNotEmpty || sleepScore != null) &&
           (recentHrv.isNotEmpty || averageHrv != null);
  }

  /// Returns true if data is older than 24 hours
  bool isStale() {
    if (lastFetched == null) return true;
    final now = DateTime.now();
    return now.difference(lastFetched!).inHours > 24;
  }

  @override
  List<Object?> get props => [
    recentSleep,
    recentHrv,
    menstrualHistory,
    sleepScore,
    lowestHeartRate,
    sleepInterruptions,
    activityScore,
    readinessScore,
    temperatureDeviation,
    averageHeartRate,
    averageHrv,
    source,
    lastFetched,
  ];
}
