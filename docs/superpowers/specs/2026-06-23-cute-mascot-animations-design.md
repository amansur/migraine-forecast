# Cute Mascot & Animations Design

**Date:** 2026-06-23
**Branch:** feat/data-portability (to be continued on a new branch)
**Status:** Approved (post-review fixes applied 2026-06-23)

---

## Overview

Add a soft, expressive blob mascot and lightweight UI animations throughout the migraine forecast app. Goal: make the app feel warm, delightful, and emotionally engaging — especially on the Today screen where users check their risk level daily.

---

## Phase 1: Mascot

### Character Design

A soft abstract blob drawn entirely in Flutter `CustomPainter`. The blob is the primary character — no fixed species, but it wears "cute hint" accessories that vary by risk band. The emotional arc escalates from cheerful to wide-eyed-worried, staying cute and warm throughout (never scary or clinical).

| Risk Band | Accessory | Expression |
|---|---|---|
| Low | Flower petals around head | Big happy eyes, rosy cheeks |
| Moderate | Cat ears | Calm, slightly alert eyes |
| High | Bunny ears (drooped slightly) | Worried brow, small sweat drop |
| Very High | Bee antennae (quivering) | Wide eyes, mouth open, flushed |

### Visual Style

- Body shape: roundish blob defined by 4 bezier control points
- Fill: band color (`bandLow` → `bandVeryHigh`) at ~60% opacity — soft, not garish
- Size: ~160×160px on the Today screen; ~80px for cameo appearances
- Works in both light (ivory) and comfort (dark) themes

### Public Interface

`MascotWidget` exposes:
```dart
MascotWidget({
  required RiskBand band,       // drives body color, accessory, expression
  double size = 160,            // diameter of bounding box
  VoidCallback? onWiggle,       // external trigger for happy wiggle
})
```
Band-change morphing is detected internally via `didUpdateWidget` — `MascotWidget` owns the previous-band state. `RiskDisplay` is not involved in band-change detection.

### Animations

- **Idle:** gentle float + breathe loop via `RepeatAnimation` on a `CurvedAnimation`. Controller is paused when the app is backgrounded and resumed on foreground — leverages the existing `WidgetsBindingObserver` already present in `_TodayScreenState` (see `today_screen.dart`).
- **Band change:** detected in `didUpdateWidget`; body morphs between bezier shapes over 600ms ease-in-out using `TweenAnimationBuilder`; accessories swap simultaneously
- **Happy wiggle:** body squishes vertically then bounces back — triggered externally via `onWiggle` callback or internally on band-improve
- **Wave:** accessory animates (ears/petals swing) — triggered on onboarding completion
- **Blink:** brief eye close/open — triggered on settings saved

### Placement

- Today screen: centered above the `RiskDisplay` widget
- Cameos elsewhere (80px):
  - `_OnboardingCard` in `onboarding_screen.dart` — on completion
  - `LogPickerSheet` confirmation moment — after log save returns
  - `_NoDataCard` in `today_screen.dart` — idle empty state

### PNG Fallback

If the CustomPainter blob doesn't achieve the right cuteness in practice, swap to raster PNG assets under `assets/mascot/` (one PNG per band state, e.g. `mascot_low.png`). Loaded via `Image.asset`. The `MascotWidget` interface stays identical — only the internal painter changes. Animation controllers remain the same. No new packages required.

---

## Phase 2: UI Animations

### Idle Charm (passive)

Applied via a reusable `AnimatedEntry` wrapper — `SlideTransition` + `FadeTransition` on widget appear. No structural changes to existing screens.

- **Cards** (`TomorrowTile`, `HealthMetricsCard`): slide up + fade in, short stagger between multiple cards
- **`WhyChips`**: each chip scale-pops in on staggered delay (`why_chips.dart`)
- **`ContributorChip`**: gentle scale pulse on first appearance (`common/contributor_chip.dart`)

### Celebration Moments (triggered)

Implemented as an `OverlayEntry` — no third-party packages.

