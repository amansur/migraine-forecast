import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../data/database.dart' hide Attack, JournalEntry, WeatherSnapshot, RiskAssessment;
import '../data/repos/assessment_repository.dart';
import '../data/repos/baseline_snapshot_builder.dart';
import '../data/repos/notification_dedup_repo.dart';
import '../data/repos/settings_repo.dart';
import '../data/repos/user_trigger_flags_repo_drift.dart';
import '../data/sources/drift_journal_source.dart';
import '../data/sources/health_package_source.dart';
import '../data/sources/health_source.dart';
import '../data/sources/journal_source.dart';
import '../data/sources/location_source.dart';
import '../data/sources/geolocator_location_source.dart';
import '../data/sources/persisted_manual_location_source.dart';
import '../data/sources/open_meteo/open_meteo_geocoder.dart';
import '../data/sources/open_meteo/open_meteo_weather_source.dart';
import '../data/sources/weather_source.dart';
import '../data/context_builder.dart';
import '../services/high_risk_notifier.dart';
import '../services/notification_service.dart';
import '../services/permission_service.dart';
import 'package:domain/domain.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = openAppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final httpClientProvider = Provider<http.Client>((ref) {
  final c = http.Client();
  ref.onDispose(c.close);
  return c;
});

final permissionServiceProvider = Provider<PermissionService>((_) => PermissionService());

final geocoderProvider = Provider<OpenMeteoGeocoder>(
    (ref) => OpenMeteoGeocoder(ref.watch(httpClientProvider)));

final weatherSourceProvider = Provider<WeatherSource>((ref) =>
    OpenMeteoWeatherSource(client: ref.watch(httpClientProvider), db: ref.watch(databaseProvider)));

final healthSourceProvider = Provider<HealthSource>((_) => HealthPackageSource());

final journalSourceProvider = Provider<JournalSource>((ref) => DriftJournalSource(ref.watch(databaseProvider)));

final manualLocationSourceProvider = Provider<PersistedManualLocationSource>(
    (ref) => PersistedManualLocationSource(ref.watch(settingsRepoProvider)));

final locationSourceProvider = Provider<LocationSource>(
    (ref) => GeolocatorLocationSource(fallback: ref.watch(manualLocationSourceProvider)));

final settingsRepoProvider = Provider<SettingsRepo>((ref) => SettingsRepo(ref.watch(databaseProvider)));

final flagsRepoProvider = Provider<UserTriggerFlagsRepo>((ref) => UserTriggerFlagsRepoDrift(ref.watch(databaseProvider)));

final assessmentRepoProvider = Provider<AssessmentRepository>((ref) => AssessmentRepository(ref.watch(databaseProvider)));

final baselineBuilderProvider = Provider<BaselineSnapshotBuilder>(
    (_) => const BaselineSnapshotBuilder(BaselineStore()));

final contextBuilderProvider = Provider<ContextBuilder>((ref) => ContextBuilder(
      weather: ref.watch(weatherSourceProvider),
      health: ref.watch(healthSourceProvider),
      journal: ref.watch(journalSourceProvider),
      location: ref.watch(locationSourceProvider),
      flagsRepo: ref.watch(flagsRepoProvider),
      baselineBuilder: ref.watch(baselineBuilderProvider),
      db: ref.watch(databaseProvider),
    ));

final rulesConfigProvider = FutureProvider<RulesConfig>((_) async {
  final text = await rootBundle.loadString('assets/rules_config_v1.json');
  return RulesConfigLoader.parse(text);
});

final riskEngineProvider = Provider<RiskEngine>((_) => RiskEngine(modules: [
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
    ]));

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final notificationDedupRepoProvider = Provider<NotificationDedupRepo>((ref) {
  return NotificationDedupRepo(ref.watch(databaseProvider));
});

final highRiskNotifierProvider = Provider<HighRiskNotifier>((ref) {
  return HighRiskNotifier(
    notifications: ref.watch(notificationServiceProvider),
    dedup: ref.watch(notificationDedupRepoProvider),
  );
});

final dayAssessmentProvider = FutureProvider.autoDispose.family<RiskAssessment?, DateTime>((ref, date) async {
  final repo = ref.watch(assessmentRepoProvider);
  final today = await repo.latestForDate(target: date, horizon: RiskHorizon.today);
  if (today != null) return today;
  return repo.latestForDate(target: date, horizon: RiskHorizon.tomorrow);
});

final dayAttacksProvider = StreamProvider.autoDispose.family<List<Attack>, DateTime>((ref, date) {
  final journal = ref.watch(journalSourceProvider);
  final d = date.toUtc();
  final startOfDay = DateTime.utc(d.year, d.month, d.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));
  return journal.watchRecentAttacks(const Duration(days: 1), now: endOfDay);
});
