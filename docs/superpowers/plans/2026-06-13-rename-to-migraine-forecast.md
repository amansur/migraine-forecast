# Plan: Rename project `migraine-weatherr` → `migraine-forecast`

## Context

The project is currently named `migraine-weatherr` (typo, double "r"). We want to rename to `migraine-forecast` across the local repo, the Dart package, and the iOS/Android/macOS/web platform shells. Display name in UI becomes **"Migraine Forecast"**.

**Out of scope** (explicitly excluded per user):

- GitHub remote rename (none configured: `git remote -v` is empty).
- Renaming the Dart `domain` sub-package (`packages/domain/pubspec.yaml` is already just `name: domain`).

**Critical risks to handle inside this plan:**

1. **SQLite database file name** — `lib/data/database.dart:131` opens a drift DB named `migraine_weatherr`. Changing it on existing installs would orphan user data (attacks, baselines, settings). Plan keeps the on-disk DB name unchanged and only renames code identifiers.
2. **App ID change is a hard break for existing installs.** Changing `applicationId` (Android) and `PRODUCT_BUNDLE_IDENTIFIER` (iOS) means the OS treats the new build as a fresh, distinct app. The dev install will need to be uninstalled. Acceptable pre-launch but call it out.
3. **iOS BGTaskScheduler identifiers** in `ios/Runner/Info.plist` (`com.migraineweatherr.morning_refresh`, `com.migraineweatherr.evening_refresh`) must change in lockstep with the Dart-side registration in `lib/services/background_scheduler.dart` (or wherever they're registered) — mismatches silently break background refresh.
4. **Open git worktrees.** `.claude/worktrees/grafted` and `.claude/worktrees/piped-orbiting-kettle` are checked-out worktrees of this repo. Renaming the repo root invalidates the `gitdir:` pointers inside each worktree. Plan removes them before the directory rename and recreates only if needed.

## Naming conventions

| Surface | Old | New |
|---|---|---|
| Repo dir | `migraine-weatherr` | `migraine-forecast` |
| Dart package | `migraine_weatherr` | `migraine_forecast` |
| Dart imports | `package:migraine_weatherr/...` | `package:migraine_forecast/...` |
| Android namespace + applicationId | `com.migraineweatherr.migraine_weatherr` | `com.migraineforecast.migraine_forecast` |
| Android Kotlin package dir | `android/app/src/main/kotlin/com/migraineweatherr/migraine_weatherr/` | `android/app/src/main/kotlin/com/migraineforecast/migraine_forecast/` |
| iOS bundle ID | `com.migraineweatherr.migraineWeatherr` | `com.migraineforecast.migraineForecast` |
| iOS BG task IDs | `com.migraineweatherr.*_refresh` | `com.migraineforecast.*_refresh` |
| macOS PRODUCT_NAME / bundle ID | `migraine_weatherr` / `com.migraineweatherr.migraineWeatherr` | `migraine_forecast` / `com.migraineforecast.migraineForecast` |
| Display name (iOS `CFBundleDisplayName`, Android `android:label`, web `name`) | `Migraine Weatherr` / `migraine_weatherr` | `Migraine Forecast` |
| Drift sqlite DB file (`lib/data/database.dart:131`) | `migraine_weatherr` | **unchanged** — preserves existing user data |

## Changes

Group changes into ordered phases so the working tree compiles after each phase.

### Phase 0 — Pre-flight (manual, before edits)

- Commit/stash any in-flight changes on `feature/ui-insights-button` (git status currently shows three modified files).
- `git worktree remove .claude/worktrees/grafted && git worktree remove .claude/worktrees/piped-orbiting-kettle` (the user can recreate later if still needed). Confirm with `git worktree list`.
- Quit any IDE / `flutter run` / simulator instance pinned to the old paths.

### Phase 1 — Dart package rename (in repo root, **before** directory rename)

1. `pubspec.yaml`: `name: migraine_weatherr` → `migraine_forecast`. Update `description` if it mentions the name.
2. Bulk-replace Dart imports: `package:migraine_weatherr/` → `package:migraine_forecast/` across `lib/`, `test/`, `integration_test/` (if present), and `packages/domain/` (only if the domain package imports back into the app — verify; likely no).
3. Display strings inside Dart code (only the user-visible ones):
   - `lib/app/app.dart:45` — `title: 'Migraine Weatherr'` → `'Migraine Forecast'`
   - `lib/ui/onboarding/onboarding_screen.dart:35` — AppBar title → `'Welcome to Migraine Forecast'`
   - `lib/ui/onboarding/onboarding_screen.dart:108` — disclaimer copy
   - `lib/app/theme.dart:3` — comment ("Migraine Weatherr brand colors…")
4. **Do not change** `lib/data/database.dart:131` — drift DB name stays `migraine_weatherr`. Add a one-line comment explaining why (renaming would orphan installed-user data).
5. Run `flutter pub get` and `flutter analyze` to confirm package import rewrites are complete.

### Phase 2 — Platform shell renames

**Android** (`android/app/build.gradle.kts`, `AndroidManifest.xml`, Kotlin sources):

- `namespace` and `applicationId` → `com.migraineforecast.migraine_forecast`.
- `android:label` in `AndroidManifest.xml:9` → `Migraine Forecast`.
- Move Kotlin source dir: `android/app/src/main/kotlin/com/migraineweatherr/migraine_weatherr/` → `.../com/migraineforecast/migraine_forecast/`. Delete the now-empty `migraineweatherr/` parent.
- Update `MainActivity.kt` package declaration to match.

**iOS** (`ios/Runner/Info.plist`, `ios/Runner.xcodeproj/project.pbxproj`):

- `CFBundleDisplayName` → `Migraine Forecast`.
- `CFBundleName` → `migraine_forecast`.
- `NSLocationWhenInUseUsageDescription` / `NSLocationAlwaysAndWhenInUseUsageDescription` strings — replace "Migraine Weatherr" with "Migraine Forecast".
- BGTaskScheduler identifiers under `BGTaskSchedulerPermittedIdentifiers`: `com.migraineweatherr.morning_refresh` → `com.migraineforecast.morning_refresh` (same for `evening_refresh`).
- `project.pbxproj` (6 occurrences): `PRODUCT_BUNDLE_IDENTIFIER = com.migraineweatherr.migraineWeatherr` → `com.migraineforecast.migraineForecast`, and `*.RunnerTests` variants the same way.

**Verify and update the Dart side of the BG IDs.** Grep `migraineweatherr` under `lib/services/` — wherever the morning/evening identifiers are referenced in code, update them to the new `com.migraineforecast.*` strings in the same commit. If the IDs don't match Info.plist exactly, iOS silently refuses to schedule the task.

**macOS** (`macos/Runner/Configs/AppInfo.xcconfig`, `macos/Runner/Info.plist`):

- `PRODUCT_NAME` → `migraine_forecast`.
- `PRODUCT_BUNDLE_IDENTIFIER` → `com.migraineforecast.migraineForecast`.
- `PRODUCT_COPYRIGHT` → update org string.
- Location usage strings in `macos/Runner/Info.plist` (lines 32 & 34).

**Web** (`web/index.html`, `web/manifest.json`):

- `manifest.json` `name` and `short_name` → `Migraine Forecast`.
- `index.html` `apple-mobile-web-app-title` and `<title>` → `Migraine Forecast`.

### Phase 3 — Docs & meta

- `README.md`: title and any prose mentions.
- `GEMINI.md`: title.
- `docs/superpowers/specs/2026-06-10-migraine-weatherr-design.md`: rename file to `…-migraine-forecast-design.md` and update its content title. Leave older handoff/plan docs as historical record — they reference the project by its old name on purpose. Add a one-line note at the top of `README.md` recording the rename date.
- `.claude/settings.local.json`: replace name references.

### Phase 4 — Directory rename + reattach

Last, with the repo clean and committed on a `chore/rename-to-migraine-forecast` branch:

1. From `/Users/amansur/projects/`: `mv migraine-weatherr migraine-forecast`.
2. Update the persistent feedback memory at `~/.claude/projects/-Users-amansur-projects-migraine-weatherr/memory/feedback_work_in_main_repo.md` so the recorded canonical path is the new one. (User runs the project from this path; stale memory will mislead future sessions.) Move/rename the parent memory directory itself if its path encodes the old name.
3. Run `flutter clean && flutter pub get` from the new path.

## Files touched (representative)

Single bulk-rewrite passes cover most of this. Representative paths:

- `pubspec.yaml`, `lib/**/*.dart`, `test/**/*.dart` (Dart package & imports & display strings)
- `android/app/build.gradle.kts`, `android/app/src/main/AndroidManifest.xml`, `android/app/src/main/kotlin/...` (Android shell, plus directory move)
- `ios/Runner/Info.plist`, `ios/Runner.xcodeproj/project.pbxproj` (iOS shell + BG task IDs)
- `macos/Runner/Configs/AppInfo.xcconfig`, `macos/Runner/Info.plist` (macOS shell)
- `web/index.html`, `web/manifest.json` (web shell)
- `README.md`, `GEMINI.md`, `docs/superpowers/specs/...` (docs)
- `lib/data/database.dart` — **comment only**, DB name unchanged

## Verification

1. `flutter clean && flutter pub get` from the new repo path — clean resolve.
2. `flutter analyze` — zero errors.
3. `flutter test` — full unit + widget suite passes (catches any missed `package:migraine_weatherr/...` import).
4. `cd packages/domain && dart test` — domain suite passes.
5. **Android**: `flutter run -d android`. Uninstall any prior `com.migraineweatherr.*` app first (different applicationId = different app). App label on launcher reads "Migraine Forecast". Onboarding AppBar reads "Welcome to Migraine Forecast".
6. **iOS**: `flutter run -d ios`. Same — uninstall the old build. Background refresh: confirm `BGTaskScheduler` registration logs no "Unrecognized task identifier" warnings (search Xcode console for the BG task IDs).
7. **Sanity grep**: `git grep -i 'migraine[_-]\?weatherr'` returns only intentional matches — the DB name in `lib/data/database.dart`, the explanatory comment, and historical docs under `docs/handoff/` and `docs/superpowers/plans/`. Anything else is a miss.

## Notes / open questions

- The drift DB file kept its old name to preserve user data. If you ever decide to rename it too, that needs a one-shot migration that copies `migraine_weatherr.sqlite` → `migraine_forecast.sqlite` on first launch, then deletes the old.
- If a GitHub remote gets added later, the local-side rename here leaves you free to pick any remote repo name — nothing in code depends on it.