| Trigger | Call site | Animation |
|---|---|---|
| Journal log saved | `journal_entry_sheet.dart` — after `_save()` succeeds | Confetti burst + mascot happy wiggle |
| Sleep log saved | `sleep_entry_sheet.dart` — after `_save()` succeeds | Confetti burst + mascot happy wiggle |
| Attack log saved | `log_attack_screen.dart` — after `_save()` succeeds | Confetti burst + mascot happy wiggle |
| Onboarding completed | `onboarding_screen.dart` | Mascot wave + cheerful scale-up then settle |
| Settings saved | `settings_screen.dart` | Mascot blink + small checkmark particle |

Confetti: 20–30 colored circles using `BrandColors` palette (sage, ivory, band colors) launched from center-bottom with random velocities and gravity, fade out over 1.2s. Colors stay on-brand, not arbitrary bright hues.

### Accessibility / Reduced Motion

Check `MediaQuery.disableAnimations` at the root of `MascotWidget` and `AnimatedEntry`. When true:
- Mascot renders statically (correct band state, no idle loop, no morphing)
- `AnimatedEntry` shows widgets instantly (no slide/fade)
- Celebrations skip confetti; mascot still updates expression
This is critical for migraine users who may have motion sensitivity or photophobia.

---

## Architecture

### New Files

```
lib/ui/shared/mascot/
  blob_painter.dart          — CustomPainter: bezier blob body morphing
  mascot_widget.dart         — StatefulWidget: animation controllers, idle loop, band switching
  mascot_accessories.dart    — Painters for ears, petals, antennae per band

lib/ui/shared/animations/
  animated_entry.dart        — Reusable slide+fade wrapper widget
  celebration_overlay.dart   — Confetti + particle burst via OverlayEntry
```

### Modified Files

```
lib/ui/today/today_screen.dart            — Insert MascotWidget above RiskDisplay; pass current band;
                                            pause/resume idle animation via existing WidgetsBindingObserver
lib/ui/today/why_chips.dart               — Wrap chips in AnimatedEntry with stagger
lib/ui/today/tomorrow_tile.dart           — Wrap in AnimatedEntry
lib/ui/common/health_metrics_card.dart    — Wrap in AnimatedEntry
lib/ui/common/contributor_chip.dart       — Wrap in AnimatedEntry with scale pulse
lib/ui/log/journal_entry_sheet.dart       — Trigger celebration overlay after _save() succeeds
lib/ui/log/sleep_entry_sheet.dart         — Trigger celebration overlay after _save() succeeds
lib/ui/log/log_attack_screen.dart         — Trigger celebration overlay after _save() succeeds
lib/ui/onboarding/onboarding_screen.dart  — Trigger mascot wave on complete
lib/ui/settings/settings_screen.dart      — Trigger mascot blink on save
```

Note: `risk_display.dart` is **not** modified — band-change detection lives in `MascotWidget.didUpdateWidget`.

---

## Testing

- Widget tests for `MascotWidget`: one test per band state verifying correct accessory/expression
- Golden tests for `BlobPainter` per band (catch visual regressions)
- Use `tester.binding.disableAnimations = true` in widget tests to avoid infinite `RepeatAnimation` loops hanging `pumpAndSettle`

---

## Implementation Order

1. `blob_painter.dart` + `mascot_accessories.dart` — draw static blob per band, verify look
2. `mascot_widget.dart` — add idle animation, band-change morphing via `didUpdateWidget`
3. Wire mascot into `today_screen.dart`, connect `WidgetsBindingObserver` for idle pause/resume
4. `animated_entry.dart` — build wrapper, apply to cards and chips
5. `celebration_overlay.dart` — confetti + particle system
6. Wire celebrations into log sheets (`journal_entry_sheet`, `sleep_entry_sheet`, `log_attack_screen`), onboarding, settings
7. Add reduced-motion checks to `MascotWidget` and `AnimatedEntry`
8. Write widget + golden tests
9. If blob doesn't look right → PNG fallback swap

---

## Non-Goals

- No Lottie files or external animation assets
- No new third-party packages (PNG fallback uses `Image.asset`, no `flutter_svg` needed)
- No changes to risk calculation logic or data layer
- Mascot does not replace existing display modes (gauge/numeric/weather icon)
