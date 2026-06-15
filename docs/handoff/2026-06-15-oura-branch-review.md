# Handoff: Oura integration follow-ups

**Date:** 2026-06-15
**Repo:** `/Users/amansur/projects/migraine-forecast`
**Branch:** `feature/oura-integration` (24 commits ahead of `main`)
**User:** amansur@gmail.com

## Context

This branch adds Oura Ring as a first-class health data source alongside Apple Health. The work has been through five code reviews; the fifth review surfaced six findings that haven't been addressed yet. The user asked for a handoff so a fresh agent can pick those up.

**Architectural docs to read first:**
- `docs/superpowers/plans/2026-06-14-oura-integration.md` — the implementation plan (rewritten mid-branch; the appendix at the bottom lists the defects the rewrite was meant to prevent)
- `README.md` — has an "Oura Ring integration" section covering setup and the `--dart-define` keys

**Key source files (all under `lib/data/sources/`, `lib/data/`, `lib/state/`, `lib/ui/settings/`):**
- `oura_auth_manager.dart` — token lifecycle, secure storage, refresh
- `oura_api_client.dart` — HTTP wrapper, tokenProvider callback shape
- `oura_oauth_flow.dart` — browser handoff (`flutter_web_auth_2`)
- `oura_health_source.dart` — implements `HealthSource`, writes Drift cache, reads it on rate-limit/network failure
- `health_source_factory.dart` — picks between Oura and Apple Health per `HealthSourcePreference`, falls back on stale/error
- `oura_settings_provider.dart` — `OuraAuthState`, `ouraAuthStateProvider`, `ouraOAuthFlowProvider`
- `oura_settings_card.dart` — UI; ConsumerStatefulWidget with `_busy` flag for double-tap guard
- `database/oura_tables.dart` — Drift schema (v11 split daily sleep into its own table)
- `database.dart` — schema v11, migration includes guarded prefix-row migration (only runs `from == 10`)

## Working-tree state

Uncommitted at handoff time (post-review):

```
 M lib/data/database.dart          # migration guard fix for from < 10 → 11 jump
 M lib/data/native_database.dart   # rename helper for legacy db filename
 M lib/data/native_database_web.dart  # no-op rename for web
 M macos/Podfile                   # MACOSX_DEPLOYMENT_TARGET override
 M macos/Podfile.lock
```

These are recent fixes for runtime issues the user hit during testing. They should be committed before starting the review-finding work — they're already complete and tested by the user.

## Findings from the fifth review (the work to do)

Ordered by priority. The original review text lives only in the conversation, not on disk — summary below.

### 1. `.records.last` doesn't guarantee most-recent day — `oura_health_source.dart`

In `_buildFromApi` (lines ~111-114), all four `*Data` responses use `records.last` to get the "most recent" record. Oura's API doesn't document a stable ordering for these endpoints. The cache path (`_buildFromCache`) already sorts via Drift's `orderBy day DESC` — the bug is API-side only.

**Fix:** sort each `records` list by `day` descending and take `.first`.

### 2. `DateTime.parse(r.day)` uses local time, not UTC — `oura_health_source.dart`

Lines ~56, 68, 77, 86 (write path). Oura returns `day` as `YYYY-MM-DD`. `DateTime.parse('2026-06-13')` returns midnight in local time. Timezone shifts can flip which row is "most recent" and which `day` falls inside the `cutoff = now - window` filter in `recentOuraSleep` etc.

**Fix:** parse as UTC. Either `DateTime.utc(year, month, day)` or `DateTime.parse('${r.day}T00:00:00Z')`. Apply to all four write sites.

### 3. `averageHeartRate` loses precision through cache — `oura_health_source.dart` + `oura_tables.dart`

The model is `double` (`OuraSleepRecord.averageHeartRate`). The Drift column is `IntColumn`. Write path rounds (`r.averageHeartRate?.round()`), read path casts back to double. Live API: `52.5`. Cached: `53.0`. Same datapoint surfaces differently depending on which path the factory chose.

