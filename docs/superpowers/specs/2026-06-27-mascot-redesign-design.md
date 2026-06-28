# Mascot Redesign — Design Spec

**Date:** 2026-06-27  
**Branch:** feat/mascot  
**Status:** Approved

---

## Problem

The current mascot (a green blob with subtle painted-on accessories) is not visually cute enough. The accessories (petals, cat ears, bunny ears, bee antennae) are too small and blend into the body, making the character unrecognizable. Canvas-drawn characters are hard to make charming; SVG assets are the right tool.

Additionally, the alcohol trigger explanation reads "2.0 units in last 24h" without specifying what kind of units.

---

## Goals

1. Replace the CustomPainter mascot body with SVG assets that clearly depict one of four cute characters.
2. Let the user choose their mascot (first tap on mascot + Settings).
3. Each character visually evolves across the four risk bands.
4. Fix "units" label to "alcohol units".

---

## Characters & Risk Band Evolution

Four characters, each with 4 SVG variants (`low`, `moderate`, `high`, `veryHigh`):

| Character | Low | Moderate | High | Very High |
|-----------|-----|----------|------|-----------|
| **Flower** | Full bloom, 5 petals fanned wide | Petals slightly closing in | Petals drooping down | Petals fully wilted/folded |
| **Kitty** | Ears perked up, tail up | Ears slightly angled back | Ears flat, tail tucked | Ears flat, eyes wide, sweat drop |
| **Bunny** | Long ears straight up | Ears tilted 30° outward | Ears flopped sideways | Ears completely drooped down |
| **Bee** | Antennae upright, wings spread | Wings lower, antennae bent | Wings folded in, antennae drooped | Wings down, antennae wilted, sweat drop |

**SVG content:** body outline + character-specific features only. No face. The center ~60% of each SVG canvas must remain clear for the face painter overlay.

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

Stored in the existing settings repository alongside `temperatureUnit` / `pressureUnit`. No new storage mechanism.

---

## Mascot Picker UI

A bottom sheet (`mascot_picker_sheet.dart`) with:
- Heading: "Choose your companion"
- 2×2 grid of character tiles, each showing the `low`-band SVG + character name
- Selected tile has a green accent highlight ring
- Auto-dismisses on selection (live preview updates immediately behind the sheet)

**Entry points:**
1. First tap on the mascot widget on the Today screen
2. Settings screen — new "Mascot" row under an "Appearance" section

---

## Code Changes

### New files
- `assets/mascots/` — 16 SVG files
- `lib/ui/shared/mascot/mascot_character.dart` — enum + asset path resolver
- `lib/ui/shared/mascot/mascot_widget.dart` — stacks SVG body + face painter
- `lib/ui/shared/mascot/mascot_picker_sheet.dart` — picker bottom sheet

### Modified files
- `lib/ui/shared/mascot/blob_painter.dart` → renamed to `mascot_face_painter.dart`; blob body drawing removed, face painting retained
- `lib/ui/shared/mascot/mascot_accessories.dart` — deleted (accessories now live in SVGs)
- `pubspec.yaml` — add `flutter_svg`, register `assets/mascots/` directory
- Settings repository + provider — add `MascotCharacter` field
- Settings screen — add Appearance > Mascot row
- Today screen — wire first-tap gesture to open picker

### Deleted files
- `lib/ui/shared/mascot/mascot_accessories.dart`

---

## Animation Continuity

The widget stack in `mascot_widget.dart`:

```
Stack [
  SvgPicture(asset: resolvedPath)        ← static per (character, band)
  AnimatedBuilder(mascotController)       ← face: blink, squish, sway, blush
]
```

- Band change → SVG crossfade (~200ms `AnimatedSwitcher`)
- Character change → same crossfade
- `MascotController` (blink, wave, celebration) unchanged
- Face painter always draws at same relative position; all SVGs keep center 60% clear

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
- Dark mode color variants — SVGs are drawn in white/monochrome and tinted at render time via `SvgPicture`'s `colorFilter`, so they automatically match the app's theme green without separate dark-mode assets
