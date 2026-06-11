# Plan 4 — Background Scheduling + Notifications (+ Web sqlite3 fix)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement task-by-task. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Two scheduled refreshes per day (morning at 6am, evening at 8pm) that recompute risk and fire a local notification when the score crosses the High band, deduped per (date, horizon, band). When the app comes back to foreground after >6h offline, catch up with a refresh. Also fix the web build regression that Plan 2's Drift wiring introduced.

**Architecture:** `flutter_local_notifications` for the OS-level notification surface. `workmanager` for periodic background tasks on both iOS (via BGTaskScheduler) and Android (via WorkManager). A new `NotificationDedupRepo` (Drift) records every (date, horizon, band) the app has notified about so refreshes that recompute the same risk don't spam. An `AppLifecycleObserver` in `MigraineWeatherrApp` triggers a foreground catch-up. For web, swap the Drift database setup to use `sqlite3_web` with the WASM artifact served from `web/`.

**Tech Stack:** Flutter 3.44 / Dart 3.12. `flutter_local_notifications` ^17.2, `workmanager` ^0.5.2, `drift_flutter` ^0.2 (multi-platform Drift bootstrap), `sqlite3` ^2.4 (web).

---

## File Structure

```
/Users/amansur/projects/migraine-weatherr/
├── web/
│   ├── sqlite3.wasm                              # added
│   └── drift_worker.js                           # added (drift web worker)
├── lib/
│   ├── data/
│   │   ├── database.dart                         # schema v2 with notifications_sent
│   │   ├── database.g.dart                       # regenerated
│   │   └── repos/
│   │       └── notification_dedup_repo.dart      # new
│   ├── services/
│   │   ├── notification_service.dart             # flutter_local_notifications wrapper
│   │   ├── high_risk_notifier.dart               # band → notification decision
│   │   ├── lifecycle_observer.dart               # foreground catch-up
│   │   └── background_scheduler.dart             # workmanager registration + callback
│   ├── state/
│   │   └── providers.dart                        # add notification + scheduler providers
│   └── app/
│       └── app.dart                              # wire lifecycle observer
├── ios/
│   └── Runner/Info.plist                         # background modes + BGTask identifier
├── android/
│   └── app/src/main/AndroidManifest.xml          # WorkManager permissions
├── test/
│   ├── data/repos/notification_dedup_repo_test.dart
│   └── services/
│       ├── high_risk_notifier_test.dart
│       └── lifecycle_observer_test.dart
└── docs/superpowers/plans/2026-06-11-plan4-background-notifications.md
```

---

## Task 1: Web sqlite3 fix

**Files:**
- Modify: `pubspec.yaml`
- Modify: `lib/data/database.dart` (swap to multi-platform connection)
- Create: `web/sqlite3.wasm`, `web/drift_worker.js`

- [ ] **Step 1: Add deps**

Edit `pubspec.yaml`. Under `dependencies:`:

```yaml
  drift_flutter: ^0.2.0
  sqlite3: ^2.4.0
  drift: ^2.18.0  # already present; ensure version is recent enough
```

`drift_flutter` provides a unified `driftDatabase()` helper that picks the right backend per platform (`NativeDatabase` on mobile/desktop, `WasmDatabase` on web with the bundled wasm + worker).

Run:
```bash
cd /Users/amansur/projects/migraine-weatherr && flutter pub get
```

- [ ] **Step 2: Download the wasm + worker artifacts**

```bash
cd /Users/amansur/projects/migraine-weatherr
dart run drift_dev setup-web
```

This is the official Drift command that writes `web/sqlite3.wasm` and `web/drift_worker.js` matching the installed Drift version. If the command name has drifted in newer drift_dev versions, the equivalent is:

```bash
curl -L -o web/sqlite3.wasm https://github.com/simolus3/sqlite3.dart/releases/latest/download/sqlite3.wasm
curl -L -o web/drift_worker.js https://github.com/simolus3/drift/releases/latest/download/drift_worker.js
```

Verify the files exist and are non-trivial (sqlite3.wasm ~1.4 MB):

```bash
ls -la web/sqlite3.wasm web/drift_worker.js
```

- [ ] **Step 3: Swap the database connection to multi-platform**

Edit `lib/data/database.dart`. Replace the existing `_openConnection()` and `openAppDatabase()` block (everything from `LazyDatabase _openConnection() => ...` to the end) with:

