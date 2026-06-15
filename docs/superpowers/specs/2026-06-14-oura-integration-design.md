# Oura Ring Integration Design

**Date:** 2026-06-14  
**Status:** Design approved, ready for implementation  
**Scope:** Full Oura Ring integration with comprehensive health metrics

## Overview

This design adds **Oura Ring** as a second health data source for migraine-forecast, complementing the existing Apple Health / Health Connect integration. Users can authenticate with their Oura account via OAuth, and the app will:

1. Pull all available Oura metrics (sleep score, lowest heart rate, sleep interruptions, activity score, readiness score, temperature deviation)
2. Store Oura data locally in the existing Drift database
3. Let users choose which source to prioritize (Oura or Apple Health)
4. Fall back to Apple Health if Oura data is missing or stale
5. Sync data in real-time (on app open + every 4 hours) and on-demand (via refresh button)

**Key principle:** Treat Oura as a complete alternative to Apple Health, not a supplement. Users can prefer Oura, and the system intelligently falls back to Apple Health for missing metrics.

---

## Architecture

```
┌─────────────────────────────────────────────────────┐
│ Settings: "Data source preference" (Oura / Apple)   │
└────────────┬────────────────────────────────────────┘
             │
             ├─→ HealthSourceFactory (refactored)
             │   Decides source priority
             │
             ├─→ OuraHealthSource (new)
             │   ├─ OuraAuthManager: OAuth + token management
             │   ├─ OuraApiClient: API calls to Oura
             │   └─ Maps Oura JSON → HealthMetrics
             │
             └─→ ExistingHealthSource (Apple Health / Health Connect)
                 Fallback if Oura is missing/stale
```

### Data Flow

```
App Open / Refresh Button
    ↓
HealthSourceFactory.recentMetrics(window)
    ├─ Check user setting: "Prefer Oura"?
    │
    ├─ If Oura preferred:
    │   ├─ Try OuraHealthSource.recentMetrics()
    │   ├─ If Oura data exists & fresh: return it
    │   └─ Else: fall back to ExistingHealthSource
    │
    └─ If Apple Health preferred:
        └─ Use ExistingHealthSource
        
Background Sync (every 4 hours via workmanager)
    ↓
OuraHealthSource.syncLatestData() [if Oura preferred]
    ├─ Fetch from Oura API
    ├─ Store in Drift database
    └─ Update last_synced timestamp
```

---

## Components

### 1. OuraAuthManager

**Purpose:** Handle OAuth 2.0 authentication with Oura.

**Responsibilities:**
- Launch OAuth browser flow (`startOAuthFlow()`)
- Capture redirect URI and authorization code
- Exchange code for access token + refresh token
- Store tokens securely using `flutter_secure_storage`
- Auto-refresh tokens when expired
- Clear tokens on logout
- Expose `isAuthenticated` and `getCurrentUser()` checks

**Key Methods:**
```dart
class OuraAuthManager {
  Future<void> startOAuthFlow();
  Future<String> getValidAccessToken();  // Refresh if needed
  Future<void> logout();
  bool get isAuthenticated;
  String? get userEmail;
}
```

**Storage:** Tokens stored in platform keychain/keystore via `flutter_secure_storage`. Not accessible to other apps.

**Error Handling:**
- Token refresh failure → prompt user to re-authenticate
- Invalid OAuth callback → show error dialog
- Network errors during auth → retry with exponential backoff

---

### 2. OuraApiClient

**Purpose:** Low-level HTTP client for Oura API calls.

**Responsibilities:**
- Wrap all Oura API endpoints
- Handle authentication headers (Bearer token)
- Parse JSON responses into domain models
- Implement rate limit handling (429 responses)
- Cache responses to avoid redundant API calls

**Key Methods:**
```dart
class OuraApiClient {
  Future<SleepData> getSleep(DateRange range);
  Future<DailySleepData> getDailySleep(DateRange range);
  Future<DailyActivityData> getDailyActivity(DateRange range);
  Future<DailyReadinessData> getDailyReadiness(DateRange range);
  Future<DailyStressData> getDailyStress(DateRange range);
}
```

