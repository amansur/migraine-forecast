# Cute Mascot & Animations Design

**Date:** 2026-06-23
**Branch:** feat/data-portability (to be continued on a new branch)
**Status:** Approved

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
- Size: ~160×160px on the Today screen
- Works in both light (ivory) and comfort (dark) themes

### Animations

- **Idle:** gentle float + breathe loop via `RepeatAnimation` on a `CurvedAnimation`
- **Band change:** body morphs between bezier shapes over 600ms ease-in-out using `TweenAnimationBuilder`; accessories swap simultaneously
- **Happy wiggle:** body squishes vertically then bounces back — triggered by log submission
- **Wave:** accessory animates (ears/petals swing) — triggered on onboarding completion
- **Blink:** brief eye close/open — triggered on settings saved

### Placement

- Today screen: centered above the `RiskDisplay` widget
- Cameos elsewhere: smaller instance (80px) on onboarding completion, log confirmation, and empty states

### SVG Fallback

If the CustomPainter blob doesn't achieve the right cuteness in practice, swap to SVG assets under `assets/mascot/` (one SVG per band state). The `MascotWidget` interface stays identical — only the internal painter changes. Animation controllers remain the same.

---

## Phase 2: UI Animations

### Idle Charm (passive)

Applied via a reusable `AnimatedEntry` wrapper — `SlideTransition` + `FadeTransition` on widget appear. No structural changes to existing screens.

- **Cards** (`TomorrowTile`, `HealthMetricsCard`): slide up + fade in, short stagger between multiple cards
- **Why chips** (`WhyChips`): each chip scale-pops in on staggered delay
- **Contributor chips**: gentle scale pulse on first appearance

### Celebration Moments (triggered)

Implemented as an `OverlayEntry` — no third-party packages.

| Trigger | Animation |
|---|---|
| Log entry submitted | Confetti burst (colored circles with physics) + mascot happy wiggle |
| Onboarding completed | Mascot wave + cheerful scale-up then settle |
| Settings saved | Mascot blink + small checkmark particle |

Confetti: 20–30 colored circles launched from center-bottom with random velocities and gravity, fade out over 1.2s.

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
lib/ui/today/today_screen.dart       — Insert MascotWidget above RiskDisplay; wire to current band
lib/ui/today/risk_display.dart       — Add mascot wiggle callback on band change
lib/ui/today/why_chips.dart          — Wrap chips in AnimatedEntry with stagger
lib/ui/today/tomorrow_tile.dart      — Wrap in AnimatedEntry
lib/ui/common/health_metrics_card.dart — Wrap in AnimatedEntry
lib/ui/log/log_picker_sheet.dart     — Trigger celebration overlay on submit
lib/ui/onboarding/onboarding_screen.dart — Trigger mascot wave on complete
```

---

## Implementation Order

1. `blob_painter.dart` + `mascot_accessories.dart` — draw static blob per band, verify look
2. `mascot_widget.dart` — add idle animation, band-change morphing
3. Wire mascot into `today_screen.dart`
4. `animated_entry.dart` — build wrapper, apply to cards and chips
5. `celebration_overlay.dart` — confetti + particle system
6. Wire celebrations into log, onboarding, settings screens
7. If blob doesn't look right → SVG fallback swap

---

## Non-Goals

- No Lottie files or external animation assets (unless SVG fallback is needed)
- No new third-party packages
- No changes to risk calculation logic or data layer
- Mascot does not replace existing display modes (gauge/numeric/weather icon)