```dart
QueryExecutor _openConnection() {
  return driftDatabase(name: 'migraine_weatherr');
}

AppDatabase openAppDatabase() => AppDatabase(_openConnection());
```

And update the imports at the top of `database.dart`:

```dart
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
```

Remove the now-unused imports of `dart:io`, `package:drift/native.dart`, `package:path/path.dart`, `package:path_provider/path_provider.dart`.

Keep the `AppDatabase.memory()` factory unchanged — it still uses `NativeDatabase.memory()` which works in tests. Add the import back just for that:

```dart
import 'package:drift/native.dart' show NativeDatabase;
```

- [ ] **Step 4: Regenerate codegen**

```bash
cd /Users/amansur/projects/migraine-weatherr && dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 5: Verify web build**

```bash
cd /Users/amansur/projects/migraine-weatherr && flutter build web 2>&1 | tail -3
```

Expected: "✓ Built build/web".

If the build complains about CORS or missing wasm at runtime, the wasm files are in `web/` (correct location) — Flutter's web build copies them. The fix is at build time, not runtime.

- [ ] **Step 6: Verify all platforms still pass tests**

```bash
cd /Users/amansur/projects/migraine-weatherr && flutter test 2>&1 | tail -3
```

Expected: 45/45 still pass (the in-memory `NativeDatabase.memory()` path is unchanged).

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "data: multi-platform Drift connection; fix web build with sqlite3_web"
```

---

## Task 2: Drift migration — notifications_sent table

**Files:**
- Modify: `lib/data/database.dart` (add table + bump schemaVersion + migration)
- Regenerated: `lib/data/database.g.dart`

- [ ] **Step 1: Add the table to `database.dart`**

Insert the new table class above `@DriftDatabase(...)`:

```dart
class NotificationsSent extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get targetDate => dateTime()();
  TextColumn get horizon => text()();   // 'today' | 'tomorrow'
  TextColumn get band => text()();      // 'high' | 'veryHigh'
  DateTimeColumn get sentAt => dateTime()();
}
```

Add `NotificationsSent` to the `tables:` list in `@DriftDatabase(...)`:

```dart
@DriftDatabase(tables: [
  Attacks,
  JournalEntries,
  WeatherSnapshots,
  BaselinesKv,
  UserTriggerFlagsTbl,
  RiskAssessments,
  Settings,
  NotificationsSent,
])
```

Bump `schemaVersion`:

```dart
@override
int get schemaVersion => 2;
```

Add a migration strategy override:

```dart
@override
MigrationStrategy get migration => MigrationStrategy(
      onCreate: (m) async => m.createAll(),
      onUpgrade: (m, from, to) async {
        if (from < 2) await m.createTable(notificationsSent);
      },
    );
```

- [ ] **Step 2: Regenerate**

```bash
cd /Users/amansur/projects/migraine-weatherr && dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 3: Verify tests still pass**

```bash
cd /Users/amansur/projects/migraine-weatherr && flutter test 2>&1 | tail -3
```

Expected: 45/45 still pass. In-memory tests get `onCreate` which calls `createAll()`, so the new table is created clean.

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "data: add notifications_sent table (schema v2 with migration)"
```

---

## Task 3: NotificationDedupRepo

**Files:**
- Create: `lib/data/repos/notification_dedup_repo.dart`
- Test: `test/data/repos/notification_dedup_repo_test.dart`

- [ ] **Step 1: Write failing test**

Create `test/data/repos/notification_dedup_repo_test.dart`:

```dart
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_weatherr/data/database.dart' hide Attack, JournalEntry, WeatherSnapshot, RiskAssessment;
import 'package:migraine_weatherr/data/repos/notification_dedup_repo.dart';

void main() {
  late AppDatabase db;
  late NotificationDedupRepo repo;
  setUp(() {
    db = AppDatabase.memory();
    repo = NotificationDedupRepo(db);
  });
  tearDown(() => db.close());

  final date = DateTime.utc(2026, 6, 11);
  final now = DateTime.utc(2026, 6, 11, 6);

  test('hasNotifiedFor is false initially', () async {
    expect(await repo.hasNotifiedFor(date: date, horizon: RiskHorizon.today, band: RiskBand.high), isFalse);
  });

  test('record then check returns true', () async {
    await repo.record(date: date, horizon: RiskHorizon.today, band: RiskBand.high, at: now);
    expect(await repo.hasNotifiedFor(date: date, horizon: RiskHorizon.today, band: RiskBand.high), isTrue);
  });

  test('different horizons are tracked independently', () async {
    await repo.record(date: date, horizon: RiskHorizon.today, band: RiskBand.high, at: now);
    expect(await repo.hasNotifiedFor(date: date, horizon: RiskHorizon.tomorrow, band: RiskBand.high), isFalse);
  });

  test('different bands are tracked independently (escalating high → very_high should re-notify)', () async {
    await repo.record(date: date, horizon: RiskHorizon.today, band: RiskBand.high, at: now);
    expect(await repo.hasNotifiedFor(date: date, horizon: RiskHorizon.today, band: RiskBand.veryHigh), isFalse);
  });
}
```

- [ ] **Step 2: Run — expect FAIL**

```bash
cd /Users/amansur/projects/migraine-weatherr && flutter test test/data/repos/notification_dedup_repo_test.dart
```

- [ ] **Step 3: Implement**

Create `lib/data/repos/notification_dedup_repo.dart`:

```dart
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
```

- [ ] **Step 4: Run — expect PASS**

```bash
cd /Users/amansur/projects/migraine-weatherr && flutter test test/data/repos/notification_dedup_repo_test.dart
```

Expected: 4 passing.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "data: NotificationDedupRepo"
```

---

## Task 4: NotificationService (flutter_local_notifications wrapper)

**Files:**
- Modify: `pubspec.yaml`
- Create: `lib/services/notification_service.dart`
- Modify: `ios/Runner/Info.plist`
- Modify: `android/app/src/main/AndroidManifest.xml`

- [ ] **Step 1: Add dependency**

Edit `pubspec.yaml`, under `dependencies:`:

```yaml
  flutter_local_notifications: ^17.2.0
  timezone: ^0.9.4
```

Run:
```bash
cd /Users/amansur/projects/migraine-weatherr && flutter pub get
```

- [ ] **Step 2: Implement the service**

Create `lib/services/notification_service.dart`:

```dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;
  NotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    if (_initialized) return;
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(settings);
    _initialized = true;
  }

  /// Returns true if permission is granted.
  Future<bool> requestPermissions() async {
    final iOSPlugin = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    final iosGranted = await iOSPlugin?.requestPermissions(alert: true, sound: true);
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final androidGranted = await androidPlugin?.requestNotificationsPermission();
    return (iosGranted ?? true) && (androidGranted ?? true);
  }

  Future<void> showHighRisk({
    required int notificationId,
    required String title,
    required String body,
  }) async {
    await _plugin.show(
      notificationId,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'high_risk',
          'High risk alerts',
          channelDescription: 'Daily migraine risk alerts',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
      ),
    );
  }
}
```

- [ ] **Step 3: iOS Info.plist**

Edit `ios/Runner/Info.plist`. Inside the top-level `<dict>`, add a `UIBackgroundModes` array and a `BGTaskSchedulerPermittedIdentifiers` array:

```xml
<key>UIBackgroundModes</key>
<array>
  <string>fetch</string>
  <string>processing</string>
</array>
<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
  <string>com.migraineweatherr.morning_refresh</string>
  <string>com.migraineweatherr.evening_refresh</string>
</array>
```

If `UIBackgroundModes` already exists from a previous task, merge the strings into the existing array instead of adding a duplicate key.

- [ ] **Step 4: Android manifest**

Edit `android/app/src/main/AndroidManifest.xml`. Inside `<manifest>`, before `<application>`, ensure:

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
```

(POST_NOTIFICATIONS is needed for Android 13+, the other two are for `workmanager` to schedule reliably.)

- [ ] **Step 5: Smoke-verify pub get**

```bash
cd /Users/amansur/projects/migraine-weatherr && flutter pub get && flutter analyze lib/services/notification_service.dart 2>&1 | tail -3
```

