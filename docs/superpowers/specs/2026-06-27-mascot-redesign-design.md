# Mascot Redesign — Design Spec

**Date:** 2026-06-27  
**Branch:** feat/mascot  
**Status:** Approved (revised after Opus review)

---

## Problem

The current mascot (a green blob with subtle painted-on accessories) is not visually cute enough. The accessories (petals, cat ears, bunny ears, bee antennae) are too small and blend into the body, making the character unrecognizable. Canvas-drawn characters are hard to make charming; SVG assets are the right tool.

Additionally, the alcohol trigger explanation reads "2.0 units in last 24h" without specifying what kind of units.

---

## Goals

1. Replace the CustomPainter mascot body with SVG assets that clearly depict one of four cute characters.
2. Let the user choose their mascot (every tap on mascot on Today screen + Settings).
3. Each character visually evolves across the four risk bands.
4. Fix "units" label to "alcohol units".

---

## Characters & Risk Band Evolution

Four characters, each with 4 SVG variants (`low`, `moderate`, `high`, `veryHigh`):

| Character | Low | Moderate | High | Very High |
|-----------|-----|----------|------|-----------|
| **Flower** | Full bloom, 5 petals fanned wide | Petals slightly closing in | Petals drooping down | Petals fully wilted/folded |
| **Kitty** | Ears perked up, tail up | Ears slightly angled back | Ears flat, tail tucked | Ears flat, sweat drop |
| **Bunny** | Long ears straight up | Ears tilted 30° outward | Ears flopped sideways | Ears completely drooped down |
| **Bee** | Antennae upright, wings spread | Wings lower, antennae bent | Wings folded in, antennae drooped | Wings down, antennae wilted, sweat drop |

**SVG color strategy: multi-color.** SVGs use their own colors — no global `colorFilter`. Each character has hand-chosen palette (e.g. bee is yellow/black, flower has a distinct center). Band evolution is expressed through silhouette shape (ears drooping, petals wilting) rather than color. The existing per-band body tint (`colorForBand`) is dropped; the face painter's blush/sweat/brow expression carries the emotional register instead.

**SVG content:** body outline + character-specific colored features. No face elements. Each SVG must leave the **center 65% of the canvas** (by width and height) clear so the face painter overlay doesn't collide with character features. The face bounding box is approximately ±30% from center — the 65% clear zone provides a 2.5% margin on each side.

**Asset paths:** `assets/mascots/<character>_<band>.svg`  
16 files total: `flower_low.svg`, `flower_moderate.svg`, … `bee_veryHigh.svg`

---

## Data Model

New enum in `lib/ui/shared/mascot/mascot_character.dart`:

```dart
enum MascotCharacter { flower, kitty, bunny, bee }
```

Helper method resolves `(MascotCharacter, RiskBand)` → asset path string.

Default character: `kitty`.

Stored in the existing settings repository alongside `temperatureUnit` / `pressureUnit`. No new storage mechanism. The setter invalidates a `mascotCharacterProvider` so all watching widgets rebuild immediately (enabling live picker preview).

---

## Mascot Picker UI

A bottom sheet (`mascot_picker_sheet.dart`) with:
- Heading: "Choose your companion"
- 2×2 grid of character tiles, each showing the `low`-band SVG + character name
- Selected tile has a green accent highlight ring
- Auto-dismisses on selection (Today screen updates live behind the sheet)

**Entry points:**
1. **Every tap** on the mascot widget on the Today screen opens the picker. A subtle `InkWell` ripple provides tap affordance.
2. Settings screen — new "Mascot" row under an "Appearance" section, opens the same bottom sheet.

---

## Code Changes

### New files
- `assets/mascots/` — 16 SVG files
- `lib/ui/shared/mascot/mascot_character.dart` — enum + asset path resolver
- `lib/ui/shared/mascot/mascot_widget.dart` — stacks SVG body + face painter + animation Transform
- `lib/ui/shared/mascot/mascot_picker_sheet.dart` — picker bottom sheet

### Modified files
- `lib/ui/shared/mascot/blob_painter.dart` → renamed `mascot_face_painter.dart`; blob body removed, face painting retained
- `lib/ui/shared/mascot/mascot_accessories.dart` → **deleted** (accessories now live in SVGs)
- `pubspec.yaml` — add `flutter_svg`, register `assets/mascots/` directory
- Settings repository + provider — add `MascotCharacter` field + `mascotCharacterProvider`
- Settings screen — add Appearance > Mascot row
- Today screen — wrap mascot in `GestureDetector` (every tap → open picker)
- Onboarding screen — wire `MascotCharacter` through to `MascotWidget`
- **6 test files** — update imports after rename/delete; regenerate golden snapshots; add `SvgPicture` asset pre-caching in widget test `setUp`

### Deleted files
- `lib/ui/shared/mascot/mascot_accessories.dart`

---

## Animation Continuity

The widget stack in `mascot_widget.dart`:

```
AnimatedScale / AnimatedSlide  ← squish + wiggle Transform wrapping entire stack
  AnimatedSwitcher(200ms)      ← crossfades SVG on band or character change
    SvgPicture(asset)          ← multi-color SVG body per (character, band)
  AnimatedBuilder(controller)  ← face painter: blink, blush, brow, mouth, sweat
  AnimatedBuilder(controller)  ← sway Transform for wave animation
```

| Controller action | What animates |
|---|---|
| `blink` | Face painter `eyeOpen` → 0 and back |
| `wave` | `sway` Transform on the SVG layer (gentle rotation ±5°) |
| `wiggle` | `AnimatedScale` squish on the outer wrapper (scaleX up, scaleY down) |
| `celebration` | `wiggle` + confetti overlay (unchanged) |
| `quiver` (bee antennae) | **Dropped** — antennae are baked into static SVG |

- Band change → 200ms `AnimatedSwitcher` crossfade on SVG
- Character change → same crossfade
- Face always draws at the same relative position across all characters

---

## SVG Asset Pre-caching

All 16 SVGs are pre-cached at app startup via `precachePicture` to avoid first-frame flash. This is handled in `main.dart` (or the root widget's `initState`) before the first route renders.

---

## Units Fix

`packages/domain/lib/src/modules/alcohol.dart` line 69:

```dart
// Before
explanation: '${totalUnits.toStringAsFixed(1)} units in last ${lookback.inHours}h',
// After
explanation: '${totalUnits.toStringAsFixed(1)} alcohol units in last ${lookback.inHours}h',
```

---

## Out of Scope

- Lottie / frame-by-frame animation within SVGs
- Per-character face positioning (all characters share the same face layout)
- Dark mode SVG variants (multi-color SVGs work on the app's light background; dark mode is a follow-up)
- Onboarding mascot picker step (users discover the picker via first tap)
- SVG art sourcing / licensing (to be handled separately)
