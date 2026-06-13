# Handoff: Fix three review findings from exports/intraday/comfort PR

## Context
We just landed three independent slices from `docs/superpowers/plans/2026-06-13-exports-intraday-comfort.md` via three parallel Sonnet subagents:
1. JSON Data Export (`ExportRepo` + settings dialog)
2. Intraday Pressure Swing trigger module
3. Comfort Mode photophobia theme

All work is uncommitted on `main` in `/Users/amansur/projects/migraine-forecast`. Tests pass (`dart test` in `packages/domain`, `flutter test` at repo root). A code review surfaced three issues to fix before commit. Your job is to fix them and re-run tests.

Do NOT commit. Leave the work uncommitted so the user can review.

## The three fixes

### 1. ScaffoldMessenger-after-pop bug (real bug, snackbar silently fails)
**File:** `lib/ui/settings/settings_screen.dart`
**Methods:** `_ExportDataDialogState._copyToClipboard` (around line 532) and `_saveToDocuments` (around line 548).

Both currently do:
```dart
Navigator.pop(context);
ScaffoldMessenger.of(context).showSnackBar(...);
```
After `Navigator.pop`, the dialog's `context` is unmounted; `ScaffoldMessenger.of(context)` walks a detached ancestor chain and the snackbar will not show (or throws in debug). Fix by capturing the messenger before pop:
```dart
final messenger = ScaffoldMessenger.of(context);
Navigator.pop(context);
messenger.showSnackBar(...);
```
Apply to both methods. Preserve `mounted` checks.

### 2. Redundant `AnimatedTheme` wrapper
**File:** `lib/app/app.dart`
**Around line 49:** `AnimatedTheme` wraps `MaterialApp.router` and passes the same theme as `MaterialApp`'s `theme`/`darkTheme`. `MaterialApp` maintains its own internal `AnimatedTheme` keyed off those props and overrides any inherited `Theme` from above, so the outer `AnimatedTheme` is a no-op.

**Fix:** Delete the outer `AnimatedTheme` and return `MaterialApp.router` directly. `MaterialApp`'s internal theme animation (default 200ms) will handle the transition. If the user later asks for a longer transition, the right place is `MaterialApp.themeAnimationDuration`.

### 3. Dead code in intraday module
**File:** `packages/domain/lib/src/modules/intraday_pressure_swing.dart`
**Around line 49:** the `if (volatility <= 0)` branch is unreachable — `WeatherSeries.hourlyPressureVolatilityAround` sums absolute differences, so it returns `null` or a non-negative double, and the `null` case is already handled above. Delete the branch.

## Verification
After applying the fixes, run from repo root:
```bash
(cd packages/domain && dart test) && flutter test
```
Both must pass. Then run `git diff --stat` and report what changed.

## Reference material (don't re-read unless needed)
- Plan: `docs/superpowers/plans/2026-06-13-exports-intraday-comfort.md`
- Current uncommitted diff: `git diff` from repo root
- Three new files (untracked): `lib/data/repos/export_repo.dart`, `packages/domain/lib/src/modules/intraday_pressure_swing.dart`, plus the two test files under `test/` and `packages/domain/test/`.

## Repo conventions
- Main repo path: `/Users/amansur/projects/migraine-forecast` (renamed from `migraine-weatherr`; work in the main repo, NOT any worktree).
- No emojis in code or comments.
- Minimal comments — only when the WHY is non-obvious.
- Drift database at `lib/data/database.dart`, schemaVersion = 4 (do NOT touch — schema migrations are out of scope here).

## What to report back
Under 150 words:
1. The three diffs applied (file:line).
2. Test command exit status.
3. Any surprises (e.g., the `mounted` check interacting with the messenger capture).

## Suggested skills
- `superpowers:verification-before-completion` — run the test commands and confirm output before claiming done.
- `superpowers:systematic-debugging` — only if a fix unexpectedly fails a test.
