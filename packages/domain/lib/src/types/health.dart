import 'package:equatable/equatable.dart';

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
  const HealthMetrics({
    this.recentSleep = const [],
    this.recentHrv = const [],
    this.menstrualHistory = const [],
  });
  @override
  List<Object?> get props => [recentSleep, recentHrv, menstrualHistory];
}