**Rate Limiting:**
- Check `X-RateLimit-Remaining` header after each request
- If approaching limit, pause syncing and wait for `Retry-After`
- Log warnings when approaching rate limit

**Caching:**
- Cache API responses for 2 hours to avoid re-fetching same day
- Clear cache on manual refresh or after 4-hour sync window

---

### 3. OuraHealthSource

**Purpose:** Implement the `HealthSource` interface using Oura data.

**Responsibilities:**
- Fetch Oura metrics for a given date range
- Map Oura fields → `HealthMetrics` structure
- Expose granted categories (sleep, HRV, menstrual not available from Oura)
- Handle missing data gracefully

**Implementation:**
```dart
class OuraHealthSource extends HealthSource {
  final OuraAuthManager authManager;
  final OuraApiClient apiClient;
  final OuraDatabase ouraDatabase;  // Local cache

  @override
  Future<HealthMetrics> recentMetrics({required Duration window}) async {
    // 1. Check if data exists locally and is fresh (<24h)
    // 2. If not, fetch from Oura API
    // 3. Parse and store in Drift
    // 4. Return HealthMetrics
  }

  @override
  Future<Set<HealthCategory>> requestPermissions(Set<HealthCategory> categories) async {
    // Oura returns: {sleep, hrv}
    // (menstrual cycle not available from Oura API)
  }

  @override
  Set<HealthCategory> get grantedCategories => {HealthCategory.sleep, HealthCategory.hrv};
}
```

**Field Mapping:**

| Oura Endpoint | Oura Field | HealthMetrics Field |
|---|---|---|
| `/daily_sleep` | `score` | `sleepScore` |
| `/sleep` | `lowest_heart_rate` | `lowestHeartRate` |
| `/sleep` | `restless_periods` | `sleepInterruptions` |
| `/daily_activity` | `score` | `activityScore` |
| `/daily_readiness` | `score` | `readinessScore` |
| `/daily_readiness` | `temperature_deviation` | `temperatureDeviation` |
| `/sleep` | `average_heart_rate` | `averageHeartRate` |
| `/sleep` | `average_hrv` | `averageHrv` |

---

### 4. HealthSourceFactory (Refactored)

**Purpose:** Decide which health source to use based on user preference and data availability.

**Current behavior:** Merges Apple Health + manual sleep data.

**New behavior:**
```dart
class HealthSourceFactory {
  Future<HealthMetrics> recentMetrics(Duration window) async {
    final preference = settings.healthSourcePreference;  // 'oura' or 'appleHealth'
    
    if (preference == 'oura') {
      final ouraData = await ouraSource.recentMetrics(window: window);
      if (ouraData.isComplete()) {
        return ouraData;
      }
      // Fall back to Apple Health if Oura is missing
      return appleHealthSource.recentMetrics(window: window);
    } else {
      // Use Apple Health as primary
      return appleHealthSource.recentMetrics(window: window);
    }
  }
}
```

**Data freshness logic:**
- If Oura data is older than 24 hours and Apple Health is available, prefer Apple Health
- Show data source + last-synced timestamp in UI

---

### 5. Oura Database Schema (Drift)

**New tables:**

```dart
@DataClassName('OuraSleepRecord')
class OuraSleep extends Table {
  TextColumn get id => text()();
  DateTimeColumn get day => dateTime()();
  IntColumn get sleepScore => intColumn().nullable()();
  IntColumn get lowestHeartRate => intColumn().nullable()();
  IntColumn get restlessPeriods => intColumn().nullable()();
  IntColumn get averageHeartRate => intColumn().nullable()();
  IntColumn get averageHrv => intColumn().nullable()();
  DateTimeColumn get fetchedAt => dateTime()();
  
  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('OuraActivityRecord')
class OuraActivity extends Table {
  TextColumn get id => text()();
  DateTimeColumn get day => dateTime()();
  IntColumn get activityScore => intColumn().nullable()();
  DateTimeColumn get fetchedAt => dateTime()();
  
  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('OuraReadinessRecord')
class OuraReadiness extends Table {
  TextColumn get id => text()();
  DateTimeColumn get day => dateTime()();
  IntColumn get readinessScore => intColumn().nullable()();
  RealColumn get temperatureDeviation => real().nullable()();
  DateTimeColumn get fetchedAt => dateTime()();
  
  @override
  Set<Column> get primaryKey => {id};
}
```

