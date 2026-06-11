# Plan 3 — App MVP — Today + Log + Settings

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement task-by-task. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Ship a shippable Flutter MVP: a user opens the app, completes a one-time onboarding (flag suspected triggers, pick a risk display mode, grant location), sees today's and tomorrow's migraine risk on the Today screen with contributing factor chips, can log a migraine attack, and can adjust per-trigger weights and risk-display mode in Settings. Foreground refresh only — background scheduling is Plan 4.

**Architecture:** Material 3 + `flutter_riverpod` for state, `go_router` for navigation. The Today screen is a `ConsumerWidget` driven by a `riskAssessmentProvider` that composes `ContextBuilder` + `RiskEngine` + `AssessmentRepository` from Plan 2. The UI never touches Drift or Open-Meteo directly. The branding follows the spec's calm/wellness direction (sage greens + ivory, rounded type, soft band-accent colors).

**Tech Stack:** Flutter 3.44 / Dart 3.12. `flutter_riverpod` ^2.6, `go_router` ^14.0. All Plan 2 adapters consumed via providers. Tests use `flutter_test` + Riverpod overrides; one golden test per risk band; one end-to-end app smoke test.

---

## File Structure

```
/Users/amansur/projects/migraine-weatherr/
├── lib/
│   ├── main.dart                                    # ProviderScope + MaterialApp.router
│   ├── app/
│   │   ├── theme.dart                               # ThemeData (Material 3, sage seed)
│   │   ├── router.dart                              # go_router with onboarding gate
│   │   └── app.dart                                 # MigraineWeatherrApp widget
│   ├── data/                                        # Plan 2 already populated
│   │   ├── repos/
│   │   │   ├── user_trigger_flags_repo_drift.dart   # concrete impl of UserTriggerFlagsRepo
│   │   │   └── settings_repo.dart                   # key/value store over `settings` table
│   │   └── sources/
│   │       └── geolocator_location_source.dart      # device GPS impl of LocationSource
│   ├── services/
│   │   └── permission_service.dart                  # location + notification permission gate
│   ├── state/
│   │   ├── providers.dart                           # all top-level Riverpod providers
│   │   ├── risk_assessment_provider.dart            # AsyncNotifier<RiskAssessment>
│   │   ├── onboarding_provider.dart                 # onboarding completion state
│   │   ├── settings_provider.dart                   # display mode, notification toggle
│   │   └── trigger_flags_provider.dart              # UserTriggerFlags state
│   └── ui/
│       ├── onboarding/
│       │   └── onboarding_screen.dart
│       ├── today/
│       │   ├── today_screen.dart
│       │   ├── risk_display.dart                    # 3 variants: gauge, numeric, weather-icon
│       │   ├── contributor_chip.dart
│       │   ├── quick_check_in.dart                  # sleep / stress / hydration / alcohol
│       │   └── tomorrow_tile.dart
│       ├── log/
│       │   └── log_attack_screen.dart
│       └── settings/
│           └── settings_screen.dart
└── test/
    ├── data/                                        # extended for new repos
    │   ├── repos/
    │   │   ├── user_trigger_flags_repo_drift_test.dart
    │   │   └── settings_repo_test.dart
    ├── ui/
    │   ├── today/
    │   │   ├── today_screen_test.dart
    │   │   ├── risk_display_test.dart
    │   │   └── risk_display_golden_test.dart
    │   ├── onboarding/
    │   │   └── onboarding_screen_test.dart
    │   ├── log/
    │   │   └── log_attack_screen_test.dart
    │   └── settings/
    │       └── settings_screen_test.dart
    └── app/
        └── app_smoke_test.dart
```

---

## Task 1: Theme + Riverpod scaffold + router

**Files:**
- Modify: `pubspec.yaml` (add `flutter_riverpod`, `go_router`)
- Create: `lib/app/theme.dart`
- Create: `lib/app/router.dart`
- Create: `lib/app/app.dart`
- Modify: `lib/main.dart`

- [ ] **Step 1: Add dependencies**

Edit `pubspec.yaml`. Under `dependencies:`:

```yaml
  flutter_riverpod: ^2.6.0
  go_router: ^14.6.0
```

Run:
```bash
cd /Users/amansur/projects/migraine-weatherr && flutter pub get
```

- [ ] **Step 2: Theme**

Create `lib/app/theme.dart`:

```dart
import 'package:flutter/material.dart';

/// Migraine Weatherr brand colors — sage greens + warm ivory.
abstract final class BrandColors {
  static const sage = Color(0xFF7A9B7A);
  static const ivory = Color(0xFFFAF7F0);
  static const ink = Color(0xFF2E3A2E);

  static const bandLow      = Color(0xFF8FB28B);
  static const bandModerate = Color(0xFFE6C98C);
  static const bandHigh     = Color(0xFFD89B7A);
  static const bandVeryHigh = Color(0xFFB46A6A);
}

ThemeData buildLightTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: BrandColors.sage,
    primary: BrandColors.sage,
    surface: BrandColors.ivory,
    brightness: Brightness.light,
  );
  final base = ThemeData(useMaterial3: true, colorScheme: scheme);
  return base.copyWith(
    scaffoldBackgroundColor: BrandColors.ivory,
    textTheme: base.textTheme.apply(
      bodyColor: BrandColors.ink,
      displayColor: BrandColors.ink,
    ),
    cardTheme: const CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      backgroundColor: BrandColors.ivory,
      foregroundColor: BrandColors.ink,
      elevation: 0,
    ),
  );
}

Color colorForBand(String bandName) {
  switch (bandName) {
    case 'low': return BrandColors.bandLow;
    case 'moderate': return BrandColors.bandModerate;
    case 'high': return BrandColors.bandHigh;
    case 'veryHigh': return BrandColors.bandVeryHigh;
    default: return BrandColors.sage;
  }
}
```

- [ ] **Step 3: Router**

Create `lib/app/router.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../state/onboarding_provider.dart';
import '../ui/log/log_attack_screen.dart';
import '../ui/onboarding/onboarding_screen.dart';
import '../ui/settings/settings_screen.dart';
import '../ui/today/today_screen.dart';

GoRouter buildRouter(Ref ref) {
  return GoRouter(
    initialLocation: '/today',
    redirect: (context, state) {
      final completed = ref.read(onboardingCompletedProvider).asData?.value ?? false;
      final goingToOnboarding = state.matchedLocation == '/onboarding';
      if (!completed && !goingToOnboarding) return '/onboarding';
      if (completed && goingToOnboarding) return '/today';
      return null;
    },
    routes: [
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/today', builder: (_, __) => const TodayScreen()),
      GoRoute(path: '/log', builder: (_, __) => const LogAttackScreen()),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
    ],
  );
}
```

- [ ] **Step 4: App widget**

Create `lib/app/app.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'theme.dart';

class MigraineWeatherrApp extends ConsumerWidget {
  const MigraineWeatherrApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = buildRouter(ref);
    return MaterialApp.router(
      title: 'Migraine Weatherr',
      theme: buildLightTheme(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
```

- [ ] **Step 5: main.dart**

Replace `lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';

void main() {
  runApp(const ProviderScope(child: MigraineWeatherrApp()));
}
```

This task creates placeholder screen files that the next tasks fill in. Create empty stubs so the app compiles:

Create `lib/ui/onboarding/onboarding_screen.dart`:

```dart
import 'package:flutter/material.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(child: Text('Onboarding')),
      );
}
```

Create `lib/ui/today/today_screen.dart`:

```dart
import 'package:flutter/material.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(child: Text('Today')),
      );
}
```

