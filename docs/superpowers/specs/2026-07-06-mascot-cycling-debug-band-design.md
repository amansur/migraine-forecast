# Mascot Cycling, Per-Mascot Wiggle & Debug Band Override — Design

Date: 2026-07-06
Builds on: `docs/superpowers/specs/2026-07-06-icon-mascots-design.md` (pooled PNG mascots, daily-seeded per band)

## Goal

1. **User-facing:** tap the Today-screen mascot to cycle through the current band's mascot pool — a today-only choice.
2. **User-facing:** each mascot has its own wiggle personality.
3. **Debug-only:** a Developer section in Settings to override the displayed risk band, so all bands' mascots can be tested without real weather conditions.

## Feature 1: Tap-to-cycle mascot (today-only)

### Selection

`mascotAssetFor` in `lib/state/mascot_pool.dart` gains an offset:

```dart
String mascotAssetFor(RiskBand band, {DateTime? date, int offset = 0}) {
  ...
  return pool[(seed + offset) % pool.length];
}
```

Seed logic stays isolated in this one function; behavior is unchanged for `offset = 0`.

### State

New in-memory Riverpod provider (no persistence — the choice resets on app restart or the next calendar day):

```dart
/// (dateKey e.g. '2026-07-06', band, offset). Null = daily pick.
final mascotCycleProvider =
    StateProvider<({String dateKey, RiskBand band, int offset})?>((_) => null);
```

The offset applies only when the stored `dateKey` equals today's local date AND the stored band equals the band being rendered; otherwise it is ignored (treated as 0). Stale state does not need eager cleanup — it is simply inert.

### Today screen

- Tap on `Key('mascot-tap-target')`: read current state; if it matches (today, current band) increment `offset`, else start fresh at `offset = 1`. Then play the wiggle via the existing `MascotController` (unchanged tap feedback).
- `MascotWidget` gains `int cycleOffset = 0`, passed through to `mascotAssetFor`. TodayScreen passes the resolved offset; all other callers (onboarding, settings) keep the default 0.
- The existing `AnimatedSwitcher` + `ValueKey(assetPath)` in `MascotWidget` provides the cross-fade when the asset changes; the wiggle plays on top. No new animation plumbing.

## Feature 2: Per-mascot wiggle personality

In `lib/state/mascot_pool.dart` (next to the pool so mapping lives with the roster):

```dart
enum WiggleStyle { squish, flutter, stretch, bob }

/// Keyed by icon name (the asset filename stem). Unmapped icons → squish.
const Map<String, WiggleStyle> kMascotWiggle = {
  'butterfly': WiggleStyle.flutter,
  'fish': WiggleStyle.flutter,
  'big_star': WiggleStyle.flutter,
  'snail': WiggleStyle.stretch,
  'sprout': WiggleStyle.stretch,
  'cat': WiggleStyle.stretch,
  'sleepy_cloud': WiggleStyle.bob,
  'raining_cloud': WiggleStyle.bob,
  'teacup': WiggleStyle.bob,
  // squish (default): sun, small_flower, berry_pot, notebook,
  // potted_plant, sad_flower
};

WiggleStyle wiggleStyleFor(String assetPath); // stem lookup, default squish
```

`MascotWidget` resolves the style from the asset it is currently rendering when a wiggle one-shot plays, and switches the transform math:

- **squish** — current behavior: horizontal squish (scaleX up / scaleY down), amplitude 0.18, single pulse.
- **flutter** — fast small rotation flicks: ~3 sine oscillations of ±4° over the action, no squish.
- **stretch** — vertical stretch-and-settle: scaleY up / scaleX down (inverse of squish), amplitude ~0.15, action duration ~650ms instead of 500ms.
- **bob** — vertical dip: translate down ~6px and back with a slight squash (~0.08), no rotation.

All are parameter/curve changes inside the existing one-shot `_action` controller — no new controllers. Wave is unchanged and shared. Reduced motion continues to skip to the end state (t = 1 ⇒ all styles resolve to identity). `onWiggle` still fires on completion regardless of style.

## Feature 3: Debug band override

New in-memory provider:

```dart
/// Debug-only presentation override for the displayed risk band. Null = auto.
final debugBandOverrideProvider = StateProvider<RiskBand?>((_) => null);
```

- **Today screen:** computes `final band = debugOverride ?? a.band` and uses it for every band-driven visual it renders (mascot, band colors/copy that read `a.band`). The underlying `RiskAssessment` (score, persistence, history) is never modified — presentation-only.
- **Settings:** a **Developer** section at the bottom of Settings, wrapped in `if (kDebugMode)` so it cannot appear in release builds. One row, key `Key('debug-band-override-row')`, with a selector: Auto / Low / Moderate / High / Very High writing to the provider.
- The override is in-memory only; restart returns to Auto.

## Testing

- `mascot_pool_test.dart`: offset wraps around the pool (`offset = poolLength` ≡ `offset = 0`); `offset = 0` matches current picks; `wiggleStyleFor` returns mapped styles and defaults to squish for unknown names.
- `mascot_widget_test.dart`: each `WiggleStyle` plays to completion without error and fires `onWiggle`; `cycleOffset` changes the rendered asset within the same band.
- `today_screen_mascot_test.dart`: tapping the mascot changes the displayed asset to another member of the same band's pool; a second tap advances again; override provider set → mascot renders the overridden band's asset.
- Settings test: Developer section present in test/debug mode (tests run with asserts on ⇒ `kDebugMode` true under `flutter test`), selector writes the provider.

## Out of scope

- Persisting the cycle choice across restarts.
- Per-mascot idle or wave variations.
- Release-build access to the band override.
