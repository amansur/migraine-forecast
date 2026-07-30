# Location UX + per-day coordinate storage

**Date:** 2026-07-29
**Status:** Approved

## Problem

Location handling is opaque and in places misleading:

1. **Settings** — the "Set location" dialog shows `San Francisco, CA` as a text
   hint, which reads like a real default value. It is only a hardcoded
   placeholder. The location row also shows raw `lat, lon` coordinates because
   the geocoder's human-readable `displayName` is discarded when a manual
   location is saved.
2. **Today** — the current location is not surfaced anywhere, so the user cannot
   tell what "current" means.
3. **History (day-detail)** — a day with no per-day override shows the generic
   label `Auto (GPS)`. The data for that day was fetched at a specific location,
   but that location is never stored, so the app cannot tell the user which place
   the metrics came from. Worse, if location were displayed as "current
   effective location", changing the manual location or moving would retroactively
   mislabel past history.

### Root cause

Locations are stored as raw `lat`/`lon` in most places. A human-readable name is
persisted only for per-day history overrides (`DayLocationOverrides.displayName`).
There is no reverse geocoding. Critically, the location resolved inside
`ContextBuilder.build` (`override ?? manual ?? GPS`) is never carried into
`EvaluationContext`, the engine's `RiskAssessment`, or the persisted
`RiskAssessments` row — so each stored assessment has no record of where it was
scored.

## Design

### A. Store resolved coordinates on every assessment (core change)

- **DB migration → schemaVersion 16.** Add to `RiskAssessments`:
  - `resolvedLat` (real, nullable)
  - `resolvedLon` (real, nullable)
  - `locationName` (text, nullable)

  Nullable because not every day has a weather/location-driven score, and older
  rows may not map cleanly to a stored location.

- **Thread the location through the evaluation path.** `ContextBuilder.build`
  already computes the effective `loc`. Propagate it:
  - Add `resolvedLat` / `resolvedLon` / `locationName` to `EvaluationContext`
    (domain package). `ContextBuilder` sets them from `loc` (name from the
    manual label or a per-day override's `displayName`; null for GPS at compute
    time — reverse-geocoded lazily at display).
  - `RiskEngine` copies these three fields onto the produced `RiskAssessment`.
  - `AssessmentRepository.save` persists them into the new columns.

  This makes "what location was this scored at" an honest property of a stored
  assessment. Rationale for putting it on the domain model rather than passing it
  out-of-band at the save site: the location is part of what was evaluated, so it
  belongs with the evaluation, and it keeps a single save path.

- **Backfill existing rows in the v16 migration.** `WeatherSnapshots` already
  stores `lat`/`lon` plus a coverage window (`coverageStart`/`coverageEnd`). For
  each existing assessment row, copy `lat`/`lon` from the weather snapshot whose
  coverage window contains the assessment's `targetDate`, preferring the snapshot
  whose `fetchedAt` is closest to the assessment's `computedAt`. `locationName`
  stays null for backfilled rows (historical name unknown) and is
  reverse-geocoded lazily at display time. Assessments with no covering snapshot
  (e.g. sleep-only scores) keep null coordinates and are shown as "Location not
  recorded".

### B. Persist a name for the manual location

- `PersistedManualLocationSource` gains a `manual_label` settings key alongside
  `manual_lat`/`manual_lon`. `UserLocation.label` already exists — populate it.
- `setManualLocationProvider` signature becomes `(lat, lon, label)`; the Settings
  dialog passes the geocoder's `displayName` instead of discarding it.

### C. Reverse-geocoder (lat/lon → "City, Region")

- Add the `geocoding` package (Baseflow, same family as the existing
  `geolocator`).
- New `ReverseGeocoder` service + Riverpod provider. Input: lat/lon. Output: a
  short "City, Region" string. Coordinate-keyed in-memory cache to avoid repeat
  OS calls. Graceful fallback to formatted raw coordinates on failure/offline or
  empty results.
- Used to name the live auto/GPS location on Today, and to name stored historical
  coordinates that have a null `locationName`.

### D. Screens

- **Settings**
  - Remove the misleading `San Francisco, CA` hint → neutral hint
    (`e.g. city, ZIP, or country`).
  - Pre-fill the dialog's text field with the current location's name (empty when
    on auto).
  - Location row subtitle shows the place name (falling back to coords), not raw
    coordinates as the primary label.
- **Today** — add a compact location line near the header:
  `📍 Oakland, CA · Current location` (or the manual place name). Tapping it opens
  the Settings location control. Backed by a single "effective location" provider
  (manual label if set, else reverse-geocoded live GPS).
- **History (day-detail)** — replace `Auto (GPS)` with the assessment's *stored*
  location:
  - override present → override `displayName` (unchanged);
  - else `locationName`, or reverse-geocoded stored `resolvedLat`/`resolvedLon`,
    rendered as `City, Region (lat, lon)`;
  - else (no stored coords) → "Location not recorded".
  Existing search / "Use auto" affordances are preserved.

### E. Shared effective-location provider

A single `FutureProvider` resolves the current effective location into a small
display model `{ name, coords, isAuto }`, feeding Today and Settings-auto so the
label logic lives in one place:
- manual set → stored `label` (fallback coords), `isAuto: false`;
- else GPS → reverse-geocoded "City, Region" + coords, `isAuto: true`;
- else unset/denied → "Location not set".

## Edge cases

- Reverse-geocode failure / offline → fall back to `Current location (lat, lon)`.
- Location permission denied and no manual location → "Location not set", prompting
  the user to set one.
- History day with null stored coordinates → "Location not recorded".

## Testing

- v16 migration test, including backfill-from-weather-cache mapping (covering
  window match, closest-fetch tie-break, no-match → null).
- Manual-label persistence round-trip.
- Reverse-geocoder fallback behaviour (success, empty result, thrown error).
- Effective-location provider across manual / auto / unset states.
- Widget tests for Settings dialog (no SF hint, pre-fill), Today location line,
  and History day-detail label, using a fake reverse-geocoder.

## Out of scope

- Full location autocomplete/typeahead in the search dialog.
- Multiple saved/favourite locations.
- Backfilling historical `locationName` for old rows (kept null; reverse-geocoded
  lazily).
