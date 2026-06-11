import 'dart:io';

import 'package:domain/domain.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:workmanager/workmanager.dart';

import '../data/context_builder.dart';
import '../data/database.dart' hide Attack, JournalEntry, WeatherSnapshot, RiskAssessment;
import '../data/repos/assessment_repository.dart';
import '../data/repos/baseline_snapshot_builder.dart';
import '../data/repos/notification_dedup_repo.dart';
import '../data/repos/settings_repo.dart';
import '../data/repos/user_trigger_flags_repo_drift.dart';
import '../data/sources/drift_journal_source.dart';
import '../data/sources/geolocator_location_source.dart';
import '../data/sources/health_package_source.dart';
import '../data/sources/open_meteo/open_meteo_weather_source.dart';
import 'high_risk_notifier.dart';
import 'notification_service.dart';

const morningTask = 'com.migraineweatherr.morning_refresh';
const eveningTask = 'com.migraineweatherr.evening_refresh';

class BackgroundScheduler {
  Future<void> register() async {
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
    await Workmanager().registerPeriodicTask(
      morningTask,
      morningTask,
      frequency: const Duration(hours: 24),
      initialDelay: _delayUntilNext(hour: 6),
      constraints: Constraints(networkType: NetworkType.connected),
    );
    await Workmanager().registerPeriodicTask(
      eveningTask,
      eveningTask,
      frequency: const Duration(hours: 24),
      initialDelay: _delayUntilNext(hour: 20),
      constraints: Constraints(networkType: NetworkType.connected),
    );
  }

  Duration _delayUntilNext({required int hour}) {
    final now = DateTime.now();
    var next = DateTime(now.year, now.month, now.day, hour);
    if (!next.isAfter(now)) next = next.add(const Duration(days: 1));
    return next.difference(now);
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, _) async {
    final db = openAppDatabase();
    final notif = NotificationService();
    await notif.init();
    final highRisk = HighRiskNotifier(
      notifications: notif,
      dedup: NotificationDedupRepo(db),
    );
    final client = http.Client();
    try {
      final builder = ContextBuilder(
        weather: OpenMeteoWeatherSource(client: client, db: db),
        health: HealthPackageSource(),
        journal: DriftJournalSource(db),
        location: GeolocatorLocationSource(),
        flagsRepo: UserTriggerFlagsRepoDrift(db),
        baselineBuilder: const BaselineSnapshotBuilder(BaselineStore()),
        db: db,
      );
      final engine = RiskEngine(modules: [
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
      ]);
      final settings = SettingsRepo(db);
      final cfg = RulesConfigLoader.parseOrFallback(
        await _loadConfigText(),
        fallback: RulesConfig.minimalDefault(),
      );
      final now = DateTime.now().toUtc();
      final isMorning = task == morningTask;
      final targetDay = isMorning
          ? DateTime.utc(now.year, now.month, now.day)
          : DateTime.utc(now.year, now.month, now.day).add(const Duration(days: 1));
      final horizon = isMorning ? RiskHorizon.today : RiskHorizon.tomorrow;
      final ctx = await builder.build(now: now, target: targetDay);
      final ass = engine.evaluate(ctx, cfg, horizon: horizon);
      await AssessmentRepository(db).save(ass);
      final enabled = await settings.getBool('notifications_enabled');
      await highRisk.maybeNotify(ass, enabled: enabled);
    } finally {
      client.close();
      await db.close();
    }
    return true;
  });
}

Future<String> _loadConfigText() async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'rules_config_v1.json'));
    if (await file.exists()) return file.readAsStringSync();
  } catch (_) {/* fall through to default */}
  return ''; // parseOrFallback yields minimal default
}
