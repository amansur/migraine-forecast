# Oura Ring Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Integrate Oura Ring as a first-class health data source alongside Apple Health, with OAuth-based authentication, token refresh, intelligent fallback, and a working settings UI users can actually connect from.

**Architecture:** Five layers — (1) OAuth auth manager that owns tokens and refresh, (2) HTTP API client that takes a *callback* to fetch a valid token (not a static string), (3) HealthSource implementation that maps Oura → HealthMetrics, (4) HealthSourceFactory that decides which source to use, (5) UI + Riverpod providers wired together so the Connect button actually works. All data cached locally in Drift.

**Tech Stack:** Dart/Flutter, Riverpod (state), Drift (storage), `flutter_secure_storage` (OAuth tokens), `flutter_web_auth_2` (browser-based OAuth), `http` package.

---

## Dependency order (read before starting)

Tasks are ordered so each one only depends on what's already merged. **Do not skip ahead** — earlier mistakes had the settings card (Task 9 originally) built before its providers existed (Task 12 originally), leaving a hardcoded `isAuthenticated = false` stub in production code. The reordered sequence:

1. Deps → 2. HealthMetrics shape → 3. Models → 4. AuthManager (with refresh) → 5. ApiClient (token-callback shaped) → 6. Drift tables → 7. OuraHealthSource → 8. Factory → 9. **Auth state provider** → 10. **OAuth flow** → 11. Settings UI (now has real providers to bind) → 12. Refresh button → 13. Platform OAuth config → 14. Integration test → 15. Verification.

---

## Task 1: Add Dependencies

**Files:**
- Modify: `pubspec.yaml`
- Modify: `pubspec.lock` (auto-updated)

- [ ] **Step 1: Add to pubspec.yaml**

```yaml
  flutter_secure_storage: ^9.0.0
  flutter_web_auth_2: ^3.1.0  # browser-based OAuth callback
```

- [ ] **Step 2: `flutter pub get`**

- [ ] **Step 3: Commit** — `chore: add flutter_secure_storage + flutter_web_auth_2`

---

## Task 2: Extend HealthMetrics with Oura Fields

**Files:** Modify `lib/data/sources/health_source.dart`

- [ ] **Step 1: Add Oura fields to HealthMetrics**

Add nullable fields: `sleepScore`, `lowestHeartRate`, `sleepInterruptions`, `activityScore`, `readinessScore`, `temperatureDeviation`, `averageHeartRate`, `averageHrv`. Add `DataSource source` and `DateTime? lastFetched` metadata. Add `isComplete()` (sleep or hrv from either source) and `isStale()` (>24h).

> See review notes: don't make `source` required without checking every constructor call site — `MergedHealthSource` and any test fakes need it too.

- [ ] **Step 2:** `flutter analyze lib/data/sources/health_source.dart`

- [ ] **Step 3: Commit** — `feat(health): extend HealthMetrics with Oura fields`

---

## Task 3: Create Oura Data Models

**Files:** Create `lib/data/models/oura_models.dart` + test.

Four request/response pairs: `OuraSleepData` (lowest_heart_rate, restless_periods, average_heart_rate, average_hrv), `OuraDailySleepData` (score), `OuraActivityData` (score), `OuraReadinessData` (score, temperature_deviation).

**Note on date fields:** Oura returns `day` as a `YYYY-MM-DD` string. Keep it as `String` in the model (do not parse to DateTime here — caller chooses how to interpret). Drift tables will normalise separately.

TDD: write failing test → implement → green → commit.

- [ ] Commit — `feat(data): add Oura response models with JSON parsing`

---

## Task 4: Create OuraAuthManager (with refresh)

**Files:** Create `lib/data/sources/oura_auth_manager.dart` + test.

> **Critical change from earlier draft:** `getValidAccessToken()` must actually refresh when expired. Storing only an opaque access token is not enough — store `accessToken`, `refreshToken`, and `expiresAt`, and refresh when within 60s of expiry.

API surface:

```dart
class OuraAuthManager {
  Future<void> initialize();              // load from secure storage
  bool get isAuthenticated;
  String? get userEmail;

  /// Persist a freshly-issued token bundle (called by the OAuth flow).
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required DateTime expiresAt,
    String? userEmail,
  });

  /// Returns a non-expired access token, refreshing if necessary.
  /// Throws [OuraAuthException] if no valid token can be produced.
  Future<String?> getValidAccessToken();

  Future<void> logout();
}
```