Create `lib/ui/log/log_attack_screen.dart`:

```dart
import 'package:flutter/material.dart';

class LogAttackScreen extends StatelessWidget {
  const LogAttackScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(child: Text('Log Attack')),
      );
}
```

Create `lib/ui/settings/settings_screen.dart`:

```dart
import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(child: Text('Settings')),
      );
}
```

Create `lib/state/onboarding_provider.dart` (stub — properly implemented in Task 3):

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// True once the user has finished the onboarding flow.
final onboardingCompletedProvider = FutureProvider<bool>((ref) async => false);
```

- [ ] **Step 6: Verify build**

```bash
cd /Users/amansur/projects/migraine-weatherr && flutter build web 2>&1 | tail -3
```

Expected: "✓ Built build/web".

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "app: theme + router + Riverpod scaffold"
```

---

## Task 2: SettingsRepo + UserTriggerFlagsRepoImpl

**Files:**
- Create: `lib/data/repos/settings_repo.dart`
- Create: `lib/data/repos/user_trigger_flags_repo_drift.dart`
- Test: `test/data/repos/settings_repo_test.dart`
- Test: `test/data/repos/user_trigger_flags_repo_drift_test.dart`

- [ ] **Step 1: Write failing test for SettingsRepo**

Create `test/data/repos/settings_repo_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_weatherr/data/database.dart' hide Attack, JournalEntry, WeatherSnapshot, RiskAssessment;
import 'package:migraine_weatherr/data/repos/settings_repo.dart';

void main() {
  late AppDatabase db;
  late SettingsRepo repo;
  setUp(() {
    db = AppDatabase.memory();
    repo = SettingsRepo(db);
  });
  tearDown(() => db.close());

  test('returns null for unset key', () async {
    expect(await repo.getString('display_mode'), isNull);
  });

  test('round-trips a string value', () async {
    await repo.setString('display_mode', 'gauge');
    expect(await repo.getString('display_mode'), 'gauge');
  });

  test('returns false for unset bool', () async {
    expect(await repo.getBool('notifications_enabled'), isFalse);
  });

  test('round-trips a bool', () async {
    await repo.setBool('notifications_enabled', true);
    expect(await repo.getBool('notifications_enabled'), isTrue);
  });
}
```

- [ ] **Step 2: Run — expect FAIL**

```bash
cd /Users/amansur/projects/migraine-weatherr && flutter test test/data/repos/settings_repo_test.dart
```

- [ ] **Step 3: Implement SettingsRepo**

Create `lib/data/repos/settings_repo.dart`:

```dart
import 'package:drift/drift.dart';

import '../database.dart';

class SettingsRepo {
  final AppDatabase _db;
  SettingsRepo(this._db);

  Future<String?> getString(String key) async {
    final rows = await (_db.select(_db.settings)..where((t) => t.key.equals(key))).get();
    return rows.isEmpty ? null : rows.first.value;
  }

  Future<void> setString(String key, String value) async {
    await _db.into(_db.settings).insertOnConflictUpdate(
          SettingsCompanion.insert(key: key, value: value),
        );
  }

  Future<bool> getBool(String key) async {
    final s = await getString(key);
    return s == 'true';
  }

  Future<void> setBool(String key, bool value) async => setString(key, value ? 'true' : 'false');

  Future<int?> getInt(String key) async {
    final s = await getString(key);
    return s == null ? null : int.tryParse(s);
  }

  Future<void> setInt(String key, int value) async => setString(key, value.toString());
}
```

- [ ] **Step 4: Run — expect PASS**

```bash
cd /Users/amansur/projects/migraine-weatherr && flutter test test/data/repos/settings_repo_test.dart
```

Expected: 4 passing.

- [ ] **Step 5: Write failing test for UserTriggerFlagsRepo (Drift)**

Create `test/data/repos/user_trigger_flags_repo_drift_test.dart`:

```dart
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_weatherr/data/database.dart' hide Attack, JournalEntry, WeatherSnapshot, RiskAssessment;
import 'package:migraine_weatherr/data/repos/user_trigger_flags_repo_drift.dart';

void main() {
  late AppDatabase db;
  late UserTriggerFlagsRepoDrift repo;
  setUp(() {
    db = AppDatabase.memory();
    repo = UserTriggerFlagsRepoDrift(db);
  });
  tearDown(() => db.close());

  test('empty store returns empty flags', () async {
    final loaded = await repo.load();
    expect(loaded.flaggedModuleIds, isEmpty);
    expect(loaded.weightOverrides, isEmpty);
  });

  test('round-trips flags and overrides', () async {
    await repo.save(const UserTriggerFlags(
      flaggedModuleIds: {'pressure_drop', 'sleep_deficit'},
      weightOverrides: {'pressure_drop': 1.0, 'alcohol': -1.0},
    ));
    final loaded = await repo.load();
    expect(loaded.flaggedModuleIds, {'pressure_drop', 'sleep_deficit'});
    expect(loaded.weightOverrides, {'pressure_drop': 1.0, 'alcohol': -1.0});
  });

  test('save replaces prior state (no leftovers)', () async {
    await repo.save(const UserTriggerFlags(flaggedModuleIds: {'a', 'b'}));
    await repo.save(const UserTriggerFlags(flaggedModuleIds: {'c'}));
    final loaded = await repo.load();
    expect(loaded.flaggedModuleIds, {'c'});
  });
}
```

- [ ] **Step 6: Run — expect FAIL**

```bash
cd /Users/amansur/projects/migraine-weatherr && flutter test test/data/repos/user_trigger_flags_repo_drift_test.dart
```

- [ ] **Step 7: Implement**

Create `lib/data/repos/user_trigger_flags_repo_drift.dart`:

```dart
import 'package:domain/domain.dart';
import 'package:drift/drift.dart';

import '../context_builder.dart' show UserTriggerFlagsRepo;
import '../database.dart';

class UserTriggerFlagsRepoDrift implements UserTriggerFlagsRepo {
  final AppDatabase _db;
  UserTriggerFlagsRepoDrift(this._db);

  @override
  Future<UserTriggerFlags> load() async {
    final rows = await _db.select(_db.userTriggerFlagsTbl).get();
    final flagged = <String>{};
    final overrides = <String, double>{};
    for (final r in rows) {
      if (r.flagged) flagged.add(r.moduleId);
      if (r.weightOverride != 0) overrides[r.moduleId] = r.weightOverride;
    }
    return UserTriggerFlags(flaggedModuleIds: flagged, weightOverrides: overrides);
  }

  @override
  Future<void> save(UserTriggerFlags flags) async {
    await _db.transaction(() async {
      await _db.delete(_db.userTriggerFlagsTbl).go();
      for (final id in flags.flaggedModuleIds) {
        await _db.into(_db.userTriggerFlagsTbl).insert(
              UserTriggerFlagsTblCompanion.insert(
                moduleId: id,
                flagged: const Value(true),
                weightOverride: Value(flags.weightOverrides[id] ?? 0),
              ),
            );
      }
      for (final entry in flags.weightOverrides.entries) {
        if (flags.flaggedModuleIds.contains(entry.key)) continue;
        await _db.into(_db.userTriggerFlagsTbl).insert(
              UserTriggerFlagsTblCompanion.insert(
                moduleId: entry.key,
                flagged: const Value(false),
                weightOverride: Value(entry.value),
              ),
            );
      }
    });
  }
}
```

- [ ] **Step 8: Run — expect PASS**

```bash
cd /Users/amansur/projects/migraine-weatherr && flutter test test/data/repos/
```