**Fix options:**
- (Cheapest) change column to `RealColumn` in `oura_tables.dart`, bump to schema v12 with column-type migration (SQLite needs rename-create-copy-drop dance, not direct ALTER COLUMN).
- Or accept rounding everywhere: stop casting back to double in `_buildFromCache`.

User asked to pick whichever is less awkward. Pick one and explain why in the commit.

### 4. Cache never evicts — `oura_health_source.dart`

`_buildFromCache` filters by `day` window but ignores `fetchedAt`. A row fetched 6 months ago, for a day still within a 30-day window, will be served indefinitely. No size bound either — successful fetches `upsert` by `id` but nothing ever deletes.

**Fix options:**
- Add a `DELETE FROM oura_* WHERE day < ?` step on each successful fetch, with `?` = `now - 90d` (or whatever cleanup horizon makes sense).
- Or filter `_buildFromCache` by `fetchedAt > now - Nd` to bound freshness.

For a migraine-tracking app, "data from 3 months ago" probably isn't useful. Lean toward eviction over indefinite retention.

### 5. Widget test name lies — `test/ui/settings/oura_settings_card_test.dart:119`

Test is named `"tapping Connect invokes connect() then refreshFromManager()"` but only asserts `connect()` was called. Either fix the assertion (capture the notifier and verify state mutated) or rename the test. One-line fix is fine; the agent who wrote it flagged this in their handoff notes when implementing.

### 6. `expiresIn` not validated for positive value — `oura_oauth_flow.dart`

A malicious or buggy server returning `expires_in: -1` creates a token immediately stale. Next `getValidAccessToken()` triggers refresh, which probably fails, which logs the user out. Annoying but not a security issue. A check (`expiresIn > 0`) is free.

## Other open follow-ups (lower priority, deferred)

These came from earlier reviews and were intentionally left for later:

- **`HealthSourcePreference` persistence** — `lib/state/settings_provider.dart` has a `TODO(oura)` comment. The notifier is in-memory only; app restart resets to `appleHealth`. Persisting requires moving the notifier to `AsyncValue<HealthSourcePreference>` because `SettingsRepo` is async — touches every call site in the UI. Larger refactor than the user wanted on this branch.
- **`OuraAuthStateNotifier._initialize()` race** — fire-and-forget Future in constructor. If user opens Settings and taps Connect within milliseconds of cold start, OAuth runs against a half-loaded manager. Fix would be to expose an `AsyncValue<OuraAuthState>` shape; touches the settings card.
- **Two longstanding flaky widget tests** — `test/widget_test.dart` and `test/app/app_smoke_test.dart` fail with "Timer is still pending" from Drift's `StreamQueryStore.markAsClosed` during `ProviderScope` teardown. User explicitly said these are pre-existing flakes, not branch-blockers. Leave alone.

## Constraints the user has been firm about

1. **Don't run `flutter test`, `flutter analyze`, or `flutter pub get` yourself.** User runs those manually and pastes failures. You can use Read/Edit/Write/Bash for git operations.
2. **Incremental, focused commits** — see the existing commit log on the branch for style. Use HEREDOC for messages, include `Co-Authored-By: Claude Haiku 4.5 <noreply@anthropic.com>` (this is the literal template the harness uses, even though the current model is Opus).
3. **Verify cross-agent changes after dispatch** — the user has been bitten by agents claiming work was done when only part landed. Spot-check key files after any agent run.

## Setup notes

- **`--dart-define` keys needed for OAuth to work:** `OURA_CLIENT_ID`, `OURA_CLIENT_SECRET`. Get from https://cloud.ouraring.com/oauth/applications. Redirect URI to register: `com.migraine-forecast://oauth/callback`. The `OuraOAuthFlow` constructor asserts both are non-empty in debug builds.
- **`dart run build_runner build`** is needed whenever Drift table definitions change. Drift's `database.g.dart` is committed.
- **Schema is at v11.** If you add a new migration step, bump to v12 and update `test/data/database_migration_test.dart`.