Expected: no errors.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "services: NotificationService + platform permissions"
```

---

## Task 5: HighRiskNotifier (band → decide → notify, with dedup)

**Files:**
- Create: `lib/services/high_risk_notifier.dart`
- Test: `test/services/high_risk_notifier_test.dart`

- [ ] **Step 1: Write failing test**

Create `test/services/high_risk_notifier_test.dart`:

```dart
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_weatherr/data/database.dart' hide Attack, JournalEntry, WeatherSnapshot, RiskAssessment;
import 'package:migraine_weatherr/data/repos/notification_dedup_repo.dart';
import 'package:migraine_weatherr/services/high_risk_notifier.dart';
import 'package:migraine_weatherr/services/notification_service.dart';

class _FakeNotifications implements NotificationService {
  final calls = <_Call>[];
  @override Future<void> init() async {}
  @override Future<bool> requestPermissions() async => true;
  @override
  Future<void> showHighRisk({required int notificationId, required String title, required String body}) async {
    calls.add(_Call(id: notificationId, title: title, body: body));
  }
}

class _Call {
  final int id;
  final String title;
  final String body;
  _Call({required this.id, required this.title, required this.body});
}

RiskAssessment _ass(int score, RiskBand band, {RiskHorizon horizon = RiskHorizon.today}) => RiskAssessment(
      score: score,
      band: band,
      contributors: const [],
      computedAt: DateTime.utc(2026, 6, 11, 6),
      configVersion: 1,
      targetDate: DateTime.utc(2026, 6, 11),
      horizon: horizon,
    );

void main() {
  late AppDatabase db;
  late NotificationDedupRepo dedup;
  late _FakeNotifications notifications;
  late HighRiskNotifier notifier;
  setUp(() {
    db = AppDatabase.memory();
    dedup = NotificationDedupRepo(db);
    notifications = _FakeNotifications();
    notifier = HighRiskNotifier(notifications: notifications, dedup: dedup);
  });
  tearDown(() => db.close());

  test('does nothing for low/moderate bands', () async {
    await notifier.maybeNotify(_ass(20, RiskBand.low), enabled: true);
    await notifier.maybeNotify(_ass(40, RiskBand.moderate), enabled: true);
    expect(notifications.calls, isEmpty);
  });

  test('does nothing if notifications disabled', () async {
    await notifier.maybeNotify(_ass(60, RiskBand.high), enabled: false);
    expect(notifications.calls, isEmpty);
  });

  test('fires once for high band, then dedups', () async {
    await notifier.maybeNotify(_ass(60, RiskBand.high), enabled: true);
    await notifier.maybeNotify(_ass(60, RiskBand.high), enabled: true);
    expect(notifications.calls, hasLength(1));
  });

  test('escalation from high → veryHigh fires a second notification', () async {
    await notifier.maybeNotify(_ass(60, RiskBand.high), enabled: true);
    await notifier.maybeNotify(_ass(80, RiskBand.veryHigh), enabled: true);
    expect(notifications.calls, hasLength(2));
  });
}
```

- [ ] **Step 2: Run — expect FAIL**

```bash
cd /Users/amansur/projects/migraine-weatherr && flutter test test/services/high_risk_notifier_test.dart
```

- [ ] **Step 3: Implement**

Create `lib/services/high_risk_notifier.dart`:

```dart
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
    return ('$when\'s migraine risk is $band', 'Score ${ass.score}/100$top');
  }

  int _idFor(RiskAssessment ass) {
    // Stable per (date, horizon, band) so OS replaces rather than stacking.
    return Object.hash(ass.targetDate.millisecondsSinceEpoch, ass.horizon.name, ass.band.name) & 0x7fffffff;
  }
}
```

- [ ] **Step 4: Run**

```bash
cd /Users/amansur/projects/migraine-weatherr && flutter test test/services/high_risk_notifier_test.dart
```

Expected: 4 passing.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "services: HighRiskNotifier with dedup + escalation"
```

---

## Task 6: LifecycleObserver for foreground catch-up

**Files:**
- Create: `lib/services/lifecycle_observer.dart`
- Modify: `lib/app/app.dart` (register observer)
- Test: `test/services/lifecycle_observer_test.dart`

- [ ] **Step 1: Write failing test**

