# Journal Logging: Alcohol, Caffeine, Hydration, Stress, Sleep

**Status:** Draft
**Date:** 2026-06-13

## Goal

Give users a way to log the four lifestyle trigger inputs that the domain engine
already consumes (`alcohol`, `caffeine`, `hydration`, `stress`) plus manual
`sleep` entries for users whose device does not grant OS health access. Entries
must be viewable, editable, and deletable.

## Non-goals

- Reminders or nudges to log.
- Trends, charts, weekly summaries.
- Importing alcohol/caffeine/hydration/stress from third-party apps.
- Manual override of sleep when the OS health source already provides it.

## Current state

- `packages/domain` already models `JournalEntry` with `JournalKind { alcohol,
  caffeine, hydration, stress }` and the corresponding trigger modules consume
  it via `EvaluationContext.recentJournal`.
- `JournalEntries` drift table exists (`kind`, `payloadJson`, `at`).
- `JournalSource` exposes `addEntry` and `recentEntries` only — no
  update/delete/watch.
- Sleep is sourced from `HealthSource` (HealthKit / Health Connect) as
  `SleepRecord` (with `totalSleep`, `sleepStart`, `efficiency`, `night`). The
  `sleep_deficit` module reads `health.recentSleep`. There is no manual sleep
  storage.
- `lib/ui/log/` contains only `log_attack_screen.dart`; nothing logs the four
  journal kinds today.

## User-facing design

### Entry point

Today screen gains a "Log" affordance (FAB-style action). Tapping opens a
bottom-sheet picker with one row per kind plus a "View history" link.

Sleep row visibility is gated: it appears only when
`HealthSource.grantedCategories` does not include `HealthCategory.sleep`.

### Per-kind add/edit sheet

A single `JournalEntrySheet` widget parameterised by kind. All sheets include a
time picker (defaults to "now", editable to any time within the last 7 days).

- **Alcohol** — integer stepper for standard drinks. Payload: `{units: int}`.
- **Caffeine** — preset chips: Coffee 95mg, Espresso 64mg, Tea 47mg, Energy
  80mg. "Other" chip reveals a numeric mg field. Payload: `{mg: int}`.
- **Hydration** — preset chips: Glass 250ml, Bottle 500ml, Liter 1000ml.
  Payload: `{liters: double}` (millilitres ÷ 1000).
- **Stress** — 1–5 chip selector. Payload: `{rating: int}`.
- **Sleep** — night date (defaults to last night), bedtime time picker, wake
  time picker. Derives `totalSleep` and `sleepStart`. Efficiency stays `null`.
  Cross-midnight bedtime resolves to the prior calendar day automatically.

Saving an existing entry calls `updateEntry`; creating calls `addEntry`. The
sheet shows a "Delete" affordance in edit mode.

### History screen

`LogHistoryScreen` shows the last 30 days of entries (journal + manual sleep),
grouped by day, newest first. Each row: icon, kind label, payload summary
(e.g., "2 drinks", "95 mg", "500 ml", "Stress 4/5", "7h 15m"), local time.

- Tap row → opens edit sheet for that entry.
- Swipe row → delete with an undo snackbar (5s).

## Architecture

### Domain package

- `JournalEntry` gains a nullable `id` field. The engine ignores it; the UI
  uses it as the stable identity for edit/delete. Existing constructors stay
  source-compatible (named parameter, default `null`).

### App data layer

- `JournalSource` adds:
  - `Future<void> updateEntry(JournalEntry entry)` (requires non-null `id`)
  - `Future<void> deleteEntry(int id)`
  - `Stream<List<JournalEntry>> watchRecentEntries(Duration window, {required DateTime now})`
- `DriftJournalSource` implements these against the existing `JournalEntries`
  table, exposing the drift row id as `JournalEntry.id`.
- New table `ManualSleepRecords`:
  - `night` (DateTime, PK — UTC midnight of the night the sleep belongs to)
  - `sleepStart` (DateTime)
  - `totalSleepMinutes` (int)
  - `efficiency` (real, nullable)
- New `ManualSleepSource` (drift-backed) with `upsert`, `delete(night)`,
  `recent(window)`, `watchRecent(window)`.
- Schema bumps from v4 to v5; migration adds `manual_sleep_records`.

### Health source composition

A `MergedHealthSource` wraps the existing `HealthPackageSource` (or fake) plus
`ManualSleepSource`. When `recentMetrics` is called:

1. Fetch OS metrics as today.
2. Load manual sleep records for the same window.
3. For each `night` already present in OS `recentSleep`, drop the manual record
   (OS wins). For nights only present manually, append a `SleepRecord` built
   from the manual row.
4. Sort by `night` descending.

`grantedCategories` is delegated to the wrapped OS source unchanged so the
gating provider keeps reflecting OS state. The merge happens regardless of
permission state — manual entries are honoured even after the user later grants
HealthKit access, until OS data overtakes them night-by-night.

### State / providers

- `manualSleepSourceProvider` — exposes the drift-backed source.
- `healthSourceProvider` now returns `MergedHealthSource(HealthPackageSource(),
  manualSleepSource)`.
- `manualSleepEnabledProvider` — derived bool: true when
  `healthSource.grantedCategories` does not include `HealthCategory.sleep`.
- `journalEntriesProvider` — `StreamProvider<List<JournalEntry>>` over the last
  30 days, combining `watchRecentEntries` and `manualSleepSource.watchRecent`
  (sleep entries rendered as a synthetic `JournalEntry`-shaped row for the
  history list only; not persisted as a journal entry).

### UI files

- `lib/ui/log/log_picker_sheet.dart` — kind chooser + history link.
- `lib/ui/log/journal_entry_sheet.dart` — shared add/edit sheet.
- `lib/ui/log/sleep_entry_sheet.dart` — sleep-specific add/edit sheet (separate
  because the controls differ enough — night + two time pickers vs. a single
  payload value).
- `lib/ui/log/log_history_screen.dart` — list with edit/delete.
- Today screen gets the FAB.

## Error handling

- Save buttons are disabled until the kind-specific payload is valid (units ≥ 1,
  rating chosen, sleep bedtime < wake time, etc.).
- Drift failures bubble up as a snackbar: "Couldn’t save — try again." No
  retry logic; the user can re-tap.
- Sleep entries with `totalSleep` < 1h or > 16h are blocked at the UI layer.

## Migration

- Drift schema 4 → 5: create `manual_sleep_records`.
- Domain `JournalEntry.id` added as nullable; no domain schema migration since
  it's an in-memory field.

## Testing

Unit:

- Domain: `JournalEntry` round-trips with and without `id`.
- `DriftJournalSource`: `addEntry` returns id, `updateEntry` persists changes,
  `deleteEntry` removes a row, `watchRecentEntries` emits on change.
- `ManualSleepSource`: upsert by night, delete, watch.
- `MergedHealthSource`: OS-supplied night wins; manual fills gaps; ordering
  preserved.
- Drift migration test 4 → 5.

Widget:

- Each per-kind sheet: preset selection produces the documented payload key/
  value when saved.
- Sleep sheet: cross-midnight bedtime resolves correctly; out-of-range duration
  blocks save.
- History screen: groups by day, tapping a row opens edit sheet pre-filled,
  swipe-delete triggers undo and restores on undo tap.
- Gating: sleep row hidden when `HealthCategory.sleep` is granted.

## Open questions

None at spec time; surface in the implementation plan if any arise.