## Suggested skills

When picking up this work:

- **`superpowers:systematic-debugging`** — for the type-precision question (#3), where the right answer depends on understanding the full data flow from API → cache → UI.
- **`superpowers:test-driven-development`** — findings #1, #2, #6 each want a test added that fails first, then the fix. The integration test (`test/data/integration/oura_integration_test.dart`) is the right place for ordering and timezone cases.
- **`superpowers:verification-before-completion`** — before claiming a fix works, verify by reading the diff and running through the user's test command. The user has caught me claiming completeness prematurely.
- **`superpowers:dispatching-parallel-agents`** — findings #1, #2, #4, #5, #6 are independent. A single parallel dispatch could land all of them. #3 is more architectural — handle inline or as a focused single-agent task.
- **`cloudflare:cloudflare`** if any work later touches the deployment side, but not relevant to this branch.

## Commit log on branch (most recent first)

```
6891092 feat(db): persist Oura responses to Drift cache; split daily-sleep table
ba77484 ui(oura): disable Connect/Disconnect during OAuth; add widget test
5cc5f65 refactor(domain): inject clock into isStale; drop factory's duplicate
836643a fix(models): defensive numeric casts and missing-data detection
b9ce79e fix(oura): drop invalid 'sleep' scope from OAuth authorize request
f764fa6 chore(docs): move Oura OpenAPI spec out of repo root
c9bb50f fix(oura): derive callback scheme from redirectUri; assert secrets present
d691abc test: align migration + integration tests with new schema and APIs
27aa6d2 ui(settings): move Oura card to bottom; TODO persist source preference
d702f5d refactor(state): unify Oura auth+email into OuraAuthState; wire settings card
973f9eb feat(auth): add OuraOAuthFlow for browser-based authorization
7f0bda1 fix(providers): wire OuraApiClient to auth manager; drop bad cast
5c76b47 refactor(sources): drop unused database field + error-swallowing wrapper
a278907 refactor(api): take tokenProvider callback; fix daily_* endpoint paths
4ee7ac3 feat(auth): real token refresh, saveTokens, defensive init
4cf8a2a deps: add flutter_web_auth_2 for Oura OAuth browser handoff
41d0d8b docs(plan): rewrite Oura plan in dependency-correct order with OAuth task
b2b182e test: add Oura integration test for full authentication + metrics flow
36df183 feat(state): add OuraAuthStateNotifier provider for authentication state
4a49480 config: add Oura OAuth URL schemes for iOS and Android
3ee04bd feat(ui): add refresh button to health metrics card with loading indicator
01ead8a feat(ui): add Oura settings card to settings screen
7e62b16 feat(health-source): implement HealthSourceFactory with preference-based selection
51587fa feat(sources): implement OuraHealthSource for Oura Ring integration
fc18f0c feat(db): add Drift tables for Oura sleep, activity, readiness data
8fe0701 feat(api): add OuraApiClient for API calls with rate limit handling
3fc734b feat(auth): add OuraAuthManager for OAuth token storage
89a8a82 feat(data): add Oura response models with JSON parsing
0bb942d feat(health): extend HealthMetrics with Oura fields
1323428 chore: add flutter_secure_storage dependency
```

## First-move suggestion

1. Commit the four uncommitted runtime fixes (migration guard, DB rename helper, web stub, Podfile override) — they're complete, just unstaged.
2. Tackle finding #2 (UTC timezone parsing) first — silent data corruption is worse than the others and the fix is small.
3. Then bundle #1, #5, #6 as a single small commit (each is one-to-three lines).
4. #3 (precision) deserves its own thought and commit.
5. #4 (eviction) deserves its own design decision (delete on write vs filter on read).
