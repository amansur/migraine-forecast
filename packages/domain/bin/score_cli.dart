import 'dart:convert';
import 'dart:io';

import 'package:domain/domain.dart';

List<TriggerModule> _buildModules() => [
      PressureDropModule(),
      HumidityModule(),
      TempSwingModule(),
      AirQualityModule(),
      SleepDeficitModule(),
      HrvLetdownModule(),
      MenstrualPhaseModule(),
      RefractoryModule(),
      AlcoholModule(),
      CaffeineModule(),
      StressModule(),
      HydrationModule(),
    ];

EvaluationContext _ctxFromJson(Map<String, Object?> json) {
  DateTime parse(String key) => DateTime.parse(json[key] as String);

  WeatherSeries? weather;
  if (json['weather'] is List) {
    weather = WeatherSeries(
      samples: (json['weather'] as List).map((e) {
        final m = e as Map<String, Object?>;
        return WeatherSample(
          at: DateTime.parse(m['at'] as String),
          pressureMsl: (m['pressureMsl'] as num).toDouble(),
          temperatureC: (m['temperatureC'] as num).toDouble(),
          humidityPct: (m['humidityPct'] as num).toDouble(),
        );
      }).toList(),
    );
  }

  AirQualitySeries? aq;
  if (json['airQuality'] is List) {
    aq = AirQualitySeries(
      samples: (json['airQuality'] as List).map((e) {
        final m = e as Map<String, Object?>;
        return AirQualitySample(
          at: DateTime.parse(m['at'] as String),
          pm25: (m['pm25'] as num).toDouble(),
        );
      }).toList(),
    );
  }

  HealthMetrics? health;
  if (json['health'] is Map) {
    final h = json['health'] as Map<String, Object?>;
    health = HealthMetrics(
      recentSleep: ((h['sleep'] as List?) ?? [])
          .map((e) {
            final m = e as Map<String, Object?>;
            return SleepRecord(
              night: DateTime.parse(m['night'] as String),
              totalSleep: Duration(minutes: (m['totalMinutes'] as num).toInt()),
              efficiency: (m['efficiency'] as num).toDouble(),
              sleepStart: DateTime.parse(m['sleepStart'] as String),
            );
          })
          .toList(),
      recentHrv: ((h['hrv'] as List?) ?? [])
          .map((e) => HrvSample(
                at: DateTime.parse((e as Map)['at'] as String),
                rmssdMs: ((e)['rmssdMs'] as num).toDouble(),
              ))
          .toList(),
      menstrualHistory: ((h['menstrual'] as List?) ?? [])
          .map((e) => MenstrualEvent(onsetDate: DateTime.parse((e as Map)['onsetDate'] as String)))
          .toList(),
    );
  }

  final journal = ((json['journal'] as List?) ?? []).map((e) {
    final m = e as Map<String, Object?>;
    return JournalEntry(
      at: DateTime.parse(m['at'] as String),
      kind: JournalKind.values.firstWhere((k) => k.name == m['kind']),
      payload: Map<String, Object?>.from(m['payload'] as Map),
    );
  }).toList();

  final attacks = ((json['attacks'] as List?) ?? []).map((e) {
    final m = e as Map<String, Object?>;
    return Attack(
      startedAt: DateTime.parse(m['startedAt'] as String),
      endedAt: m['endedAt'] == null ? null : DateTime.parse(m['endedAt'] as String),
      severity: (m['severity'] as num).toInt(),
    );
  }).toList();

  final flagsRaw = (json['userFlags'] as Map<String, Object?>?) ?? {};
  final flags = UserTriggerFlags(
    flaggedModuleIds:
        ((flagsRaw['flagged'] as List?) ?? []).map((e) => e.toString()).toSet(),
    weightOverrides: ((flagsRaw['overrides'] as Map?) ?? {}).map(
      (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
    ),
  );

  final baselinesRaw = (json['baselines'] as Map<String, Object?>?) ?? {};
  final baselines = BaselineSnapshot(
    sleepMedian7d: baselinesRaw['sleepMedianMinutes'] == null
        ? null
        : Duration(minutes: (baselinesRaw['sleepMedianMinutes'] as num).toInt()),
    hrvRmssdBaseline14d: (baselinesRaw['hrvRmssd'] as num?)?.toDouble(),
    pressureBaseline: (baselinesRaw['pressure'] as num?)?.toDouble(),
    caffeineDailyMg: (baselinesRaw['caffeineDailyMg'] as num?)?.toDouble(),
  );

  return EvaluationContext(
    now: parse('now'),
    targetDate: parse('targetDate'),
    weather: weather,
    airQuality: aq,
    health: health,
    recentJournal: journal,
    recentAttacks: attacks,
    userFlags: flags,
    baselines: baselines,
  );
}

Map<String, Object?> _assessmentToJson(RiskAssessment a) => {
      'score': a.score,
      'band': a.band.name,
      'isOnboarding': a.isOnboarding,
      'configVersion': a.configVersion,
      'targetDate': a.targetDate.toIso8601String(),
      'horizon': a.horizon.name,
      'computedAt': a.computedAt.toIso8601String(),
      'contributors': a.contributors
          .map((c) => {
                'moduleId': c.moduleId,
                'weight': c.weight,
                'confidence': c.confidence,
                'contribution': c.contribution,
                'explanation': c.explanation,
              })
          .toList(),
    };

Future<int> _run(List<String> args, Stream<List<int>> stdinStream) async {
  if (args.isEmpty) {
    stderr.writeln('usage: score_cli <config.json> [context.json]');
    return 2;
  }
  final cfg = RulesConfigLoader.parse(File(args[0]).readAsStringSync());
  final String ctxText = args.length >= 2
      ? File(args[1]).readAsStringSync()
      : await utf8.decoder.bind(stdinStream).join();
  final ctxJson = jsonDecode(ctxText) as Map<String, Object?>;
  final ctx = _ctxFromJson(ctxJson);
  final engine = RiskEngine(modules: _buildModules());
  final horizon = ctxJson['horizon'] == 'tomorrow' ? RiskHorizon.tomorrow : RiskHorizon.today;
  final ass = engine.evaluate(ctx, cfg, horizon: horizon);
  stdout.writeln(const JsonEncoder.withIndent('  ').convert(_assessmentToJson(ass)));
  return 0;
}

Future<void> main(List<String> args) async {
  exit(await _run(args, stdin));
}