---

## HealthMetrics Extension

```dart
class HealthMetrics {
  // Existing fields
  final double? sleep;              // Apple Health: duration in minutes
  final double? hrv;                // Apple Health: HRV in ms
  final double? menstrual;          // Apple Health: cycle phase
  
  // New Oura fields
  final int? sleepScore;            // Oura sleep score (0-100)
  final int? lowestHeartRate;       // Oura lowest HR during sleep (bpm)
  final int? sleepInterruptions;    // Oura restless periods (count)
  final int? activityScore;         // Oura activity score (0-100)
  final int? readinessScore;        // Oura readiness score (0-100)
  final double? temperatureDeviation; // Oura temp deviation (°C)
  final double? averageHeartRate;   // Oura average HR during sleep
  final int? averageHrv;            // Oura average HRV
  
  // Metadata
  final DataSource source;          // enum: oura, appleHealth, healthConnect, manual
  final DateTime? lastFetched;
  
  bool isComplete() {
    // True if critical metrics (sleep or hrv) are present
  }
}

enum DataSource { oura, appleHealth, healthConnect, manual }
```

---

## UI Changes

### Settings Screen

**New Section: "Health Data Sources"**

```
┌─────────────────────────────────┐
│ Health Data Sources             │
├─────────────────────────────────┤
│                                 │
│ Connected Accounts              │
│ ─────────────────────────────   │
│ ☑ Oura Ring                     │
│   Connected as user@email.com   │
│   [Disconnect]                  │
│                                 │
│ ☐ Apple Health                  │
│   [Request Permission]          │
│                                 │
│ Data Source Preference          │
│ ─────────────────────────────   │
│ ◉ Oura Ring                     │
│ ○ Apple Health                  │
│   (Only available if Oura       │
│    fails to fetch data)         │
│                                 │
│ [Connect Oura]  (if not auth'd) │
└─────────────────────────────────┘
```

**Actions:**
- "Connect Oura" button → launches OAuth flow
- "Disconnect" → clears OAuth token, removes Oura preference
- Radio buttons for source preference (only if Oura is connected)
- Shows last sync timestamp per source

### Dashboard / Today Screen

**Health Data Card Enhancement:**

```
┌─────────────────────────────────┐
│ Health Metrics                  │
├─────────────────────────────────┤
│ Sleep:  7.5 hrs | Score: 82/100│
│ HRV:    45 ms   | Low RHR: 48 bpm
│ Activity: 85/100 | Readiness: 78/100
│                                 │
│ Updated 2 hours ago from Oura   │
│              [Refresh Data]      │
└─────────────────────────────────┘
```

**Refresh Button:**
- Shows loading spinner during sync
- Updates timestamp on success
- Shows error toast on failure (with retry)

---

## Sync Strategy

### Real-time Sync

**On App Open:**
1. Check if Oura is preferred and authenticated
2. If yes, call `OuraHealthSource.recentMetrics()` (with cache check)
3. If data is >2 hours old, fetch fresh data from API

**Every 4 Hours (Background):**
1. Use existing `workmanager` to schedule periodic sync
2. Add new task: `SyncOuraDataTask`
3. Only sync if Oura is preferred and app has been backgrounded

**Network State Changes:**
- Optional: Listen to connectivity changes and re-sync when network reconnects

### On-demand Sync

**User taps "Refresh Data":**
1. Bypass cache, fetch fresh from Oura API
2. Show loading spinner for 2-5 seconds
3. Update timestamp and UI on success
4. Show error toast with retry on failure

---

## Error Handling