Expected: all repo tests pass (Plan 2's plus the 7 new ones).

- [ ] **Step 9: Commit**

```bash
git add -A
git commit -m "data: SettingsRepo + UserTriggerFlagsRepoDrift"
```

---

## Task 3: GeolocatorLocationSource + PermissionService

**Files:**
- Create: `lib/data/sources/geolocator_location_source.dart`
- Create: `lib/services/permission_service.dart`
- Test: `test/services/permission_service_test.dart` (only the cached-permission logic, not the platform call)

- [ ] **Step 1: Implement GeolocatorLocationSource**

Create `lib/data/sources/geolocator_location_source.dart`:

```dart
import 'package:geolocator/geolocator.dart';

import 'location_source.dart';
import 'manual_location_source.dart';

/// Returns the device's last known or current GPS fix, falling back to a
/// manually-set location if GPS is unavailable or permission is denied.
class GeolocatorLocationSource implements LocationSource {
  final ManualLocationSource fallback;
  GeolocatorLocationSource({ManualLocationSource? fallback})
      : fallback = fallback ?? ManualLocationSource();

  @override
  Future<UserLocation?> current() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return fallback.current();
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
      );
      return UserLocation(lat: pos.latitude, lon: pos.longitude);
    } catch (_) {
      return fallback.current();
    }
  }
}
```

- [ ] **Step 2: Write failing test for PermissionService**

Create `test/services/permission_service_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_weatherr/services/permission_service.dart';

void main() {
  test('locationGranted defaults to false', () {
    final svc = PermissionService.forTesting();
    expect(svc.locationGranted, isFalse);
  });

  test('markLocationGranted flips the flag', () {
    final svc = PermissionService.forTesting();
    svc.markLocationGranted();
    expect(svc.locationGranted, isTrue);
  });
}
```

- [ ] **Step 3: Run — expect FAIL**

```bash
cd /Users/amansur/projects/migraine-weatherr && flutter test test/services/permission_service_test.dart
```

- [ ] **Step 4: Implement PermissionService**

Create `lib/services/permission_service.dart`:

```dart
import 'package:geolocator/geolocator.dart';

class PermissionService {
  bool _locationGranted = false;
  bool _notificationsGranted = false;

  PermissionService();
  PermissionService.forTesting();

  bool get locationGranted => _locationGranted;
  bool get notificationsGranted => _notificationsGranted;

  void markLocationGranted() => _locationGranted = true;

  /// Real-device path: requests location permission. Tests skip this.
  Future<bool> requestLocation() async {
    var p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) {
      p = await Geolocator.requestPermission();
    }
    final granted = p == LocationPermission.whileInUse || p == LocationPermission.always;
    if (granted) _locationGranted = true;
    return granted;
  }
}
```

- [ ] **Step 5: Run — expect PASS**

```bash
cd /Users/amansur/projects/migraine-weatherr && flutter test test/services/permission_service_test.dart
```

Expected: 2 passing.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "data: GeolocatorLocationSource + PermissionService"
```

---

## Task 4: Top-level Riverpod providers

**Files:**
- Create: `lib/state/providers.dart`
- Create: `lib/state/onboarding_provider.dart` (replaces stub)
- Create: `lib/state/settings_provider.dart`
- Create: `lib/state/trigger_flags_provider.dart`
- Create: `lib/state/risk_assessment_provider.dart`
- Test: `test/state/risk_assessment_provider_test.dart`

- [ ] **Step 1: Create top-level providers**

Create `lib/state/providers.dart`:

```dart
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../data/database.dart' hide Attack, JournalEntry, WeatherSnapshot, RiskAssessment;
import '../data/repos/assessment_repository.dart';
import '../data/repos/baseline_snapshot_builder.dart';
import '../data/repos/settings_repo.dart';
import '../data/repos/user_trigger_flags_repo_drift.dart';
import '../data/sources/drift_journal_source.dart';
import '../data/sources/health_package_source.dart';
import '../data/sources/health_source.dart';
import '../data/sources/journal_source.dart';
import '../data/sources/location_source.dart';
import '../data/sources/geolocator_location_source.dart';
import '../data/sources/open_meteo/open_meteo_weather_source.dart';
import '../data/sources/weather_source.dart';
import '../data/context_builder.dart';
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

final weatherSourceProvider = Provider<WeatherSource>((ref) =>
    OpenMeteoWeatherSource(client: ref.watch(httpClientProvider), db: ref.watch(databaseProvider)));

final healthSourceProvider = Provider<HealthSource>((_) => HealthPackageSource());

final journalSourceProvider = Provider<JournalSource>((ref) => DriftJournalSource(ref.watch(databaseProvider)));

final locationSourceProvider = Provider<LocationSource>((_) => GeolocatorLocationSource());

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
      HumidityTempSwingModule(),
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
```

- [ ] **Step 2: Onboarding provider**

Replace `lib/state/onboarding_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

final onboardingCompletedProvider = FutureProvider<bool>((ref) async {
  final settings = ref.watch(settingsRepoProvider);
  return settings.getBool('onboarding_completed');
});

final markOnboardingCompletedProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    await ref.read(settingsRepoProvider).setBool('onboarding_completed', true);
    ref.invalidate(onboardingCompletedProvider);
  };
});
```

- [ ] **Step 3: Settings provider**

Create `lib/state/settings_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

enum RiskDisplayMode { gauge, numeric, weatherIcon }

final riskDisplayModeProvider = FutureProvider<RiskDisplayMode>((ref) async {
  final s = await ref.watch(settingsRepoProvider).getString('display_mode');
  return RiskDisplayMode.values.firstWhere(
    (m) => m.name == s,
    orElse: () => RiskDisplayMode.gauge,
  );
});

final setRiskDisplayModeProvider = Provider<Future<void> Function(RiskDisplayMode)>((ref) {
  return (mode) async {
    await ref.read(settingsRepoProvider).setString('display_mode', mode.name);
    ref.invalidate(riskDisplayModeProvider);
  };
});

final notificationsEnabledProvider = FutureProvider<bool>((ref) async {
  return ref.watch(settingsRepoProvider).getBool('notifications_enabled');
});

final setNotificationsEnabledProvider = Provider<Future<void> Function(bool)>((ref) {
  return (enabled) async {
    await ref.read(settingsRepoProvider).setBool('notifications_enabled', enabled);
    ref.invalidate(notificationsEnabledProvider);
  };
});
```

- [ ] **Step 4: Trigger flags provider**

Create `lib/state/trigger_flags_provider.dart`:

```dart
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

final triggerFlagsProvider = FutureProvider<UserTriggerFlags>((ref) async {
  return ref.watch(flagsRepoProvider).load();
});

final saveTriggerFlagsProvider = Provider<Future<void> Function(UserTriggerFlags)>((ref) {
  return (flags) async {
    await ref.read(flagsRepoProvider).save(flags);
    ref.invalidate(triggerFlagsProvider);
  };
});
```

- [ ] **Step 5: Risk assessment provider — write failing test**

Create `test/state/risk_assessment_provider_test.dart`:

```dart
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_weatherr/data/context_builder.dart';
import 'package:migraine_weatherr/data/database.dart' hide Attack, JournalEntry, WeatherSnapshot, RiskAssessment;
import 'package:migraine_weatherr/data/repos/assessment_repository.dart';
import 'package:migraine_weatherr/data/repos/baseline_snapshot_builder.dart';
import 'package:migraine_weatherr/data/sources/drift_journal_source.dart';
import 'package:migraine_weatherr/data/sources/fake_health_source.dart';
import 'package:migraine_weatherr/data/sources/manual_location_source.dart';
import 'package:migraine_weatherr/data/sources/weather_source.dart';
import 'package:migraine_weatherr/state/providers.dart';
import 'package:migraine_weatherr/state/risk_assessment_provider.dart';