TDD: cover (a) starts unauthenticated, (b) round-trips a token bundle through secure storage, (c) returns null after logout, (d) refresh path is exercised when `expiresAt` is in the past (mock the http call that does the refresh — or make the refresh callback injectable).

- [ ] Commit — `feat(auth): add OuraAuthManager with token refresh`

---

## Task 5: Create OuraApiClient

**Files:** Create `lib/data/sources/oura_api_client.dart` + test.

> **Critical change from earlier draft:** the client must take a `Future<String?> Function() tokenProvider` callback instead of a static `accessToken` string. Otherwise providers can't pick up newly-issued tokens without rebuilding the client. (The previous implementation hardcoded `accessToken: ''` in `providers.dart` because of this.)

```dart
class OuraApiClient {
  OuraApiClient({
    required Future<String?> Function() tokenProvider,
    http.Client? httpClient,
  });
  Future<OuraSleepData> getSleep({required DateTime startDate, required DateTime endDate});
  Future<OuraDailySleepData> getDailySleep({...});
  Future<OuraActivityData> getActivity({...});
  Future<OuraReadinessData> getReadiness({...});
}
```

Each method: call `tokenProvider()`, attach `Authorization: Bearer ...`, GET, handle 200/401/429. Throw `OuraAuthException` on 401 (signals the caller to re-auth), `RateLimitException` on 429 with `retry-after`, generic `Exception` otherwise.

- [ ] Commit — `feat(api): add OuraApiClient with token callback + rate limit handling`

---

## Task 6: Drift Tables for Oura Data

**Files:** Create `lib/data/database/oura_tables.dart`, modify `lib/data/native_database.dart`, add test.

```dart
class OuraSleep extends Table {
  TextColumn get id => text()();
  DateTimeColumn get day => dateTime()();
  IntColumn get sleepScore => integer().nullable()();
  IntColumn get lowestHeartRate => integer().nullable()();
  IntColumn get restlessPeriods => integer().nullable()();
  IntColumn get averageHeartRate => integer().nullable()();
  IntColumn get averageHrv => integer().nullable()();
  DateTimeColumn get fetchedAt => dateTime()();
  @override
  Set<Column> get primaryKey => {id};
}
// OuraActivity, OuraReadiness similar
```

> **API correction:** use `integer().nullable()()` — not `intColumn().nullable()()`. (Earlier draft had the wrong factory.)

Register tables in `@DriftDatabase`, run `dart run build_runner build`, bump schemaVersion + add migration.

- [ ] Commit — `feat(db): add Drift tables for Oura sleep, activity, readiness data`

---

## Task 7: OuraHealthSource

**Files:** Create `lib/data/sources/oura_health_source.dart` + test.

Constructor takes `OuraAuthManager`, `OuraApiClient`, `NativeDatabase` (typed concretely — **do not cast `databaseProvider` to `QueryExecutor`** as the buggy version did). Fetches all four endpoints in parallel via `Future.wait`, picks latest day from each, merges into `HealthMetrics(source: DataSource.oura, lastFetched: now)`. Persists to Drift tables on success (cache-on-fetch).

On `OuraAuthException`: rethrow so the factory can fall back. On `RateLimitException`: read from Drift cache if available, else rethrow.

- [ ] Commit — `feat(health): add OuraHealthSource`

---

## Task 8: HealthSourceFactory with Preference + Fallback

