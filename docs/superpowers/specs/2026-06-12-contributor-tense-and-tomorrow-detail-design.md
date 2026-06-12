# Contributor Tense + Tomorrow Detail Design

Date: 2026-06-12
Status: Draft

## Problem

The "Why" contributor chips on the Today screen mix tenses and one of them is
factually wrong:

| Chip                                          | Says                       | Actually measures                          |
|-----------------------------------------------|----------------------------|---------------------------------------------|
| `Pressure dropping 6.1 mmHg over next 48h`    | future window              | past 24h (`maxPressureDropOver(24h)`)       |
| `Humidity 85% (+69%), rising`                 | present + past trend       | window from `now − 24h` for 48h forward     |
| `Temp swing 19.8°F over 24h, cooling`         | ambiguous                  | past 24h relative to `samples.last.at`      |

Three problems compound:

1. **Tense inconsistency** — the user can't tell whether a chip describes what
   has already happened, what's happening now, or what's coming.
2. **The pressure label lies** — the `lookahead` param is interpolated into
   the string but never passed to the data query.
3. **Window anchor drift** — `tempSwingInLast` and `humidityTrendInLast`
   anchor to `samples.last.at`, not to a deliberate moment. When the series
   includes forecast samples, "last 24h" silently means "last 24h of
   forecast," not "last 24h before now."

Separately, the Today screen shows a `TomorrowTile` with a tomorrow risk
score, but tapping it does nothing. There is no way to see *why* tomorrow's
score is what it is.

## Goals

1. Every contributor chip's text matches the data it was computed from, in a
   tense consistent with the day being scored.
2. Today's chips read past-tense ("Pressure dropped 6.1 hPa in last 24h").
3. Tomorrow's chips read future-tense ("Pressure dropping 6.1 hPa over next
   24h") and are reachable by tapping the Tomorrow tile.
4. Modules compute their windows relative to the day being scored, not
   relative to whichever sample happens to be last in the series.

## Non-goals

- Adding new trigger modules.
- Changing the underlying risk scoring math. Tense and window-anchoring are
  *labeling and data-windowing* fixes; module weights and thresholds are
  untouched.
- A multi-day forecast view (Day After Tomorrow, etc.). Just Today and
  Tomorrow for now.

## Design

### 1. Anchor module windows to `targetDate`, not `samples.last`

`EvaluationContext` already carries `now` and `targetDate`. Modules should
read time windows relative to those, never relative to `samples.last.at`.

Introduce two helpers on `WeatherSeries` (mirroring the existing window
helpers, but parameterized by an anchor moment):

```dart
double? tempSwingAround(DateTime anchor, Duration window);
double? tempTrendAround(DateTime anchor, Duration window);
double? humidityTrendAround(DateTime anchor, Duration window);
double? maxPressureDropAround(DateTime anchor, Duration window);
```

The semantics depend on whether the anchor is in the past or future relative
to the series:

- **Today (anchor = ctx.now):** window covers `[anchor − duration, anchor]` —
  the *past* window.
- **Tomorrow (anchor = ctx.targetDate):** window covers `[ctx.now, anchor +
  duration]` — the *future* window using forecast samples.

The existing `…InLast` methods stay for now (used elsewhere?) and the new
`…Around` methods supersede them in the modules.

### 2. Tense-correct explanation strings

Each module formats its explanation based on whether the window is past or
future. A small helper:

```dart
enum WindowDirection { past, future }

WindowDirection directionFor(EvaluationContext ctx) =>
    ctx.targetDate.isAfter(ctx.now) ? WindowDirection.future : WindowDirection.past;
```

Per-module formats:

| Module        | Past (Today)                                          | Future (Tomorrow)                                         |
|---------------|-------------------------------------------------------|-----------------------------------------------------------|
| pressure_drop | `Pressure dropped 6.1 hPa in last 24h`                | `Pressure dropping 6.1 hPa over next 24h`                 |
| temp_swing    | `Temp swung 19.8°F in last 24h, cooling`              | `Temp swing 19.8°F expected over next 24h, cooling`       |
| humidity      | `Humidity 85%, rose +69% in last 24h`                 | `Humidity reaching 85%, rising +69% over next 24h`        |
| air_quality   | `PM2.5 peaked at X µg/m³ in last 24h`                 | `PM2.5 forecast to reach X µg/m³ over next 24h`           |