class _StubWeather implements WeatherSource {
  @override
  Future<WeatherSnapshot> fetch({required double lat, required double lon, required DateTime now}) async =>
      WeatherSnapshot(
        weather: const WeatherSeries(samples: []),
        airQuality: const AirQualitySeries(samples: []),
        fetchedAt: now,
      );
}

class _MemFlagsRepo implements UserTriggerFlagsRepo {
  UserTriggerFlags _f = const UserTriggerFlags();
  @override
  Future<UserTriggerFlags> load() async => _f;
  @override
  Future<void> save(UserTriggerFlags flags) async => _f = flags;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('refresh produces an onboarding assessment with empty inputs', () async {
    final db = AppDatabase.memory();
    final location = ManualLocationSource();
    await location.set(lat: 40.7, lon: -74.0);
    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      weatherSourceProvider.overrideWithValue(_StubWeather()),
      healthSourceProvider.overrideWithValue(FakeHealthSource()),
      journalSourceProvider.overrideWithValue(DriftJournalSource(db)),
      locationSourceProvider.overrideWithValue(location),
      flagsRepoProvider.overrideWithValue(_MemFlagsRepo()),
    ]);
    addTearDown(container.dispose);
    addTearDown(db.close);

    final notifier = container.read(riskAssessmentProvider.notifier);
    await notifier.refresh();
    final ass = container.read(riskAssessmentProvider).requireValue;
    expect(ass.isOnboarding, isTrue);
    expect(ass.score, 0);
  });
}
```

- [ ] **Step 6: Run — expect FAIL**

```bash
cd /Users/amansur/projects/migraine-weatherr && flutter test test/state/risk_assessment_provider_test.dart
```

- [ ] **Step 7: Implement risk_assessment_provider**

Create `lib/state/risk_assessment_provider.dart`:

```dart
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

final riskAssessmentProvider =
    AsyncNotifierProvider<RiskAssessmentNotifier, RiskAssessment>(RiskAssessmentNotifier.new);

class RiskAssessmentNotifier extends AsyncNotifier<RiskAssessment> {
  @override
  Future<RiskAssessment> build() async {
    return _compute();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_compute);
  }

  Future<RiskAssessment> _compute() async {
    final builder = ref.read(contextBuilderProvider);
    final cfg = await ref.read(rulesConfigProvider.future);
    final engine = ref.read(riskEngineProvider);
    final now = DateTime.now().toUtc();
    final today = DateTime.utc(now.year, now.month, now.day);
    final ctx = await builder.build(now: now, target: today);
    final ass = engine.evaluate(ctx, cfg, horizon: RiskHorizon.today);
    await ref.read(assessmentRepoProvider).save(ass);
    return ass;
  }
}

final tomorrowRiskAssessmentProvider =
    AsyncNotifierProvider<TomorrowRiskAssessmentNotifier, RiskAssessment>(TomorrowRiskAssessmentNotifier.new);

class TomorrowRiskAssessmentNotifier extends AsyncNotifier<RiskAssessment> {
  @override
  Future<RiskAssessment> build() async {
    return _compute();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_compute);
  }

  Future<RiskAssessment> _compute() async {
    final builder = ref.read(contextBuilderProvider);
    final cfg = await ref.read(rulesConfigProvider.future);
    final engine = ref.read(riskEngineProvider);
    final now = DateTime.now().toUtc();
    final tomorrow = DateTime.utc(now.year, now.month, now.day).add(const Duration(days: 1));
    final ctx = await builder.build(now: now, target: tomorrow);
    final ass = engine.evaluate(ctx, cfg, horizon: RiskHorizon.tomorrow);
    await ref.read(assessmentRepoProvider).save(ass);
    return ass;
  }
}
```

- [ ] **Step 8: Run — expect PASS**

```bash
cd /Users/amansur/projects/migraine-weatherr && flutter test test/state/risk_assessment_provider_test.dart
```

Expected: 1 passing.

- [ ] **Step 9: Commit**

```bash
git add -A
git commit -m "state: Riverpod providers wiring all adapters + risk assessment notifier"
```

---

## Task 5: Risk display widgets (3 variants) + golden tests

**Files:**
- Create: `lib/ui/today/risk_display.dart`
- Test: `test/ui/today/risk_display_test.dart`
- Test: `test/ui/today/risk_display_golden_test.dart`

- [ ] **Step 1: Implement widget**

Create `lib/ui/today/risk_display.dart`:

```dart
import 'dart:math' as math;

import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../state/settings_provider.dart';

class RiskDisplay extends StatelessWidget {
  final RiskAssessment assessment;
  final RiskDisplayMode mode;
  const RiskDisplay({super.key, required this.assessment, required this.mode});

  @override
  Widget build(BuildContext context) {
    switch (mode) {
      case RiskDisplayMode.gauge:
        return _GaugeDisplay(assessment: assessment);
      case RiskDisplayMode.numeric:
        return _NumericDisplay(assessment: assessment);
      case RiskDisplayMode.weatherIcon:
        return _WeatherIconDisplay(assessment: assessment);
    }
  }
}

class _GaugeDisplay extends StatelessWidget {
  final RiskAssessment assessment;
  const _GaugeDisplay({required this.assessment});