**Files:** Create `lib/data/sources/health_source_factory.dart` (do **not** rename `merged_health_source.dart` — that's a different existing class wrapping HealthPackageSource + manual sleep). Modify `lib/state/settings_provider.dart`. Add test.

```dart
final healthSourcePreferenceProvider = StateNotifierProvider<...>(...);
enum HealthSourcePreference { oura, appleHealth }
```

Factory logic when `preferOura = true`:
1. Try `ouraHealthSource.recentMetrics()`.
2. If result is `!isStale()` → return it.
3. On stale, `OuraAuthException`, or any other failure → fall back to Apple Health.

When `preferOura = false`: skip Oura entirely.

Persist the preference (use existing `SettingsRepo` so it survives restarts).

- [ ] Commit — `refactor(health): add HealthSourceFactory with preference + fallback`

---

## Task 9: Auth State Provider (moved earlier — must exist before UI)

**Files:** Create `lib/state/oura_settings_provider.dart`.

```dart
final ouraAuthManagerProvider = Provider<OuraAuthManager>((ref) => OuraAuthManager());

// Token callback wired into the api client:
final ouraApiClientProvider = Provider<OuraApiClient>((ref) {
  final auth = ref.watch(ouraAuthManagerProvider);
  return OuraApiClient(tokenProvider: auth.getValidAccessToken);
});

final ouraHealthSourceProvider = Provider<HealthSource>((ref) => OuraHealthSource(
  authManager: ref.watch(ouraAuthManagerProvider),
  apiClient: ref.watch(ouraApiClientProvider),
  database: ref.watch(databaseProvider),  // typed NativeDatabase, no cast
));

final ouraAuthStateProvider = StateNotifierProvider<OuraAuthStateNotifier, bool>(...);
final ouraUserEmailProvider = Provider<String?>(...);
```

`OuraAuthStateNotifier` exposes `logout()`, `setAuthenticated(...)`, and calls `manager.initialize()` on construction.

- [ ] Commit — `feat(state): add Oura auth providers`

---

## Task 10: OAuth Flow (NEW — was missing from original plan)

**Files:** Create `lib/data/sources/oura_oauth_flow.dart` + test.

This is the load-bearing piece the original plan dropped on the floor. Without it the Connect button can't actually do anything.

```dart
class OuraOAuthFlow {
  OuraOAuthFlow({required this.clientId, required this.redirectUri, required this.authManager});

  /// Launches browser → user grants → callback URL → exchange code for tokens.
  Future<void> connect();
}
```

Implementation steps:
1. Build authorize URL with `client_id`, `redirect_uri`, `response_type=code`, `scope=email personal daily heartrate spo2 ring_configuration session sleep tag workout`, `state=<random>`.
2. `flutter_web_auth_2.authenticate(url: ..., callbackUrlScheme: 'com.migraine-forecast')` — returns the redirect URL with `?code=...&state=...`.
3. Validate `state` matches.
4. POST `https://api.ouraring.com/oauth/token` with `grant_type=authorization_code`, `code`, `client_id`, `client_secret`, `redirect_uri`.
5. Parse `{access_token, refresh_token, expires_in}` → call `authManager.saveTokens(...)`.
6. Optionally GET `/v2/usercollection/personal_info` to populate `userEmail`.

Add a provider: `final ouraOAuthFlowProvider = Provider<OuraOAuthFlow>(...)`.

> **Secrets:** `client_id` / `client_secret` belong in `--dart-define` build args, not source. Document in README.

TDD focus: state-mismatch rejection, token-exchange parsing, error paths (user cancellation, network failure).

- [ ] Commit — `feat(auth): add OuraOAuthFlow for browser-based authorization`

---

## Task 11: Oura Settings UI (now wired to real providers)

**Files:** Create `lib/ui/settings/oura_settings_card.dart`, modify `lib/ui/settings/settings_screen.dart`.

> **Do not** use placeholder `const isAuthenticated = false;` — that was the bug. Bind to `ouraAuthStateProvider` directly.

```dart
class OuraSettingsCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthenticated = ref.watch(ouraAuthStateProvider);
    final userEmail = ref.watch(ouraUserEmailProvider);
    final preference = ref.watch(healthSourcePreferenceProvider);
    // Connect → ref.read(ouraOAuthFlowProvider).connect()
    // Disconnect → ref.read(ouraAuthStateProvider.notifier).logout()
    // Radio buttons → setPreference(...)
  }
}
```

Use `RadioGroup` ancestor (the new API) rather than deprecated `RadioListTile.groupValue` / `onChanged`.

- [ ] Commit — `feat(ui): add Oura settings card wired to OAuth + preference providers`

---

## Task 12: Health Metrics Refresh Button

**Files:** Modify `lib/ui/common/health_metrics_card.dart`, add `healthMetricsRefreshingProvider` to settings.

`IconButton(Icons.refresh)` → invalidates `healthMetricsProvider`. Show `CircularProgressIndicator(strokeWidth: 2)` in a 24×24 box while refreshing. Display `'Updated <relative> from <source>'` under metrics.

- [ ] Commit — `feat(ui): add refresh button to health metrics card`

---

## Task 13: Platform OAuth Configuration

**Files:** `ios/Runner/Info.plist`, `android/app/src/main/AndroidManifest.xml`.

Register `com.migraine-forecast` as the callback scheme so `flutter_web_auth_2` can intercept the redirect.

- iOS: add to `CFBundleURLTypes`.
- Android: add `<intent-filter>` with `<data android:scheme="com.migraine-forecast" />` to `MainActivity`.

- [ ] Commit — `config: register Oura OAuth callback URL scheme`

---

## Task 14: Integration Test for Full Flow (rewritten — was vacuous)

**Files:** Create `test/data/integration/oura_integration_test.dart`.

> The earlier integration test asserted only `factory.preferOura == true` — it didn't exercise anything. Replace with a real flow:

```dart
test('OAuth → AuthManager → ApiClient → HealthSource → Factory', () async {
  // 1. Mock secure storage starts empty.
  // 2. Simulate OAuth completion: authManager.saveTokens(access, refresh, expiry).
  // 3. Mock http client to return canned JSON for all 4 endpoints when called with Bearer <access>.
  // 4. Verify factory.recentMetrics() returns DataSource.oura with expected sleepScore/lowestHeartRate.
  // 5. Verify the http client was called with the access token from secure storage.
});

test('factory falls back to Apple Health when Oura returns 401', () async {
  // 1. authManager has a stored token that the mocked http client will reject (401).
  // 2. Mocked Apple Health returns sleep=480.
  // 3. factory.recentMetrics() → DataSource.appleHealth, sleep=480.
});

test('factory falls back when Oura data is stale (lastFetched > 24h)', () async {
  // ...
});
```

Use `MockHttpClient` (mocktail) and `MockSecureStorage` — real component wiring otherwise.

- [ ] Commit — `test: real end-to-end integration test for Oura flow`

---

## Task 15: Verification

- [ ] `flutter test` — all green.
- [ ] `flutter analyze` — no new warnings vs. main. **Specifically check for `dead_code` warnings in `oura_settings_card.dart`** — if present, the card is still using the placeholder `isAuthenticated = false` pattern and Task 11 is incomplete.
- [ ] Manual smoke test on a real device with valid `OURA_CLIENT_ID`/`OURA_CLIENT_SECRET` `--dart-define`s: Settings → Connect → browser opens → Oura login → returns to app → Connect becomes Disconnect → user email shown → metrics card shows Oura data.
- [ ] `git log --oneline` — 14 commits on the branch, in the order above.

---

## Success Criteria

✅ All 14 implementation tasks committed in dependency order
✅ Unit tests for: models, auth manager (incl. refresh), api client (incl. 401/429), health source, factory, OAuth flow
✅ Integration test exercises the *real* path: stored token → API call → parsed metrics → factory selection
✅ Settings card is bound to real providers — no `const isAuthenticated = false` placeholders, no TODO snackbars
✅ `OuraApiClient` receives tokens via callback — providers do not pass an empty string
✅ Factory falls back to Apple Health on Oura auth failure, rate limit, or staleness
✅ Token refresh works (verified by test that advances `expiresAt` into the past)
✅ `flutter analyze` clean of new warnings; no `dead_code` warnings introduced

---

## What changed from the previous draft

This plan is a rewrite of an earlier version that was implemented and produced these defects:

1. **Settings card built before its providers existed** → shipped with hardcoded `const isAuthenticated = false;` and `[TODO]` snackbars. **Fix:** auth providers (Task 9) now come before the UI (Task 11).
2. **No OAuth flow task at all** → Connect button literally did nothing. **Fix:** dedicated Task 10 with `flutter_web_auth_2` and token exchange.
3. **`OuraApiClient(accessToken: '')` in providers** → all API calls would 401. **Fix:** client takes `tokenProvider` callback; provider wires it to `authManager.getValidAccessToken`.
4. **`getValidAccessToken()` didn't actually refresh** → users would get silently logged out after token expiry. **Fix:** auth manager stores expiry + refresh token and refreshes proactively.
5. **`database: ref.watch(databaseProvider) as QueryExecutor`** with field typed `NativeDatabase` → type-unsafe cast. **Fix:** Task 7 specifies concrete `NativeDatabase` typing throughout.
6. **Plan said "rename merged_health_source.dart"** but that file holds a different existing class. **Fix:** Task 8 creates a new `health_source_factory.dart`.
7. **Drift API typo (`intColumn()`)** → wouldn't compile if followed literally. **Fix:** Task 6 uses `integer().nullable()()`.
8. **Integration test asserted `factory.preferOura == true` and nothing else.** **Fix:** Task 14 specifies three real scenarios with mocked HTTP + storage but live component wiring.
