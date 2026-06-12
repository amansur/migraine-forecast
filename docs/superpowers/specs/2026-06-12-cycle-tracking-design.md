# Cycle Tracking Design

Date: 2026-06-12
Status: Approved (brainstorming)

## Motivation

Menstrual cycle is one of the most well-documented migraine triggers — estrogen
withdrawal in the perimenstrual window drives a large share of attacks in
menstruating users. The app already tracks migraine severity by day and
correlates it against environmental triggers; adding lightweight period logging
lets the same insight surface a cycle correlation without turning the app into a
dedicated cycle tracker.

Phase, not period start/end, is the salient variable. But phase is derived from
period dates — the user only logs what they can observe.

## Scope

### In scope

- Logging period start, end, and a severity score.
- Deriving cycle phase for any past or near-future day from logged periods.
- Surfacing phase visually on the Insights screen heatmap.
- Surfacing phase textually in the day-detail sheet.

### Out of scope (YAGNI)

- A "cycle phase" correlation card. Deferred until the correlation engine knows
  how to score phase as a contributor the way it scores barometric pressure,
  sleep, etc. When that lands, phase shows up in the existing trigger
  correlations and day-detail Risk Assessment sections automatically.
- Flow type breakdown (light/medium/heavy as a categorical), symptom tracking,
  ovulation tests, fertility predictions.
- A dedicated cycle-tracking screen or top-level tab.
- Backfill UI for users who switch on cycle tracking later (they just start
  logging from the next period).

## Data model

### `PeriodEvent`

A new persistent record, stored alongside `Attack` records in the journal
source.

| Field       | Type      | Notes                                                                                        |
|-------------|-----------|----------------------------------------------------------------------------------------------|
| `startedAt` | `DateTime`| UTC. Primary key (same convention as `Attack.startedAt`).                                    |
| `endedAt`   | `DateTime?` | UTC. Null while the period is in progress, mirroring the existing in-progress-attack pattern. |
| `severity`  | `int`     | 1–10. Same scale as migraine severity, for consistency.                                      |

No flow type, no symptoms — keep the model minimal. Severity is a single number
the user enters when logging the period start; editable later from the
day-detail sheet.

### Phase derivation (computed, never stored)

Given the ordered list of period starts:

1. **Cycle length** = mean gap between consecutive period starts, computed over
   the most recent ~6 cycles. Requires at least 2 logged periods. Until then,
   phase is "unknown."
2. **For a target day**, find the nearest preceding period start `s` and compute
   `dayOffset = target - s`.
3. Map `dayOffset` to a phase:
   - `menses`: day 1 through the recorded period end (or day 5 if `endedAt` is
     null and the period is ongoing).
   - `follicular`: menses end → cycleLength − 16
   - `ovulatory`: cycleLength − 16 → cycleLength − 12 (roughly the 4-day window
     around ovulation)
   - `luteal`: cycleLength − 12 → next period start

Days beyond the most recent logged period extrapolate using the same offset
math — these are flagged as *predicted* rather than *confirmed*.

A day's phase result has three states:

- `Unknown` — fewer than 2 periods logged, no cycle length yet.
- `Confirmed(phase, dayOfCycle)` — the day falls inside a span anchored by a
  logged period start that has actually elapsed.
- `Predicted(phase, dayOfCycle)` — the day falls after the most recent logged
  period start, projected forward.

## Logging entry points

Two ways to log a period. Both write the same `PeriodEvent`.

### 1. Home screen button

A second primary action button on the home screen, next to the existing "Log
migraine" button.

- Default label: **"Log period"** — tapping records a new `PeriodEvent` with
  `startedAt = now`, no `endedAt`, prompts for severity.
- If a period is currently in progress (most recent `PeriodEvent` has null
  `endedAt`), the label changes to **"End period"** — tapping sets `endedAt =
  now` on that event.

This is the path for logging "right now."

### 2. Heatmap day-tap

In the day-detail sheet that opens when a heatmap day is tapped, add an action
next to the existing "+ Add migraine" button:

- "Mark period start" if no period overlaps this day.
- "Mark period end" if a period started before this day and has no end yet.
- Severity entry is part of the start flow.

This is the path for backfilling past periods.

## Insights screen changes

### Phase ribbon above the heatmap

A thin horizontal band rendered immediately above the existing
`CalendarHeatmap`, spanning the same 8-week window and aligned to the same
column structure.

- Each day-column in the ribbon is colored by its derived phase.
- Visual states:
  - **Confirmed** days: solid fill.
  - **Predicted** days (after the most recent period start, including the
    future portion of the 8-week window): hatched or low-opacity fill.
  - **Unknown** days (when fewer than 2 periods are logged): blank / neutral
    grey.
- Color palette: one color per phase, chosen to not collide with the heatmap's
  severity palette. (Exact palette deferred to implementation.)
- A small legend underneath the ribbon, e.g. `■ follicular  ■ ovulatory  ■
  luteal  ■ menses`.

The ribbon is purely visual — pattern recognition. The user sees whether dark
heatmap cells cluster under a particular phase band.

### Day-detail sheet: cycle row

When the day-detail sheet has a known phase for the day, render a new row near
the top, above the existing "Risk Assessment" section:

```
🩸 Cycle: Day 14 · Ovulatory
```

If the phase is predicted (vs. confirmed), suffix with `(predicted)` or render
slightly muted. If phase is unknown, the row is omitted entirely.

## Data flow

1. User logs a period (home screen button or heatmap day-tap) → `PeriodEvent`
   persisted to the journal source.
2. A new `periodEventsProvider` watches the journal source and exposes the
   ordered list of period events.
3. A `cyclePhaseProvider` derives `(cycleLength, List<PhaseSpan>)` from the
   period events. Pure function, cached.
4. The InsightsScreen reads `cyclePhaseProvider` for both:
   - rendering the ribbon (maps each day in the 8-week window to a phase
     state),
   - feeding the day-detail sheet (a `dayPhaseProvider(day)` derivation).
5. The home screen's "Log period / End period" toggle reads the most recent
   `PeriodEvent` to decide its label.

## Testing

- Phase derivation is the highest-risk piece — pure function, unit-tested
  exhaustively:
  - 0 periods → all days `Unknown`.
  - 1 period → still `Unknown` (no cycle length yet).
  - 2+ periods → confirmed phases for days inside elapsed cycles, predicted for
    days after the most recent period start.
  - Edge: in-progress period (no `endedAt`) → menses spans through day 5 by
    default.
  - Edge: irregular cycle lengths → mean-of-last-6 is robust.
- Widget test for the ribbon: confirmed vs. predicted vs. unknown rendering on
  representative inputs.
- Widget test for the home-screen button label flipping between "Log period"
  and "End period."
- Widget test for the day-detail sheet cycle row appearing/being omitted.

## Open questions / future work

- **Phase as a correlation contributor.** Once the correlation engine grows a
  cycle module, phase will appear in `Risk Assessment` contributors and in the
  trigger correlations list. This is a separate spec.
- **Notifications.** "Your period is likely starting in 2 days — watch for
  perimenstrual migraines" is a natural extension once predictions are
  trustworthy. Not in this spec.
- **Privacy.** Period data is sensitive; current storage is local-only, same as
  migraine data, so no new concerns — but worth re-checking before any future
  cloud sync work.