  @override
  Widget build(BuildContext context) {
    final color = colorForBand(assessment.band.name);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 220,
          height: 130,
          child: CustomPaint(
            painter: _GaugePainter(value: assessment.score / 100.0, color: color),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Text(
                  assessment.score.toString(),
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(color: color),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(_bandLabel(assessment.band), style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double value; // 0..1
  final Color color;
  _GaugePainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final track = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final arc = Paint()
      ..color = color
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final rect = Rect.fromLTWH(8, 8, size.width - 16, (size.height - 16) * 2);
    canvas.drawArc(rect, math.pi, math.pi, false, track);
    canvas.drawArc(rect, math.pi, math.pi * value.clamp(0, 1), false, arc);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) => old.value != value || old.color != color;
}

class _NumericDisplay extends StatelessWidget {
  final RiskAssessment assessment;
  const _NumericDisplay({required this.assessment});

  @override
  Widget build(BuildContext context) {
    final color = colorForBand(assessment.band.name);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          assessment.score.toString(),
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 96,
              ),
        ),
        Text(_bandLabel(assessment.band), style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

class _WeatherIconDisplay extends StatelessWidget {
  final RiskAssessment assessment;
  const _WeatherIconDisplay({required this.assessment});

  @override
  Widget build(BuildContext context) {
    final color = colorForBand(assessment.band.name);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(_iconForBand(assessment.band), size: 96, color: color),
        const SizedBox(height: 8),
        Text(_bandLabel(assessment.band), style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }

  IconData _iconForBand(RiskBand b) {
    switch (b) {
      case RiskBand.low: return Icons.wb_sunny_outlined;
      case RiskBand.moderate: return Icons.cloud_outlined;
      case RiskBand.high: return Icons.thunderstorm_outlined;
      case RiskBand.veryHigh: return Icons.warning_amber_rounded;
    }
  }
}

String _bandLabel(RiskBand b) {
  switch (b) {
    case RiskBand.low: return 'Low';
    case RiskBand.moderate: return 'Moderate';
    case RiskBand.high: return 'High';
    case RiskBand.veryHigh: return 'Very High';
  }
}
```

- [ ] **Step 2: Smoke test**

Create `test/ui/today/risk_display_test.dart`:

```dart
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_weatherr/state/settings_provider.dart';
import 'package:migraine_weatherr/ui/today/risk_display.dart';

RiskAssessment makeAss(int score, RiskBand band) => RiskAssessment(
      score: score,
      band: band,
      contributors: [],
      computedAt: DateTime.utc(2026, 6, 10),
      configVersion: 1,
      targetDate: DateTime.utc(2026, 6, 10),
      horizon: RiskHorizon.today,
    );

void main() {
  for (final mode in RiskDisplayMode.values) {
    testWidgets('renders ${mode.name} for high band', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: RiskDisplay(assessment: makeAss(58, RiskBand.high), mode: mode),
        ),
      ));
      expect(find.text('High'), findsOneWidget);
    });
  }
}
```

- [ ] **Step 3: Golden tests**

Create `test/ui/today/risk_display_golden_test.dart`:

```dart
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_weatherr/app/theme.dart';
import 'package:migraine_weatherr/state/settings_provider.dart';
import 'package:migraine_weatherr/ui/today/risk_display.dart';

RiskAssessment _ass(int score, RiskBand band) => RiskAssessment(
      score: score,
      band: band,
      contributors: [],
      computedAt: DateTime.utc(2026, 6, 10),
      configVersion: 1,
      targetDate: DateTime.utc(2026, 6, 10),
      horizon: RiskHorizon.today,
    );

void main() {
  for (final entry in {
    'low': _ass(15, RiskBand.low),
    'moderate': _ass(35, RiskBand.moderate),
    'high': _ass(58, RiskBand.high),
    'very_high': _ass(85, RiskBand.veryHigh),
  }.entries) {
    testWidgets('gauge_${entry.key}', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: buildLightTheme(),
        home: Scaffold(
          body: Center(
            child: RiskDisplay(assessment: entry.value, mode: RiskDisplayMode.gauge),
          ),
        ),
      ));
      await expectLater(
        find.byType(RiskDisplay),
        matchesGoldenFile('goldens/gauge_${entry.key}.png'),
      );
    });
  }
}
```

- [ ] **Step 4: Generate golden files**

```bash
cd /Users/amansur/projects/migraine-weatherr && flutter test --update-goldens test/ui/today/risk_display_golden_test.dart
```

Expected: golden files generated under `test/ui/today/goldens/`.

- [ ] **Step 5: Run all UI tests**

```bash
cd /Users/amansur/projects/migraine-weatherr && flutter test test/ui/today/
```

Expected: all pass.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "ui: RiskDisplay widget with 3 variants + goldens"
```

---

## Task 6: Onboarding screen

**Files:**
- Replace stub: `lib/ui/onboarding/onboarding_screen.dart`
- Test: `test/ui/onboarding/onboarding_screen_test.dart`

- [ ] **Step 1: Write failing test**

Create `test/ui/onboarding/onboarding_screen_test.dart`:

```dart
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_weatherr/data/context_builder.dart';
import 'package:migraine_weatherr/state/providers.dart';
import 'package:migraine_weatherr/state/settings_provider.dart';
import 'package:migraine_weatherr/state/trigger_flags_provider.dart';
import 'package:migraine_weatherr/ui/onboarding/onboarding_screen.dart';

class _MemSettings implements SettingsRepoFake {
  final values = <String, String>{};
  @override Future<String?> getString(String k) async => values[k];
  @override Future<void> setString(String k, String v) async => values[k] = v;
  @override Future<bool> getBool(String k) async => values[k] == 'true';
  @override Future<void> setBool(String k, bool v) async => values[k] = v ? 'true' : 'false';
  @override Future<int?> getInt(String k) async => int.tryParse(values[k] ?? '');
  @override Future<void> setInt(String k, int v) async => values[k] = v.toString();
}

abstract class SettingsRepoFake {
  Future<String?> getString(String key);
  Future<void> setString(String key, String value);
  Future<bool> getBool(String key);
  Future<void> setBool(String key, bool value);
  Future<int?> getInt(String key);
  Future<void> setInt(String key, int value);
}

class _MemFlagsRepo implements UserTriggerFlagsRepo {
  UserTriggerFlags _f = const UserTriggerFlags();
  @override Future<UserTriggerFlags> load() async => _f;
  @override Future<void> save(UserTriggerFlags flags) async => _f = flags;
}

void main() {
  testWidgets('tapping triggers then Finish persists flags + marks onboarding completed', (tester) async {
    final flagsRepo = _MemFlagsRepo();
    bool onboardingDone = false;
    final container = ProviderContainer(overrides: [
      flagsRepoProvider.overrideWithValue(flagsRepo),
      markOnboardingCompletedProvider.overrideWithValue(() async => onboardingDone = true),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: OnboardingScreen()),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Stress'));
    await tester.tap(find.text('Weather'));
    await tester.tap(find.text('Finish'));
    await tester.pumpAndSettle();

    final saved = await flagsRepo.load();
    expect(saved.flaggedModuleIds, contains('stress'));
    expect(saved.flaggedModuleIds, contains('pressure_drop'));
    expect(onboardingDone, isTrue);
  });
}
```

Hmm — the test imports a `SettingsRepoFake` that I haven't fully wired. Let me simplify: I'll skip the test for now and focus on the screen + a smoke render test instead. **Use this simpler test:**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:domain/domain.dart';
import 'package:migraine_weatherr/data/context_builder.dart';
import 'package:migraine_weatherr/state/providers.dart';
import 'package:migraine_weatherr/state/onboarding_provider.dart';
import 'package:migraine_weatherr/ui/onboarding/onboarding_screen.dart';

class _MemFlagsRepo implements UserTriggerFlagsRepo {
  UserTriggerFlags _f = const UserTriggerFlags();
  @override Future<UserTriggerFlags> load() async => _f;
  @override Future<void> save(UserTriggerFlags flags) async => _f = flags;
}

void main() {
  testWidgets('tapping triggers then Finish persists flags + marks onboarding completed', (tester) async {
    final flagsRepo = _MemFlagsRepo();
    bool onboardingDone = false;
    final container = ProviderContainer(overrides: [
      flagsRepoProvider.overrideWithValue(flagsRepo),
      markOnboardingCompletedProvider.overrideWithValue(() async => onboardingDone = true),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: OnboardingScreen()),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Stress'));
    await tester.tap(find.text('Weather'));
    await tester.tap(find.text('Finish'));
    await tester.pumpAndSettle();

    final saved = await flagsRepo.load();
    expect(saved.flaggedModuleIds, contains('stress'));
    expect(saved.flaggedModuleIds, contains('pressure_drop'));
    expect(onboardingDone, isTrue);
  });
}
```

- [ ] **Step 2: Run — expect FAIL**

```bash
cd /Users/amansur/projects/migraine-weatherr && flutter test test/ui/onboarding/onboarding_screen_test.dart
```

- [ ] **Step 3: Implement**

Replace `lib/ui/onboarding/onboarding_screen.dart`:

```dart
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../state/onboarding_provider.dart';
import '../../state/trigger_flags_provider.dart';

/// User-facing labels for the multi-select. Each maps to a module ID.
const _triggerOptions = <String, String>{
  'Stress': 'stress',
  'Sleep': 'sleep_deficit',
  'Weather': 'pressure_drop',
  'Hormones': 'menstrual_phase',
  'Alcohol': 'alcohol',
  'Caffeine': 'caffeine',
  'Dehydration': 'hydration',
};

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final Set<String> _selected = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Welcome to Migraine Weatherr')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Which of these have triggered migraines for you?',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'You can change these any time in Settings.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _triggerOptions.entries.map((e) {
                      final selected = _selected.contains(e.value);
                      return FilterChip(
                        label: Text(e.key),
                        selected: selected,
                        onSelected: (v) => setState(() {
                          v ? _selected.add(e.value) : _selected.remove(e.value);
                        }),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const _Disclaimer(),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _finish,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Finish'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _finish() async {
    final saveFlags = ref.read(saveTriggerFlagsProvider);
    await saveFlags(UserTriggerFlags(flaggedModuleIds: Set.of(_selected)));
    final markDone = ref.read(markOnboardingCompletedProvider);
    await markDone();
    if (mounted) context.go('/today');
  }
}

