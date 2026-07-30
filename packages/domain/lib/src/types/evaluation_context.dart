import 'package:equatable/equatable.dart';
import 'health.dart';
import 'journal.dart';
import 'user_flags.dart';
import 'weather.dart';

class EvaluationContext extends Equatable {
  final DateTime now;
  final DateTime targetDate;          // UTC midnight of the day being scored
  final WeatherSeries? weather;
  final AirQualitySeries? airQuality;
  final HealthMetrics? health;
  final List<JournalEntry> recentJournal;
  final List<Attack> recentAttacks;
  final UserTriggerFlags userFlags;
  final BaselineSnapshot baselines;
  final double? resolvedLat;
  final double? resolvedLon;
  final String? locationName;

  const EvaluationContext({
    required this.now,
    required this.targetDate,
    this.weather,
    this.airQuality,
    this.health,
    this.recentJournal = const [],
    this.recentAttacks = const [],
    this.userFlags = const UserTriggerFlags(),
    required this.baselines,
    this.resolvedLat,
    this.resolvedLon,
    this.locationName,
  });

  @override
  List<Object?> get props => [
        now,
        targetDate,
        weather,
        airQuality,
        health,
        recentJournal,
        recentAttacks,
        userFlags,
        baselines,
        resolvedLat,
        resolvedLon,
        locationName,
      ];
}

/// Snapshot of rolling per-user baselines. Defined fully in Task 6.
/// Forward-declared here so EvaluationContext can reference it.
class BaselineSnapshot extends Equatable {
  final Duration? sleepMedian7d;
  final double? hrvRmssdBaseline14d;
  final double? pressureBaseline;
  final double? caffeineDailyMg;
  const BaselineSnapshot({
    this.sleepMedian7d,
    this.hrvRmssdBaseline14d,
    this.pressureBaseline,
    this.caffeineDailyMg,
  });
  static const empty = BaselineSnapshot();
  @override
  List<Object?> get props =>
      [sleepMedian7d, hrvRmssdBaseline14d, pressureBaseline, caffeineDailyMg];
}