Create `test/services/lifecycle_observer_test.dart`:

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_weatherr/services/lifecycle_observer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('refreshes when resumed after stale window', () async {
    var refreshes = 0;
    DateTime now = DateTime.utc(2026, 6, 11, 12);
    final observer = AppLifecycleObserver(
      staleAfter: const Duration(hours: 6),
      lastRefreshAt: () async => now.subtract(const Duration(hours: 7)),
      refresh: () async => refreshes++,
      clock: () => now,
    );
    await observer.didChangeAppLifecycleStateForTest(AppLifecycleState.resumed);
    expect(refreshes, 1);
  });

  test('does not refresh when within freshness window', () async {
    var refreshes = 0;
    DateTime now = DateTime.utc(2026, 6, 11, 12);
    final observer = AppLifecycleObserver(
      staleAfter: const Duration(hours: 6),
      lastRefreshAt: () async => now.subtract(const Duration(hours: 2)),
      refresh: () async => refreshes++,
      clock: () => now,
    );
    await observer.didChangeAppLifecycleStateForTest(AppLifecycleState.resumed);
    expect(refreshes, 0);
  });

  test('does not refresh on backgrounding', () async {
    var refreshes = 0;
    final observer = AppLifecycleObserver(
      staleAfter: const Duration(hours: 6),
      lastRefreshAt: () async => DateTime.utc(2026, 6, 10),
      refresh: () async => refreshes++,
      clock: () => DateTime.utc(2026, 6, 11, 12),
    );
    await observer.didChangeAppLifecycleStateForTest(AppLifecycleState.paused);
    expect(refreshes, 0);
  });
}
```

- [ ] **Step 2: Run — expect FAIL**

```bash
cd /Users/amansur/projects/migraine-weatherr && flutter test test/services/lifecycle_observer_test.dart
```

- [ ] **Step 3: Implement**

Create `lib/services/lifecycle_observer.dart`:

```dart
import 'package:flutter/widgets.dart';

class AppLifecycleObserver extends WidgetsBindingObserver {
  final Duration staleAfter;
  final Future<DateTime?> Function() lastRefreshAt;
  final Future<void> Function() refresh;
  final DateTime Function() clock;
  AppLifecycleObserver({
    required this.staleAfter,
    required this.lastRefreshAt,
    required this.refresh,
    DateTime Function()? clock,
  }) : clock = clock ?? DateTime.now;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    didChangeAppLifecycleStateForTest(state);
  }

  /// Same as [didChangeAppLifecycleState] but awaits the work so tests can
  /// assert on it.
  Future<void> didChangeAppLifecycleStateForTest(AppLifecycleState state) async {
    if (state != AppLifecycleState.resumed) return;
    final last = await lastRefreshAt();
    if (last == null) {
      await refresh();
      return;
    }
    final age = clock().difference(last);
    if (age >= staleAfter) await refresh();
  }
}
```

- [ ] **Step 4: Wire into `app.dart`**

Edit `lib/app/app.dart`. Convert `MigraineWeatherrApp` to a `ConsumerStatefulWidget`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/lifecycle_observer.dart';
import '../state/providers.dart';
import '../state/risk_assessment_provider.dart';
import 'router.dart';
import 'theme.dart';

class MigraineWeatherrApp extends ConsumerStatefulWidget {
  const MigraineWeatherrApp({super.key});
  @override
  ConsumerState<MigraineWeatherrApp> createState() => _MigraineWeatherrAppState();
}

class _MigraineWeatherrAppState extends ConsumerState<MigraineWeatherrApp> {
  late final AppLifecycleObserver _observer;

  @override
  void initState() {
    super.initState();
    _observer = AppLifecycleObserver(
      staleAfter: const Duration(hours: 6),
      lastRefreshAt: () async {
        // Plan 5 will read the last RiskAssessment.computedAt; for now,
        // return null on first run so refresh is skipped without a real value.
        return null;
      },
      refresh: () async {
        await ref.read(riskAssessmentProvider.notifier).refresh();
      },
    );
    WidgetsBinding.instance.addObserver(_observer);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_observer);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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

The `lastRefreshAt` callback returns `null` for now — wiring it to the real `AssessmentRepository.latestForDate().computedAt` is a one-liner once we have the right ref, but with proper Plan 5 history view. For Plan 4 the empty-result path is acceptable (we refresh aggressively rather than stale-suppress on first run).

- [ ] **Step 5: Run**

```bash
cd /Users/amansur/projects/migraine-weatherr && flutter test test/services/lifecycle_observer_test.dart
```

Expected: 3 passing.

Full suite:

```bash
cd /Users/amansur/projects/migraine-weatherr && flutter test 2>&1 | tail -3
```

Expected: still all green.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "services: AppLifecycleObserver for foreground catch-up"
```