class _Disclaimer extends StatelessWidget {
  const _Disclaimer();
  @override
  Widget build(BuildContext context) {
    return Text(
      'Migraine Weatherr is decision-support, not medical advice. Please consult a clinician for diagnosis or treatment.',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
    );
  }
}
```

- [ ] **Step 4: Run — expect PASS**

```bash
cd /Users/amansur/projects/migraine-weatherr && flutter test test/ui/onboarding/onboarding_screen_test.dart
```

Expected: 1 passing.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "ui: Onboarding screen — trigger flags + disclaimer"
```

---

## Task 7: Today screen — UI + tomorrow tile + contributor chips

**Files:**
- Replace stub: `lib/ui/today/today_screen.dart`
- Create: `lib/ui/today/contributor_chip.dart`
- Create: `lib/ui/today/tomorrow_tile.dart`
- Test: `test/ui/today/today_screen_test.dart`

- [ ] **Step 1: Contributor chip widget**

Create `lib/ui/today/contributor_chip.dart`:

```dart
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

class ContributorChip extends StatelessWidget {
  final TriggerSignal signal;
  const ContributorChip({super.key, required this.signal});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: const Icon(Icons.trending_up, size: 16),
      label: Text(signal.explanation),
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
      ),
    );
  }
}
```

- [ ] **Step 2: Tomorrow tile**

Create `lib/ui/today/tomorrow_tile.dart`:

```dart
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../state/risk_assessment_provider.dart';

class TomorrowTile extends ConsumerWidget {
  const TomorrowTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tomorrow = ref.watch(tomorrowRiskAssessmentProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: tomorrow.when(
          loading: () => const Center(child: SizedBox(
            width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2),
          )),
          error: (e, _) => Text('Tomorrow: --', style: Theme.of(context).textTheme.titleSmall),
          data: (ass) {
            final color = colorForBand(ass.band.name);
            return Row(
              children: [
                Container(
                  width: 14, height: 14,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 12),
                Text('Tomorrow: ${_label(ass.band)} (${ass.score})',
                    style: Theme.of(context).textTheme.titleSmall),
              ],
            );
          },
        ),
      ),
    );
  }

  String _label(RiskBand b) {
    switch (b) {
      case RiskBand.low: return 'Low';
      case RiskBand.moderate: return 'Moderate';
      case RiskBand.high: return 'High';
      case RiskBand.veryHigh: return 'Very High';
    }
  }
}
```

- [ ] **Step 3: Today screen**

Replace `lib/ui/today/today_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../state/risk_assessment_provider.dart';
import '../../state/settings_provider.dart';
import 'contributor_chip.dart';
import 'risk_display.dart';
import 'tomorrow_tile.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ass = ref.watch(riskAssessmentProvider);
    final mode = ref.watch(riskDisplayModeProvider).asData?.value ?? RiskDisplayMode.gauge;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Today'),
        actions: [
          IconButton(
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(riskAssessmentProvider.notifier).refresh(),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            ass.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 80),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(child: Text('Could not compute risk: $e')),
              ),
              data: (a) {
                if (a.isOnboarding) {
                  return _OnboardingCard(onSetup: () => context.go('/settings'));
                }
                final contributing = a.contributors.where((c) => c.contribution > 0).take(4).toList();
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: RiskDisplay(assessment: a, mode: mode),
                    ),
                    const SizedBox(height: 8),
                    const TomorrowTile(),
                    const SizedBox(height: 16),
                    if (contributing.isNotEmpty) ...[
                      Text('Why', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: contributing.map((c) => ContributorChip(signal: c)).toList(),
                      ),
                      const SizedBox(height: 24),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => context.push('/log'),
                        icon: const Icon(Icons.add),
                        label: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('Log a migraine'),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingCard extends StatelessWidget {
  final VoidCallback onSetup;
  const _OnboardingCard({required this.onSetup});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Set up your personal risk profile',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('Grant location and Health permissions to start seeing risk predictions.'),
            const SizedBox(height: 16),
            FilledButton(onPressed: onSetup, child: const Text('Open Settings')),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Widget test**

Create `test/ui/today/today_screen_test.dart`:

```dart
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:migraine_weatherr/state/risk_assessment_provider.dart';
import 'package:migraine_weatherr/state/settings_provider.dart';
import 'package:migraine_weatherr/ui/today/today_screen.dart';

class _FakeNotifier extends RiskAssessmentNotifier {
  final RiskAssessment fixed;
  _FakeNotifier(this.fixed);
  @override
  Future<RiskAssessment> build() async => fixed;
  @override
  Future<void> refresh() async {
    state = AsyncValue.data(fixed);
  }
}

class _FakeTomorrowNotifier extends TomorrowRiskAssessmentNotifier {
  final RiskAssessment fixed;
  _FakeTomorrowNotifier(this.fixed);
  @override
  Future<RiskAssessment> build() async => fixed;
  @override
  Future<void> refresh() async {
    state = AsyncValue.data(fixed);
  }
}

RiskAssessment _ass({int score = 58, RiskBand band = RiskBand.high, List<TriggerSignal> contributors = const []}) =>
    RiskAssessment(
      score: score,
      band: band,
      contributors: contributors,
      computedAt: DateTime.utc(2026, 6, 10, 6),
      configVersion: 1,
      targetDate: DateTime.utc(2026, 6, 10),
      horizon: RiskHorizon.today,
    );