Other modules (sleep, HRV, caffeine, hydration, stress, alcohol, refractory,
menstrual_phase) are observational/personal and don't have a forward vs.
backward framing; their existing strings stay.

### 3. Make Tomorrow tappable → TomorrowDetailScreen

`TomorrowTile` becomes tappable. Tapping it pushes a new
`TomorrowDetailScreen` that mirrors the Today screen's structure:

```
Tomorrow                          ← AppBar
Tue, Jun 13

  [Risk gauge or pill]

  Why
  [Pressure dropping 6.1 hPa over next 24h]
  [Humidity reaching 85%, rising +69% over next 24h]
  [Temp swing 19.8°F expected over next 24h, cooling]
```

The screen reads from the existing `tomorrowRiskAssessmentProvider`. It
renders the same `RiskDisplay` + Why-chips layout as `TodayScreen` but
without the log button.

The `TomorrowTile` gains a trailing `chevron_right` and a tap handler that
pushes the new route. A new go_router route `/tomorrow` is added.

### 4. Centralize the chip widget so Today and Tomorrow share it

`ContributorChip` already exists. The plan extracts the chip list into a
small `WhyChips` widget that takes `List<TriggerSignal>` so both screens
render identically.

## Data flow

No new data sources. The pieces are:

1. Module evaluation uses `ctx.targetDate` and `ctx.now` to pick the window
   anchor and direction.
2. The explanation string is formatted using the same direction.
3. Today screen renders chips from `riskAssessmentProvider` (targetDate =
   today); Tomorrow screen renders chips from `tomorrowRiskAssessmentProvider`
   (targetDate = tomorrow).

## Testing

- Unit tests for each updated module:
  - Past window: with a series of historical + forecast samples, asserting
    the module reads only the past 24h relative to `ctx.now`.
  - Future window: asserting the module reads only forecast samples in
    `[ctx.now, ctx.targetDate + 24h]`.
  - Tense correctness in the produced explanation string.
- Regression test for the pressure_drop bug: the explanation's stated window
  must match the queried window.
- Widget test for `TomorrowDetailScreen`: chips render with future-tense
  strings.
- Widget test for `TomorrowTile`: tap pushes `/tomorrow`.

## Implementation steps

1. Add the `…Around(DateTime anchor, Duration window)` helpers to
   `WeatherSeries`, with tests.
2. Add a `directionFor(ctx)` helper in `packages/domain/lib/src/engine/`.
3. Update `pressure_drop`, `temp_swing`, `humidity`, `air_quality` to:
   - use the new `…Around` helpers anchored to `ctx.now` or `ctx.targetDate`,
   - format explanations using `directionFor(ctx)`.
4. Extract `WhyChips` from the existing inline `Wrap` in `TodayScreen`.
5. Add `TomorrowDetailScreen` and the `/tomorrow` route.
6. Make `TomorrowTile` tappable, add chevron.
7. Update tests.

Steps 1–3 are the bug fix + tense fix and can ship independently. Steps 4–6
are the Tomorrow detail UX and can ship as a follow-up if needed, but are
small enough to bundle.

## Open questions

- **Sample density for forecast windows.** Open-Meteo (or whichever
  forecast provider) gives hourly forecast; the `…Around` helpers assume
  enough samples in the future window to compute trends. If the series is
  empty in the forward window, the module should fall back to a "forecast
  unavailable" `TriggerSignal.zero` rather than producing a misleading chip.
- **Unit conversion.** The current pressure chip shows mmHg (per user
  setting) but the module emits hPa. The conversion happens elsewhere in
  the rendering pipeline — confirm that the new past/future strings flow
  through the same unit formatter.