---

## Task 7: Background scheduling (workmanager)

**Files:**
- Modify: `pubspec.yaml`
- Create: `lib/services/background_scheduler.dart`
- Modify: `lib/main.dart` (workmanager init + dispatch callback)

This task is **not unit-testable** — `workmanager` requires platform channels. Test plan: deploy to a real device, verify the morning/evening tasks fire and notifications appear.

- [ ] **Step 1: Add dep**

Edit `pubspec.yaml`, under `dependencies:`:

```yaml
  workmanager: ^0.5.2
```

```bash
cd /Users/amansur/projects/migraine-weatherr && flutter pub get
```

- [ ] **Step 2: Implement scheduler**

Create `lib/services/background_scheduler.dart`:

```dart
import 'package:domain/domain.dart';
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
      morningTask, morningTask,
      frequency: const Duration(hours: 24),
      initialDelay: _delayUntilNext(hour: 6),
      constraints: Constraints(networkType: NetworkType.connected),
    );
    await Workmanager().registerPeriodicTask(
      eveningTask, eveningTask,
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
    // Re-create the world manually inside the isolate.
    final db = openAppDatabase();
    final notif = NotificationService();
    await notif.init();
    final highRisk = HighRiskNotifier(
      notifications: notif,
      dedup: NotificationDedupRepo(db),
    );
    final builder = ContextBuilder(
      weather: OpenMeteoWeatherSource(client: _httpClient(), db: db),
      health: HealthPackageSource(),
      journal: DriftJournalSource(db),
      location: GeolocatorLocationSource(),
      flagsRepo: UserTriggerFlagsRepoDrift(db),
      baselineBuilder: const BaselineSnapshotBuilder(BaselineStore()),
      db: db,
    );
    final engine = RiskEngine(modules: [
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
    ]);
    final settings = SettingsRepo(db);
    final cfgText = await _loadConfigText();
    final cfg = RulesConfigLoader.parse(cfgText);
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
    await db.close();
    return true;
  });
}

// Internal helpers below — extracted so the dispatcher stays linear.

import 'dart:io';
import 'package:http/http.dart' as http;

http.Client _httpClient() => http.Client();

Future<String> _loadConfigText() async {
  // The isolate can't use rootBundle. Read from the app bundle dir via path_provider.
  // Simplest path for v1: load from a hardcoded asset name shipped via the app's
  // documents dir. If unavailable, fall back to the bundled fallback.
  try {
    final file = File('${Directory.current.path}/assets/rules_config_v1.json');
    return file.readAsStringSync();
  } catch (_) {
    return _bundledFallback;
  }
}

const _bundledFallback = '''
{"version":1,"modules":{},"score_bands":{"low":25,"moderate":50,"high":75},"unflagged_trigger_confidence_multiplier":0.6}
''';
```

⚠ The `_loadConfigText` helper is brittle — Drift workers/background isolates can't access `rootBundle`. Production fix: at app startup, copy `assets/rules_config_v1.json` to the documents dir; the isolate reads it from there. For Plan 4, the inline fallback gracefully degrades (engine produces an onboarding assessment, no notification fires).

- [ ] **Step 3: Initialize in `main.dart`**

Edit `lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'services/background_scheduler.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final notif = NotificationService();
  await notif.init();
  await BackgroundScheduler().register();
  runApp(const ProviderScope(child: MigraineWeatherrApp()));
}
```

- [ ] **Step 4: Verify it builds**

```bash
cd /Users/amansur/projects/migraine-weatherr && flutter build apk --debug 2>&1 | tail -5
```

(Use `flutter build apk` if Android SDK is installed; otherwise skip and rely on `flutter analyze`.)

```bash
cd /Users/amansur/projects/migraine-weatherr && flutter analyze lib/services/background_scheduler.dart lib/main.dart 2>&1 | tail -5
```

Expected: no errors.

- [ ] **Step 5: Run full test suite (background code not unit-tested but other tests still pass)**

```bash
cd /Users/amansur/projects/migraine-weatherr && flutter test 2>&1 | tail -3
```

