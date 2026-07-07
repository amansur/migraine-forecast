# Mascot per-icon idle styles + ambient wiggles — design

Date: 2026-07-07. Follows the icon-mascots and cycling/debug-band specs.
Decisions made with the user: per-mascot idle **replaces** the host-chosen
`MascotIdle` (option 1); five idle styles with the mapping below; ambient
wiggle every 6–12 s at ~60 % of tap amplitude.

## Goals

- Each mascot idles with its own personality instead of the shared
  float/hop.
- Mascots occasionally wiggle on their own (ambient), so the screen feels
  alive without a tap.

## 1. Idle styles

New enum and mapping in `lib/state/mascot_pool.dart`, mirroring the
`WiggleStyle` pattern:

```dart
enum MascotIdleStyle { hover, drift, sway, still, bounce }

const Map<String, MascotIdleStyle> kMascotIdle = {
  'butterfly': hover, 'big_star': hover,
  'sleepy_cloud': drift, 'raining_cloud': drift,
  'small_flower': sway, 'sad_flower': sway, 'sprout': sway,
  'potted_plant': sway, 'berry_pot': sway,
  'snail': still, 'teacup': still,
  // bounce (default): sun, fish, cat, notebook
};

MascotIdleStyle idleStyleFor(String assetPath); // stem lookup, default bounce
```

### Motion (in `mascot_widget.dart`, driven by the existing `_idle` controller)

All styles keep the existing breathe scale on top, are multiplied by the
existing `idleMute` while a one-shot action plays, and resolve to identity
under reduced motion (`disableAnimations`).

- **hover** — vertical bob plus slight horizontal figure-8 (x uses double
  the phase frequency), airborne feel. Amplitudes ≈ y ±5 px, x ±3 px.
- **drift** — slow horizontal wander ±6 px with tiny vertical ±2 px.
- **sway** — small rotation ±0.035 rad around bottom-center (breeze).
- **still** — breathe only; no translation/rotation.
- **bounce** — the current hop arc at reduced amplitude (≈ −10 px, squash
  0.06), periodic.

### Removals

- `MascotIdle` enum and the `idle:` parameter on `MascotWidget` are
  deleted; all hosts (TodayScreen, log sheets, onboarding, settings) stop
  passing it.
- Idle style is derived from `_assetPath` in the build — it follows cycle
  taps and band changes automatically (no pinning; pinning is only needed
  for in-flight one-shots).

## 2. Ambient wiggle

In `_MascotWidgetState`:

- A `Timer` scheduled at a uniform random delay in **6–12 s**
  (`math.Random`). On fire: play the mascot's own wiggle style via the
  existing one-shot path, with an **amplitude factor of 0.6** applied to
  the style constants (squish 0.22→0.132, flutter ±0.21→±0.126 rad,
  stretch 0.30→0.18, bob 14 px→8.4 px + squish 0.12→0.072). Then
  reschedule.
- **Skip (and just reschedule)** when: reduced motion is on, the app is
  not resumed (reuse the existing `WidgetsBindingObserver`), or an action
  is already in flight.
- Any explicit action (tap wiggle / wave / band-drop wiggle) **resets the
  timer** so ambient and tap wiggles don't stack.
- Timer cancelled on dispose and on pause/inactive/hidden; restarted on
  resume.
- Ambient wiggles do **not** call `onWiggle` (that callback is for user
  taps/host semantics) and do not touch the `MascotController` ack path.

## 3. Testing

Widget tests (`fake_async`/`tester.pump` driven):

- For each idle style: mid-phase transform differs from identity in the
  expected channel (translation/rotation), and is identity under reduced
  motion.
- Idle style switches when the displayed asset changes (cycle tap).
- Ambient: advancing past the max interval fires a wiggle; suppressed
  under reduced motion; suppressed while an action is in flight (only
  rescheduled); tap resets the pending ambient timer; timer cancelled on
  dispose (no pending-timer leaks in tests).
- Existing wiggle/wave/cycle tests keep passing; hosts compile without
  the `idle:` param.

## Non-goals

- No new asset work, no per-mascot one-shot changes beyond the amplitude
  factor, no settings toggle for ambient motion (reduced motion is the
  opt-out).