| Scenario | Behavior |
|----------|----------|
| **Oura API offline** | Show warning "Health data unavailable"; fall back to Apple Health if available |
| **OAuth token expired** | Auto-refresh; if refresh fails, show "Reconnect Oura" prompt |
| **Rate limit (429)** | Wait for `Retry-After` header; retry automatically in background |
| **Oura Ring not synced (no data)** | Fall back to Apple Health or show "No recent Oura data" |
| **Network timeout** | Retry with exponential backoff; use cached data if available |
| **User revokes Oura consent** | Clear token; show "Reconnect Oura" in settings |
| **Both sources missing data** | Show warning: "No recent health data available" |
| **Invalid/malformed Oura response** | Log error; skip that day; continue syncing other days |

---

## Testing Strategy

### Unit Tests

- **OuraAuthManager:** Mock OAuth flow, token refresh, expiration logic
- **OuraApiClient:** Mock HTTP responses, rate limit handling, JSON parsing
- **OuraHealthSource:** Mock OuraApiClient, verify field mapping, cache logic
- **HealthSourceFactory:** Mock both sources, verify preference logic and fallback

### Integration Tests

- OAuth flow end-to-end (with real Oura sandbox if available)
- Drift database: store and retrieve Oura records
- Real API calls (optional, using test credentials)

### UI Tests

- Settings screen: toggle preference, connect/disconnect Oura
- Dashboard: refresh button triggers sync, displays data source

### Golden Files

- Settings screen with Oura connected
- Settings screen without Oura
- Health metrics card showing Oura vs Apple Health data

---

## Implementation Phases

**Phase 1: Foundation**
- Create OuraAuthManager (OAuth flow + secure storage)
- Create OuraApiClient (API wrapper + caching)
- Add Drift tables for Oura data
- Extend HealthMetrics with new fields

**Phase 2: Integration**
- Create OuraHealthSource (implements HealthSource)
- Refactor HealthSourceFactory (preference + fallback logic)
- Wire up background sync task

**Phase 3: UI**
- Update Settings screen (connect/disconnect, preference radio)
- Add refresh button to Dashboard
- Show data source + timestamp in metrics card

**Phase 4: Polish**
- Error handling & edge cases
- Comprehensive tests (unit, integration, UI)
- Webhooks (optional future optimization)

---

## Rate Limits & Quotas

**Oura API rate limits:**
- Per-token: ~60 requests/hour
- Per-application: aggregate across all users

**Our usage (estimated):**
- Cold start (backfill): ~5 endpoints × 30 days = ~150 requests
- Daily sync: ~5 requests per day
- User refreshes: ~3 requests per user action

**Mitigation:**
- Cache responses for 2 hours
- Use webhooks (future) instead of polling
- Implement `Retry-After` header compliance
- Alert user if approaching rate limit

---

## Data Privacy & Security

- **Token storage:** `flutter_secure_storage` (platform keychain/keystore)
- **Data residency:** All Oura data stays on device (Drift database)
- **No PII transmitted:** Only send Oura API calls; no analytics of health metrics
- **OAuth scopes:** Request only necessary scopes (sleep, activity, readiness)
- **Logout:** Clearing token revokes API access; Drift data persists (user can delete manually)

---

## Future Enhancements

1. **Webhooks:** Replace polling with Oura webhooks (~30s latency) for real-time updates
2. **Historical backfill:** Let users import 1+ years of Oura data on first connect
3. **Garmin / Withings:** Extend `HealthSourceFactory` to support other wearables
4. **Trigger weights:** Learn which Oura metrics correlate best with migraines (via Insights)
5. **Sharing:** Export Oura-derived metrics to Apple Health (one-way sync)

---

## Success Criteria

- ✅ Users can authenticate with Oura via OAuth
- ✅ Sleep score, lowest RHR, sleep interruptions sync and display
- ✅ Activity score, readiness score, temperature deviation available
- ✅ Users can switch between Oura and Apple Health
- ✅ Real-time + on-demand sync working
- ✅ Fallback to Apple Health if Oura data missing
- ✅ No rate limit errors in normal usage
- ✅ All tests passing (unit, integration, UI)
- ✅ Settings and Dashboard UI updated