Expected: still all green.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "services: background scheduling via workmanager (morning + evening)"
```

---

## Task 8: Wire HighRiskNotifier into the risk assessment provider

**Files:**
- Modify: `lib/state/providers.dart` (add HighRiskNotifier provider)
- Modify: `lib/state/risk_assessment_provider.dart` (call maybeNotify after computing)

- [ ] **Step 1: Add providers**

Edit `lib/state/providers.dart` — at the bottom, after the existing `riskEngineProvider`:

```dart
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final svc = NotificationService();
  ref.onDispose(() {});
  return svc;
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
```

Add the necessary imports at the top:

```dart
import '../data/repos/notification_dedup_repo.dart';
import '../services/high_risk_notifier.dart';
import '../services/notification_service.dart';
```

- [ ] **Step 2: Hook into the notifier**

Edit `lib/state/risk_assessment_provider.dart`. In `RiskAssessmentNotifier._compute()`, after `await ref.read(assessmentRepoProvider).save(ass);` and before `return ass;`, add:

```dart
final enabled = await ref.read(settingsRepoProvider).getBool('notifications_enabled');
await ref.read(highRiskNotifierProvider).maybeNotify(ass, enabled: enabled);
```

Do the same in `TomorrowRiskAssessmentNotifier._compute()`.

- [ ] **Step 3: Verify all tests still pass**

```bash
cd /Users/amansur/projects/migraine-weatherr && flutter test 2>&1 | tail -3
```

Expected: still green. The existing `risk_assessment_provider_test.dart` overrides `flagsRepoProvider` but NOT `notificationServiceProvider` — the test only exercises the empty-context onboarding path, which has band `low` and therefore doesn't trigger `showHighRisk`. If the test fails because `NotificationService` can't be constructed in the test environment, add an override:

```dart
notificationServiceProvider.overrideWithValue(_FakeNotifications()),
```

with a tiny fake. Adjust the test imports.

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "state: wire HighRiskNotifier into risk assessment compute path"
```

---

## Task 9: Documentation + CI sanity

**Files:**
- Modify: `README.md` (mark Plan 4 done; remove the "web broken" line)
- Run CI checks locally

- [ ] **Step 1: Update README**

Edit the Status block in `README.md` to:

```markdown
- **Plan 4** — Background scheduling + notifications (+ web sqlite3 fix) ✓
- **Plan 5** — Insights screen + correlation-driven personalization — not started
```

Remove the "Currently broken — `sqlite3_flutter_libs`..." paragraph under the Web section and replace with:

```markdown
### Web

`flutter build web` works and serves the app. SQLite runs via WASM (the `sqlite3.wasm` + drift worker are bundled in `web/`). Limitations: the `health` plugin has no web implementation; geolocator on web requires HTTPS + browser permission; background notifications go through the browser's Push API which we don't wire in v1.
```

- [ ] **Step 2: Run all sanity checks**

```bash
cd /Users/amansur/projects/migraine-weatherr
flutter analyze 2>&1 | tail -3
dart run build_runner build --delete-conflicting-outputs 2>&1 | tail -2
flutter test 2>&1 | tail -3
flutter build web 2>&1 | tail -3
cd packages/domain && dart test 2>&1 | tail -3
```

Expected:
- `flutter analyze` exits 0.
- `build_runner` succeeds.
- `flutter test` — all green.
- `flutter build web` — "✓ Built build/web".
- Domain tests — 69/69 passing.

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "docs: Plan 4 status; web build is back"
```

---

## Done

After Task 9, you have:

- Web build restored (`flutter build web` produces a working bundle).
- Two scheduled background tasks (6am morning, 8pm evening) that wake the app, recompute risk, save the assessment, and notify if it lands in the High or Very High band.
- Notifications are deduped per (date, horizon, band) so the same alert never fires twice; an escalation (high → very_high) re-notifies.
- Foreground catch-up via `AppLifecycleObserver` — when the app resumes after >6h offline, it refreshes immediately.
- The `notifications_enabled` toggle in Settings (from Plan 3) now genuinely controls whether notifications fire.

Plan 5 (final plan) adds:
- Wilson-CI correlation engine over logged attacks + module signals
- Insights screen with a calendar heatmap and per-trigger correlation cards
- Suggested-weight-adjustment cards on Insights (user-in-the-loop personalization — replaces the deferred ML pipeline)
- Hooks the `lastRefreshAt` callback into the AssessmentRepository's most-recent `computedAt` (Plan 4 left it stubbed)