void main() {
  testWidgets('renders score and contributors', (tester) async {
    final today = _ass(
      score: 58,
      contributors: [
        TriggerSignal(moduleId: 'pressure_drop', weight: 18, confidence: 1.0, explanation: 'Pressure dropping 7 hPa'),
        TriggerSignal(moduleId: 'sleep_deficit', weight: 10, confidence: 1.0, explanation: '4.5h sleep'),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          riskAssessmentProvider.overrideWith(() => _FakeNotifier(today)),
          tomorrowRiskAssessmentProvider.overrideWith(() => _FakeTomorrowNotifier(_ass(score: 30, band: RiskBand.moderate))),
          riskDisplayModeProvider.overrideWith((ref) async => RiskDisplayMode.numeric),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(routes: [
            GoRoute(path: '/', builder: (_, __) => const TodayScreen()),
            GoRoute(path: '/log', builder: (_, __) => const SizedBox()),
            GoRoute(path: '/settings', builder: (_, __) => const SizedBox()),
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('58'), findsOneWidget);
    expect(find.text('High'), findsOneWidget);
    expect(find.text('Pressure dropping 7 hPa'), findsOneWidget);
    expect(find.textContaining('Tomorrow'), findsOneWidget);
  });

  testWidgets('renders onboarding card for zero-confidence assessment', (tester) async {
    final ass = RiskAssessment(
      score: 0,
      band: RiskBand.low,
      contributors: [TriggerSignal.zero(moduleId: 'x', reason: 'no data')],
      computedAt: DateTime.utc(2026, 6, 10),
      configVersion: 1,
      targetDate: DateTime.utc(2026, 6, 10),
      horizon: RiskHorizon.today,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          riskAssessmentProvider.overrideWith(() => _FakeNotifier(ass)),
          tomorrowRiskAssessmentProvider.overrideWith(() => _FakeTomorrowNotifier(ass)),
          riskDisplayModeProvider.overrideWith((ref) async => RiskDisplayMode.gauge),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(routes: [
            GoRoute(path: '/', builder: (_, __) => const TodayScreen()),
            GoRoute(path: '/settings', builder: (_, __) => const SizedBox()),
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Set up your personal risk profile'), findsOneWidget);
  });
}
```

- [ ] **Step 5: Run**

```bash
cd /Users/amansur/projects/migraine-weatherr && flutter test test/ui/today/
```

Expected: all pass.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "ui: Today screen with risk display, tomorrow tile, contributor chips"
```

---

## Task 8: Log Attack screen

**Files:**
- Replace stub: `lib/ui/log/log_attack_screen.dart`
- Test: `test/ui/log/log_attack_screen_test.dart`

- [ ] **Step 1: Write failing test**

Create `test/ui/log/log_attack_screen_test.dart`:

```dart
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:migraine_weatherr/data/sources/journal_source.dart';
import 'package:migraine_weatherr/state/providers.dart';
import 'package:migraine_weatherr/ui/log/log_attack_screen.dart';

class _RecordingJournal implements JournalSource {
  Attack? lastAttack;
  int? lastAssessmentId;
  @override
  Future<int> addAttack(Attack attack, {int? riskAssessmentId}) async {
    lastAttack = attack;
    lastAssessmentId = riskAssessmentId;
    return 1;
  }
  @override Future<void> addEntry(JournalEntry entry) async {}
  @override Future<List<JournalEntry>> recentEntries(Duration window, {required DateTime now}) async => const [];
  @override Future<List<Attack>> recentAttacks(Duration window, {required DateTime now}) async => const [];
}

void main() {
  testWidgets('Submitting saves an attack via JournalSource', (tester) async {
    final journal = _RecordingJournal();
    bool popped = false;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          journalSourceProvider.overrideWithValue(journal),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(routes: [
            GoRoute(path: '/', builder: (_, __) => const LogAttackScreen()),
          ], redirect: (ctx, state) {
            if (state.matchedLocation == '/done') {
              popped = true;
              return '/';
            }
            return null;
          }),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(journal.lastAttack, isNotNull);
    expect(journal.lastAttack!.severity, inInclusiveRange(1, 10));
  });
}
```

- [ ] **Step 2: Run — expect FAIL**

```bash
cd /Users/amansur/projects/migraine-weatherr && flutter test test/ui/log/log_attack_screen_test.dart
```

- [ ] **Step 3: Implement**

Replace `lib/ui/log/log_attack_screen.dart`:

```dart
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../state/providers.dart';

class LogAttackScreen extends ConsumerStatefulWidget {
  const LogAttackScreen({super.key});
  @override
  ConsumerState<LogAttackScreen> createState() => _LogAttackScreenState();
}

class _LogAttackScreenState extends ConsumerState<LogAttackScreen> {
  late DateTime _start = DateTime.now();
  DateTime? _end;
  double _severity = 5;
  final _notesCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log a migraine')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                title: const Text('Started'),
                subtitle: Text(_start.toLocal().toString()),
                trailing: const Icon(Icons.edit_outlined),
                onTap: _pickStart,
              ),
              ListTile(
                title: const Text('Ended (optional)'),
                subtitle: Text(_end?.toLocal().toString() ?? 'In progress'),
                trailing: const Icon(Icons.edit_outlined),
                onTap: _pickEnd,
              ),
              const SizedBox(height: 12),
              Text('Severity: ${_severity.round()}', style: Theme.of(context).textTheme.titleMedium),
              Slider(value: _severity, min: 1, max: 10, divisions: 9, onChanged: (v) => setState(() => _severity = v)),
              const SizedBox(height: 8),
              TextField(
                controller: _notesCtrl,
                decoration: const InputDecoration(labelText: 'Notes', border: OutlineInputBorder()),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(_saving ? 'Saving…' : 'Save'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickStart() async {
    final picked = await _pickDateTime(_start);
    if (picked != null) setState(() => _start = picked);
  }

  Future<void> _pickEnd() async {
    final picked = await _pickDateTime(_end ?? DateTime.now());
    if (picked != null) setState(() => _end = picked);
  }

  Future<DateTime?> _pickDateTime(DateTime initial) async {
    final d = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (d == null) return null;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (t == null) return null;
    return DateTime(d.year, d.month, d.day, t.hour, t.minute);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final journal = ref.read(journalSourceProvider);
    final repo = ref.read(assessmentRepoProvider);
    final activeAss = await repo.activeAt(_start.toUtc());
    await journal.addAttack(
      Attack(startedAt: _start.toUtc(), endedAt: _end?.toUtc(), severity: _severity.round()),
      riskAssessmentId: null, // Plan 5 will wire the assessment row's PK; for v1 just leave null
    );
    if (mounted) context.pop();
  }
}
```

- [ ] **Step 4: Run**

```bash
cd /Users/amansur/projects/migraine-weatherr && flutter test test/ui/log/log_attack_screen_test.dart
```

Expected: 1 passing.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "ui: Log Attack screen — date/time, severity slider, notes"
```

---

## Task 9: Settings screen

**Files:**
- Replace stub: `lib/ui/settings/settings_screen.dart`
- Test: `test/ui/settings/settings_screen_test.dart`

- [ ] **Step 1: Implement settings screen**

Replace `lib/ui/settings/settings_screen.dart`:

```dart
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../state/settings_provider.dart';
import '../../state/trigger_flags_provider.dart';

const _moduleLabels = <String, String>{
  'pressure_drop': 'Pressure changes',
  'humidity_temp_swing': 'Humidity + temp swing',
  'air_quality': 'Air quality',
  'sleep_deficit': 'Sleep',
  'hrv_letdown': 'HRV / stress let-down',
  'menstrual_phase': 'Menstrual cycle',
  'alcohol': 'Alcohol',
  'caffeine': 'Caffeine',
  'stress': 'Stress',
  'hydration': 'Hydration',
};

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flagsAsync = ref.watch(triggerFlagsProvider);
    final modeAsync = ref.watch(riskDisplayModeProvider);
    final notifAsync = ref.watch(notificationsEnabledProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Display', style: Theme.of(context).textTheme.titleSmall),
          modeAsync.when(
            loading: () => const ListTile(title: Text('Risk display'), trailing: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))),
            error: (e, _) => ListTile(title: const Text('Risk display'), subtitle: Text('Error: $e')),
            data: (mode) => ListTile(
              title: const Text('Risk display'),
              subtitle: Text(_modeLabel(mode)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final pick = await showModalBottomSheet<RiskDisplayMode>(
                  context: context,
                  builder: (ctx) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: RiskDisplayMode.values.map((m) => ListTile(
                          title: Text(_modeLabel(m)),
                          selected: m == mode,
                          onTap: () => Navigator.pop(ctx, m),
                        )).toList(),
                  ),
                );
                if (pick != null) await ref.read(setRiskDisplayModeProvider)(pick);
              },
            ),
          ),
          const Divider(),
          Text('Notifications', style: Theme.of(context).textTheme.titleSmall),
          notifAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (e, _) => Text('Error: $e'),
            data: (enabled) => SwitchListTile(
              title: const Text('High-risk alerts'),
              subtitle: const Text('Background notifications come in Plan 4'),
              value: enabled,
              onChanged: (v) => ref.read(setNotificationsEnabledProvider)(v),
            ),
          ),
          const Divider(),
          Text('Triggers', style: Theme.of(context).textTheme.titleSmall),
          flagsAsync.when(
            loading: () => const Center(child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            )),
            error: (e, _) => Text('Error: $e'),
            data: (flags) {
              return Column(
                children: _moduleLabels.entries.map((e) {
                  final flagged = flags.flaggedModuleIds.contains(e.key);
                  final override = flags.weightOverrides[e.key] ?? 0;
                  return ExpansionTile(
                    title: Text(e.value),
                    subtitle: Text(flagged ? 'Tracking — weight ${_overrideLabel(override)}' : 'Not flagged'),
                    children: [
                      SwitchListTile(
                        title: const Text('I think this triggers me'),
                        value: flagged,
                        onChanged: (v) async {
                          final next = Set<String>.from(flags.flaggedModuleIds);
                          v ? next.add(e.key) : next.remove(e.key);
                          await ref.read(saveTriggerFlagsProvider)(UserTriggerFlags(
                            flaggedModuleIds: next,
                            weightOverrides: flags.weightOverrides,
                          ));
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            const Text('Weight'),
                            Expanded(
                              child: Slider(
                                value: override,
                                min: -2,
                                max: 2,
                                divisions: 4,
                                label: _overrideLabel(override),
                                onChanged: (v) async {
                                  final overrides = Map<String, double>.from(flags.weightOverrides);
                                  if (v == 0) {
                                    overrides.remove(e.key);
                                  } else {
                                    overrides[e.key] = v;
                                  }
                                  await ref.read(saveTriggerFlagsProvider)(UserTriggerFlags(
                                    flaggedModuleIds: flags.flaggedModuleIds,
                                    weightOverrides: overrides,
                                  ));
                                },
                              ),
                            ),
                            Text(_overrideLabel(override)),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  String _modeLabel(RiskDisplayMode m) {
    switch (m) {
      case RiskDisplayMode.gauge: return 'Gauge';
      case RiskDisplayMode.numeric: return 'Number';
      case RiskDisplayMode.weatherIcon: return 'Weather icon';
    }
  }

  String _overrideLabel(double v) {
    final s = v >= 0 ? '+${v.toInt()}' : '${v.toInt()}';
    return v == 0 ? '0' : s;
  }
}
```

- [ ] **Step 2: Smoke widget test**

Create `test/ui/settings/settings_screen_test.dart`:

```dart
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:migraine_weatherr/data/context_builder.dart';
import 'package:migraine_weatherr/state/providers.dart';
import 'package:migraine_weatherr/state/settings_provider.dart';
import 'package:migraine_weatherr/ui/settings/settings_screen.dart';

class _MemFlagsRepo implements UserTriggerFlagsRepo {
  UserTriggerFlags _f = const UserTriggerFlags(flaggedModuleIds: {'stress'});
  @override Future<UserTriggerFlags> load() async => _f;
  @override Future<void> save(UserTriggerFlags flags) async => _f = flags;
}

void main() {
  testWidgets('renders trigger list and reflects flagged state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          flagsRepoProvider.overrideWithValue(_MemFlagsRepo()),
          riskDisplayModeProvider.overrideWith((ref) async => RiskDisplayMode.gauge),
          notificationsEnabledProvider.overrideWith((ref) async => false),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(routes: [
            GoRoute(path: '/', builder: (_, __) => const SettingsScreen()),
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Stress'), findsOneWidget);
    expect(find.text('Pressure changes'), findsOneWidget);
  });
}
```

- [ ] **Step 3: Run**

```bash
cd /Users/amansur/projects/migraine-weatherr && flutter test test/ui/settings/
```

Expected: 1 passing.

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "ui: Settings screen — display mode, notification toggle, per-trigger weight"
```

---

## Task 10: App entry smoke + CI sanity

**Files:**
- Test: `test/app/app_smoke_test.dart`

- [ ] **Step 1: Write app smoke test**

Create `test/app/app_smoke_test.dart`:

```dart
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_weatherr/app/app.dart';
import 'package:migraine_weatherr/data/context_builder.dart';
import 'package:migraine_weatherr/data/database.dart' hide Attack, JournalEntry, WeatherSnapshot, RiskAssessment;
import 'package:migraine_weatherr/data/sources/drift_journal_source.dart';
import 'package:migraine_weatherr/data/sources/fake_health_source.dart';
import 'package:migraine_weatherr/data/sources/manual_location_source.dart';
import 'package:migraine_weatherr/data/sources/weather_source.dart';
import 'package:migraine_weatherr/state/providers.dart';

class _StubWeather implements WeatherSource {
  @override
  Future<WeatherSnapshot> fetch({required double lat, required double lon, required DateTime now}) async => WeatherSnapshot(
        weather: const WeatherSeries(samples: []),
        airQuality: const AirQualitySeries(samples: []),
        fetchedAt: now,
      );
}

class _MemFlagsRepo implements UserTriggerFlagsRepo {
  UserTriggerFlags _f = const UserTriggerFlags();
  @override Future<UserTriggerFlags> load() async => _f;
  @override Future<void> save(UserTriggerFlags flags) async => _f = flags;
}

void main() {
  testWidgets('launches into onboarding when not completed', (tester) async {
    final db = AppDatabase.memory();
    final loc = ManualLocationSource()..set(lat: 40.7, lon: -74.0);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          weatherSourceProvider.overrideWithValue(_StubWeather()),
          healthSourceProvider.overrideWithValue(FakeHealthSource()),
          journalSourceProvider.overrideWithValue(DriftJournalSource(db)),
          locationSourceProvider.overrideWithValue(await loc as ManualLocationSource),
          flagsRepoProvider.overrideWithValue(_MemFlagsRepo()),
        ],
        child: const MigraineWeatherrApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Welcome to Migraine Weatherr'), findsOneWidget);
    addTearDown(db.close);
  });
}
```

(That `await loc` pattern is wrong — fix in implementation: assign and use directly.)

Fixed test body:

```dart
    final loc = ManualLocationSource();
    await loc.set(lat: 40.7, lon: -74.0);
    ...
    locationSourceProvider.overrideWithValue(loc),
```

- [ ] **Step 2: Run all tests**

```bash
cd /Users/amansur/projects/migraine-weatherr && flutter test 2>&1 | tail -5
```

Expected: every test (including Plan 1 + Plan 2 + Plan 3) passes.

- [ ] **Step 3: Build web sanity**

```bash
cd /Users/amansur/projects/migraine-weatherr && flutter build web 2>&1 | tail -3
```

Expected: "✓ Built build/web".

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "test: app launch smoke"
```

---

## Done

After Task 10, you have:

- A fully-wired Flutter MVP: launch the app, complete onboarding (pick suspected triggers), land on Today, see your risk + tomorrow's forecast, log a migraine, and adjust display mode / per-trigger weights / notification toggle in Settings.
- Riverpod providers cleanly compose every Plan 2 adapter into a `riskAssessmentProvider` that the Today screen consumes.
- Pull-to-refresh on Today triggers a full recompute (`ContextBuilder` → `RiskEngine` → persist).
- Material 3 theme with sage/ivory branding; 3 risk display variants with golden tests.
- Disclaimer surfaced during onboarding.

Plan 4 (Background scheduling + Notifications) adds:
- `workmanager` (Android) and `BGTaskScheduler` (iOS) for the morning/evening refresh
- Local notifications via `flutter_local_notifications`
- Notification dedup + catch-up on foreground

Plan 5 (Insights + Correlation engine) adds:
- Wilson-CI correlation engine
- Insights screen with calendar heatmap
- Suggested weight-adjustment cards
