# Icon-Based Random Mascots

**Date:** 2026-07-06
**Status:** Approved

## Summary

Replace the current mascot system (4 selectable SVG characters — bee, bunny,
kitty, flower — each with 4 risk-band variants) with a single pool of
hand-drawn icon mascots sliced from `assets/icons.png`. Each risk band has
multiple mood-appropriate icons; the app picks one at random, stable per day.
Users no longer pick a character.

## Assets

- Slice `assets/icons.png` (~16 distinct icons on a black background) into
  individual PNGs, one per icon, with the black background made transparent.
- Save to `assets/mascots/` as `<icon-name>.png` (e.g. `sun.png`,
  `raining_cloud.png`). Delete the 16 existing `*_<band>.svg` files.
- During slicing, inspect each icon up close and finalize which bands it
  belongs to. Baseline mapping (icons may repeat across bands):
  - **low**: sun, berry pot, big star, butterfly, fish
  - **moderate**: potted plant, teacup, notebook & pencil, small flower,
    snail, cat
  - **high**: sad flower, sleepy cloud, sprout/grass
  - **veryHigh**: raining cloud, sleepy cloud, sad flower
- Principle: happiest/most energetic icons at low risk, calm/cozy at
  moderate, droopy/sleepy at high, distressed (crying rain cloud) at very
  high.

## Selection

- New module (replacing `lib/state/mascot_character.dart`) exposes a
  `Map<RiskBand, List<String>>` pool and
  `String mascotAssetFor(RiskBand band, {DateTime? date})`.
- Pick is seeded by `(local calendar date, band)` so the mascot is identical
  across screens and all day, and changes daily.
- **UX to revisit later** (user flagged): the per-day cadence may change
  (e.g. per-launch or manual shuffle). Keep the seed logic isolated so the
  cadence is a one-line change.
- Remove `MascotCharacter` enum, `kDefaultMascotCharacter`, the settings
  character picker, and `lib/ui/shared/mascot/mascot_picker_sheet.dart`,
  plus any persisted character preference.

## Rendering

- `MascotWidget` keeps its API (`band`, `size`, `controller`, `onWiggle`,
  `idle`) but drops the `character` parameter; renders the pooled PNG via
  `Image.asset`.
- Keep idle animations (float, hop) and one-shot actions wiggle and wave
  (whole-widget transforms).
- Remove blink and the face-overlay system: `MascotAction.blink`,
  `mascot_face_painter.dart`, and `mascot_accessories.dart`/`blob_painter.dart`
  if they exist only to serve the SVG face system (verify usage first).
- `precacheMascots()` switches from the flutter_svg cache to
  `precacheImage` over all pooled PNGs.

## Fallout / Migration

- Update all `MascotWidget` call sites (today screen, onboarding, settings,
  log sheets, main.dart) to drop `character`.
- Remove mascot-choice UI from onboarding and settings.
- Update `pubspec.yaml` asset declarations; `flutter_svg` may become
  removable if nothing else uses it (verify).
- Adjust tests referencing `MascotCharacter` or blink.

## Error Handling

- `mascotAssetFor` must always return a valid path (pools are compile-time
  constants; an empty pool is a programming error, guarded by an assert).

## Testing

- Unit tests: pool covers all four bands, each band has ≥1 icon,
  same-day/same-band picks are identical, different dates can differ.
- Widget test: `MascotWidget` renders an `Image` for each band; wiggle/wave
  still animate.
- Manual review in-app of the finalized icon slicing and mapping (user
  requested review after slicing).
