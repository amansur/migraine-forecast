# Mascot Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the CustomPainter "green blob" mascot with hand-crafted multi-color SVG characters (flower / kitty / bunny / bee), each evolving across the four risk bands, user-selectable via a picker; keep the face painter + animations; fix the alcohol "units" label.

**Architecture:** The mascot becomes a `Stack` of an SVG body (`SvgPicture.asset`, one of 16 assets resolved from `(MascotCharacter, RiskBand)`) plus the existing canvas face overlay (`MascotFacePainter`, extracted from `BlobPainter`). The chosen character is persisted in the existing `SettingsRepo` and exposed through a Riverpod `mascotCharacterProvider`, so a bottom-sheet picker can update it live. `MascotController` (one-shot wiggle/wave/blink) is retained and continues to live in `mascot_widget.dart` so all current importers compile unchanged.

**Tech Stack:** Flutter, Dart, Riverpod, drift (settings), `flutter_svg` (new), `CustomPainter` (face), `flutter_test` (unit + widget + golden).

## Global Constraints

- No `colorFilter` on SVGs — each SVG carries its own colors (multi-color strategy).
- App sage body color is `#8FAF8A`; pink inner-ear `#F2B8C6`; bee yellow `#F5C842`, black `#2C2C2C`; wing `#DCEAF5`; face ink `#2E3A2E`.
- Every SVG uses `viewBox="0 0 100 100"` and keeps the central 65% (x,y ∈ 17.5..82.5) free of decorative features so the face overlay never collides; only the body fill may sit under the face.
- Default character is `kitty`.
- Flutter test command form: `flutter test test/path/to/test.dart -r expanded`.
- Reduced-motion (`MediaQuery.disableAnimations`) must be honoured exactly as today (idle loop stops, one-shot actions jump to final state).
- Do not break existing public `MascotWidget` fields `band` and `size` (existing tests read them).

---

### Task 1: Fix alcohol "units" label

**Files:**
- Modify: `packages/domain/lib/src/modules/alcohol.dart`
- Test: `packages/domain/test/modules/alcohol_module_test.dart` (if present) — otherwise no test change required; verified by `flutter test` in the domain package.

**Interfaces:**
- Consumes: nothing.
- Produces: nothing (string-only change).

- [ ] **Step 1: Change the explanation string**
In `packages/domain/lib/src/modules/alcohol.dart`, line ~69, change:
```dart
      explanation: '${totalUnits.toStringAsFixed(1)} units in last ${lookback.inHours}h',
```
to:
```dart
      explanation: '${totalUnits.toStringAsFixed(1)} alcohol units in last ${lookback.inHours}h',
```

- [ ] **Step 2: Check for an existing assertion on the old string**
Run:
```bash
grep -rn "units in last" packages/domain/test packages/domain/lib /Users/amansur/projects/migraine-forecast/test
```
If any test asserts the literal `'... units in last ...'` without `alcohol`, update that expected string to include `alcohol units`.

- [ ] **Step 3: Run domain tests**
Run: `cd packages/domain && flutter test -r expanded`
Expected: all pass (no analyzer errors, alcohol module tests green).

- [ ] **Step 4: Commit**
```bash
git add packages/domain/lib/src/modules/alcohol.dart
git commit -m "fix(domain): clarify alcohol trigger explanation says 'alcohol units'"
```

---

### Task 2: Add flutter_svg dependency + register asset directory

**Files:**
- Modify: `pubspec.yaml`
- Create (empty placeholder until Task 4): `assets/mascots/.gitkeep`

**Interfaces:**
- Consumes: nothing.
- Produces: `package:flutter_svg/flutter_svg.dart` available; `assets/mascots/` registered so `SvgPicture.asset('assets/mascots/...')` and `rootBundle` resolve in app and tests.

- [ ] **Step 1: Add the dependency**
In `pubspec.yaml`, under `dependencies:` (after `intl: ^0.19.0` is fine), add:
```yaml
  flutter_svg: ^2.0.17
```

- [ ] **Step 2: Register the asset directory**
In `pubspec.yaml`, under `flutter: assets:`, add a line so the block reads:
```yaml
  assets:
    - assets/rules_config_v1.json
    - assets/mascots/
    - test/data/sources/fixtures/open_meteo/
```

- [ ] **Step 3: Create the directory so pub resolves it**
```bash
mkdir -p /Users/amansur/projects/migraine-forecast/assets/mascots
touch /Users/amansur/projects/migraine-forecast/assets/mascots/.gitkeep
```

- [ ] **Step 4: Fetch packages**
Run: `flutter pub get`
Expected: resolves `flutter_svg ^2.0.17` with no version conflicts; exits 0.

- [ ] **Step 5: Commit**
```bash
git add pubspec.yaml pubspec.lock assets/mascots/.gitkeep
git commit -m "build: add flutter_svg and register assets/mascots/"
```

---

### Task 3: MascotCharacter enum + asset resolver

**Files:**
- Create: `lib/ui/shared/mascot/mascot_character.dart`
- Test: `test/ui/shared/mascot/mascot_character_test.dart`

**Interfaces:**
- Produces:
  - `enum MascotCharacter { flower, kitty, bunny, bee }`
  - `String mascotAssetPath(MascotCharacter character, RiskBand band)` → `'assets/mascots/<character>_<band>.svg'`
  - `List<String> allMascotAssetPaths()` → all 16 paths (used by precaching + picker).
  - `const MascotCharacter kDefaultMascotCharacter = MascotCharacter.kitty;`

- [ ] **Step 1: Write the test first (red)**
Create `test/ui/shared/mascot/mascot_character_test.dart`:
```dart
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/ui/shared/mascot/mascot_character.dart';

void main() {
  test('asset path is character_band.svg under assets/mascots', () {
    expect(
      mascotAssetPath(MascotCharacter.bee, RiskBand.veryHigh),
      'assets/mascots/bee_veryHigh.svg',
    );
    expect(
      mascotAssetPath(MascotCharacter.flower, RiskBand.low),
      'assets/mascots/flower_low.svg',
    );
  });

  test('allMascotAssetPaths has 16 unique entries', () {
    final paths = allMascotAssetPaths();
    expect(paths.length, 16);
    expect(paths.toSet().length, 16);
    expect(paths, contains('assets/mascots/kitty_moderate.svg'));
  });

  test('default character is kitty', () {
    expect(kDefaultMascotCharacter, MascotCharacter.kitty);
  });
}
```

- [ ] **Step 2: Implement the enum + resolver (green)**
Create `lib/ui/shared/mascot/mascot_character.dart`:
```dart
import 'package:domain/domain.dart';

/// The four selectable mascot characters. Each has 4 SVG variants, one per
/// [RiskBand], living at `assets/mascots/<character>_<band>.svg`.
enum MascotCharacter { flower, kitty, bunny, bee }

/// Default mascot on a fresh install.
const MascotCharacter kDefaultMascotCharacter = MascotCharacter.kitty;

/// Resolves the SVG asset path for a given character + risk band.
String mascotAssetPath(MascotCharacter character, RiskBand band) =>
    'assets/mascots/${character.name}_${band.name}.svg';

/// All 16 mascot SVG asset paths (used for startup pre-caching).
List<String> allMascotAssetPaths() => [
      for (final c in MascotCharacter.values)
        for (final b in RiskBand.values) mascotAssetPath(c, b),
    ];
```

- [ ] **Step 3: Run test**
Run: `flutter test test/ui/shared/mascot/mascot_character_test.dart -r expanded`
Expected: 3 tests pass.

- [ ] **Step 4: Commit**
```bash
git add lib/ui/shared/mascot/mascot_character.dart test/ui/shared/mascot/mascot_character_test.dart
git commit -m "feat(mascot): add MascotCharacter enum + asset path resolver"
```

---

### Task 4: Write the 16 SVG assets

**Files:**
- Create: `assets/mascots/flower_low.svg`, `flower_moderate.svg`, `flower_high.svg`, `flower_veryHigh.svg`
- Create: `assets/mascots/kitty_low.svg`, `kitty_moderate.svg`, `kitty_high.svg`, `kitty_veryHigh.svg`
- Create: `assets/mascots/bunny_low.svg`, `bunny_moderate.svg`, `bunny_high.svg`, `bunny_veryHigh.svg`
- Create: `assets/mascots/bee_low.svg`, `bee_moderate.svg`, `bee_high.svg`, `bee_veryHigh.svg`
- Test: `test/ui/shared/mascot/mascot_assets_test.dart`

**Interfaces:**
- Consumes: asset directory from Task 2; paths from Task 3.
- Produces: 16 valid SVG files (each a body + character features, center 65% clear). Verified loadable by `flutter_svg` + present in the bundle.

Each character's body is centred so the face overlay (eyes ~y45, mouth ~y64) draws cleanly on top. Decorative features (petals/ears/wings/antennae) sit in the outer margins.

- [ ] **Step 1: Write the flower SVGs**

`assets/mascots/flower_low.svg`:
```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
  <g fill="#8FAF8A">
    <ellipse cx="50" cy="20" rx="11" ry="20"/>
    <ellipse cx="78" cy="40" rx="11" ry="20" transform="rotate(72 78 40)"/>
    <ellipse cx="67" cy="74" rx="11" ry="20" transform="rotate(144 67 74)"/>
    <ellipse cx="33" cy="74" rx="11" ry="20" transform="rotate(216 33 74)"/>
    <ellipse cx="22" cy="40" rx="11" ry="20" transform="rotate(288 22 40)"/>
  </g>
  <circle cx="50" cy="50" r="25" fill="#F5C842"/>
</svg>
```

`assets/mascots/flower_moderate.svg`:
```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
  <g fill="#8FAF8A">
    <ellipse cx="50" cy="24" rx="10" ry="16"/>
    <ellipse cx="74" cy="42" rx="10" ry="16" transform="rotate(72 74 42)"/>
    <ellipse cx="64" cy="71" rx="10" ry="16" transform="rotate(144 64 71)"/>
    <ellipse cx="36" cy="71" rx="10" ry="16" transform="rotate(216 36 71)"/>
    <ellipse cx="26" cy="42" rx="10" ry="16" transform="rotate(288 26 42)"/>
  </g>
  <circle cx="50" cy="50" r="25" fill="#F5C842"/>
</svg>
```

`assets/mascots/flower_high.svg`:
```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
  <g fill="#8FAF8A">
    <ellipse cx="50" cy="30" rx="9" ry="13"/>
    <ellipse cx="72" cy="48" rx="9" ry="13" transform="rotate(80 72 48)"/>
    <ellipse cx="64" cy="78" rx="9" ry="14" transform="rotate(150 64 78)"/>
    <ellipse cx="36" cy="78" rx="9" ry="14" transform="rotate(210 36 78)"/>
    <ellipse cx="28" cy="48" rx="9" ry="13" transform="rotate(280 28 48)"/>
  </g>
  <circle cx="50" cy="50" r="25" fill="#F5C842"/>
</svg>
```

`assets/mascots/flower_veryHigh.svg`:
```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
  <g fill="#8FAF8A">
    <ellipse cx="50" cy="34" rx="7" ry="10"/>
    <ellipse cx="70" cy="54" rx="7" ry="11" transform="rotate(95 70 54)"/>
    <ellipse cx="62" cy="80" rx="7" ry="12" transform="rotate(160 62 80)"/>
    <ellipse cx="38" cy="80" rx="7" ry="12" transform="rotate(200 38 80)"/>
    <ellipse cx="30" cy="54" rx="7" ry="11" transform="rotate(265 30 54)"/>
  </g>
  <circle cx="50" cy="50" r="25" fill="#F5C842"/>
</svg>
```

- [ ] **Step 2: Write the kitty SVGs** (tail drawn first/behind, body circle drawn last so ear bases tuck under it)

`assets/mascots/kitty_low.svg`:
```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
  <path d="M82 68 Q96 58 90 40" fill="none" stroke="#8FAF8A" stroke-width="7" stroke-linecap="round"/>
  <polygon points="30,26 22,4 44,20" fill="#8FAF8A"/>
  <polygon points="70,26 78,4 56,20" fill="#8FAF8A"/>
  <polygon points="31,22 26,10 40,19" fill="#F2B8C6"/>
  <polygon points="69,22 74,10 60,19" fill="#F2B8C6"/>
  <circle cx="50" cy="55" r="33" fill="#8FAF8A"/>
</svg>
```

`assets/mascots/kitty_moderate.svg`:
```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
  <path d="M82 70 Q94 66 92 54" fill="none" stroke="#8FAF8A" stroke-width="7" stroke-linecap="round"/>
  <polygon points="30,26 16,9 44,20" fill="#8FAF8A"/>
  <polygon points="70,26 84,9 56,20" fill="#8FAF8A"/>
  <polygon points="31,23 22,13 40,19" fill="#F2B8C6"/>
  <polygon points="69,23 78,13 60,19" fill="#F2B8C6"/>
  <circle cx="50" cy="55" r="33" fill="#8FAF8A"/>
</svg>
```

`assets/mascots/kitty_high.svg`:
```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
  <path d="M80 80 Q90 82 86 70" fill="none" stroke="#8FAF8A" stroke-width="7" stroke-linecap="round"/>
  <polygon points="28,24 8,16 44,22" fill="#8FAF8A"/>
  <polygon points="72,24 92,16 56,22" fill="#8FAF8A"/>
  <polygon points="30,23 14,18 40,21" fill="#F2B8C6"/>
  <polygon points="70,23 86,18 60,21" fill="#F2B8C6"/>
  <circle cx="50" cy="55" r="33" fill="#8FAF8A"/>
</svg>
```

`assets/mascots/kitty_veryHigh.svg`:
```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
  <path d="M80 82 Q86 90 78 84" fill="none" stroke="#8FAF8A" stroke-width="7" stroke-linecap="round"/>
  <polygon points="28,28 6,30 44,24" fill="#8FAF8A"/>
  <polygon points="72,28 94,30 56,24" fill="#8FAF8A"/>
  <polygon points="30,26 13,28 40,23" fill="#F2B8C6"/>
  <polygon points="70,26 87,28 60,23" fill="#F2B8C6"/>
  <circle cx="50" cy="55" r="33" fill="#8FAF8A"/>
</svg>
```

- [ ] **Step 3: Write the bunny SVGs** (ear groups rotate about their base; body drawn last)

`assets/mascots/bunny_low.svg`:
```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
  <g>
    <ellipse cx="40" cy="22" rx="7" ry="20" fill="#8FAF8A"/>
    <ellipse cx="40" cy="23" rx="3.4" ry="14" fill="#F2B8C6"/>
  </g>
  <g>
    <ellipse cx="60" cy="22" rx="7" ry="20" fill="#8FAF8A"/>
    <ellipse cx="60" cy="23" rx="3.4" ry="14" fill="#F2B8C6"/>
  </g>
  <circle cx="50" cy="58" r="32" fill="#8FAF8A"/>
</svg>
```

`assets/mascots/bunny_moderate.svg`:
```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
  <g transform="rotate(-25 40 40)">
    <ellipse cx="40" cy="22" rx="7" ry="20" fill="#8FAF8A"/>
    <ellipse cx="40" cy="23" rx="3.4" ry="14" fill="#F2B8C6"/>
  </g>
  <g transform="rotate(25 60 40)">
    <ellipse cx="60" cy="22" rx="7" ry="20" fill="#8FAF8A"/>
    <ellipse cx="60" cy="23" rx="3.4" ry="14" fill="#F2B8C6"/>
  </g>
  <circle cx="50" cy="58" r="32" fill="#8FAF8A"/>
</svg>
```

`assets/mascots/bunny_high.svg`:
```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
  <g transform="rotate(-65 40 42)">
    <ellipse cx="40" cy="22" rx="7" ry="20" fill="#8FAF8A"/>
    <ellipse cx="40" cy="23" rx="3.4" ry="14" fill="#F2B8C6"/>
  </g>
  <g transform="rotate(65 60 42)">
    <ellipse cx="60" cy="22" rx="7" ry="20" fill="#8FAF8A"/>
    <ellipse cx="60" cy="23" rx="3.4" ry="14" fill="#F2B8C6"/>
  </g>
  <circle cx="50" cy="58" r="32" fill="#8FAF8A"/>
</svg>
```

`assets/mascots/bunny_veryHigh.svg`:
```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
  <g transform="rotate(-120 42 44)">
    <ellipse cx="40" cy="22" rx="7" ry="20" fill="#8FAF8A"/>
    <ellipse cx="40" cy="23" rx="3.4" ry="14" fill="#F2B8C6"/>
  </g>
  <g transform="rotate(120 58 44)">
    <ellipse cx="60" cy="22" rx="7" ry="20" fill="#8FAF8A"/>
    <ellipse cx="60" cy="23" rx="3.4" ry="14" fill="#F2B8C6"/>
  </g>
  <circle cx="50" cy="58" r="32" fill="#8FAF8A"/>
</svg>
```

- [ ] **Step 4: Write the bee SVGs** (wings behind body; stripes clipped to body lower area, below the face; antennae on top; sweat for veryHigh is supplied by the face painter, not the SVG)

`assets/mascots/bee_low.svg`:
```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
  <g fill="#DCEAF5" fill-opacity="0.75" stroke="#9DB6C7" stroke-width="1.5">
    <ellipse cx="20" cy="42" rx="14" ry="20" transform="rotate(-25 20 42)"/>
    <ellipse cx="80" cy="42" rx="14" ry="20" transform="rotate(25 80 42)"/>
  </g>
  <ellipse cx="50" cy="56" rx="28" ry="30" fill="#F5C842"/>
  <clipPath id="bee-low"><ellipse cx="50" cy="56" rx="28" ry="30"/></clipPath>
  <g clip-path="url(#bee-low)" fill="#2C2C2C">
    <rect x="15" y="72" width="70" height="7"/>
    <rect x="15" y="84" width="70" height="7"/>
  </g>
  <g fill="none" stroke="#2C2C2C" stroke-width="2.4" stroke-linecap="round">
    <path d="M42 30 Q38 16 38 8"/>
    <path d="M58 30 Q62 16 62 8"/>
  </g>
  <circle cx="38" cy="8" r="3.2" fill="#2C2C2C"/>
  <circle cx="62" cy="8" r="3.2" fill="#2C2C2C"/>
</svg>
```

`assets/mascots/bee_moderate.svg`:
```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
  <g fill="#DCEAF5" fill-opacity="0.75" stroke="#9DB6C7" stroke-width="1.5">
    <ellipse cx="20" cy="48" rx="13" ry="18" transform="rotate(-12 20 48)"/>
    <ellipse cx="80" cy="48" rx="13" ry="18" transform="rotate(12 80 48)"/>
  </g>
  <ellipse cx="50" cy="56" rx="28" ry="30" fill="#F5C842"/>
  <clipPath id="bee-mod"><ellipse cx="50" cy="56" rx="28" ry="30"/></clipPath>
  <g clip-path="url(#bee-mod)" fill="#2C2C2C">
    <rect x="15" y="72" width="70" height="7"/>
    <rect x="15" y="84" width="70" height="7"/>
  </g>
  <g fill="none" stroke="#2C2C2C" stroke-width="2.4" stroke-linecap="round">
    <path d="M42 30 Q36 18 42 12"/>
    <path d="M58 30 Q64 18 58 12"/>
  </g>
  <circle cx="42" cy="12" r="3.2" fill="#2C2C2C"/>
  <circle cx="58" cy="12" r="3.2" fill="#2C2C2C"/>
</svg>
```

`assets/mascots/bee_high.svg`:
```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
  <g fill="#DCEAF5" fill-opacity="0.7" stroke="#9DB6C7" stroke-width="1.5">
    <ellipse cx="26" cy="52" rx="10" ry="15" transform="rotate(12 26 52)"/>
    <ellipse cx="74" cy="52" rx="10" ry="15" transform="rotate(-12 74 52)"/>
  </g>
  <ellipse cx="50" cy="56" rx="28" ry="30" fill="#F5C842"/>
  <clipPath id="bee-high"><ellipse cx="50" cy="56" rx="28" ry="30"/></clipPath>
  <g clip-path="url(#bee-high)" fill="#2C2C2C">
    <rect x="15" y="72" width="70" height="7"/>
    <rect x="15" y="84" width="70" height="7"/>
  </g>
  <g fill="none" stroke="#2C2C2C" stroke-width="2.4" stroke-linecap="round">
    <path d="M42 30 Q36 24 32 20"/>
    <path d="M58 30 Q64 24 68 20"/>
  </g>
  <circle cx="32" cy="20" r="3.2" fill="#2C2C2C"/>
  <circle cx="68" cy="20" r="3.2" fill="#2C2C2C"/>
</svg>
```

`assets/mascots/bee_veryHigh.svg`:
```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
  <g fill="#DCEAF5" fill-opacity="0.7" stroke="#9DB6C7" stroke-width="1.5">
    <ellipse cx="24" cy="60" rx="10" ry="16" transform="rotate(38 24 60)"/>
    <ellipse cx="76" cy="60" rx="10" ry="16" transform="rotate(-38 76 60)"/>
  </g>
  <ellipse cx="50" cy="56" rx="28" ry="30" fill="#F5C842"/>
  <clipPath id="bee-vh"><ellipse cx="50" cy="56" rx="28" ry="30"/></clipPath>
  <g clip-path="url(#bee-vh)" fill="#2C2C2C">
    <rect x="15" y="72" width="70" height="7"/>
    <rect x="15" y="84" width="70" height="7"/>
  </g>
  <g fill="none" stroke="#2C2C2C" stroke-width="2.4" stroke-linecap="round">
    <path d="M42 30 Q34 28 30 32"/>
    <path d="M58 30 Q66 28 70 32"/>
  </g>
  <circle cx="30" cy="32" r="3.2" fill="#2C2C2C"/>
  <circle cx="70" cy="32" r="3.2" fill="#2C2C2C"/>
</svg>
```

- [ ] **Step 5: Write the asset-loadability test**
Create `test/ui/shared/mascot/mascot_assets_test.dart`:
```dart
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/ui/shared/mascot/mascot_character.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every mascot SVG is present in the bundle and parses', () async {
    for (final path in allMascotAssetPaths()) {
      final raw = await rootBundle.loadString(path);
      expect(raw.contains('<svg'), isTrue, reason: '$path missing <svg>');
      // Throws if the SVG is malformed.
      await vg.loadPicture(SvgStringLoader(raw), null);
    }
  });
}
```

- [ ] **Step 6: Run test**
Run: `flutter test test/ui/shared/mascot/mascot_assets_test.dart -r expanded`
Expected: passes — all 16 SVGs load and parse. (If it fails with "Unable to load asset", re-run `flutter pub get` so the new files are picked up by the asset manifest.)

- [ ] **Step 7: Commit**
```bash
git rm --cached assets/mascots/.gitkeep 2>/dev/null || true
rm -f assets/mascots/.gitkeep
git add assets/mascots/ test/ui/shared/mascot/mascot_assets_test.dart
git commit -m "feat(mascot): add 16 kawaii SVG character assets (flower/kitty/bunny/bee x 4 bands)"
```

---

### Task 5: Extract MascotFacePainter (rename blob_painter, delete accessories)

**Files:**
- Create: `lib/ui/shared/mascot/mascot_face_painter.dart`
- Delete: `lib/ui/shared/mascot/blob_painter.dart`
- Delete: `lib/ui/shared/mascot/mascot_accessories.dart`
- Create (replaces the old blob_painter test): `test/ui/shared/mascot/mascot_face_painter_test.dart`
- Delete: `test/ui/shared/mascot/blob_painter_test.dart`

**Interfaces:**
- Consumes: `RiskBand` from `package:domain/domain.dart`.
- Produces:
  - `class MascotFace` with `browAngle, mouthOpen, blush, sweat`, `MascotFace.forBand(RiskBand)`, `MascotFace.lerp(a,b,t)` (unchanged from current `blob_painter.dart`).
  - `class MascotFacePainter extends CustomPainter` with constructor `MascotFacePainter({required MascotFace face, double eyeOpen = 1.0})`. No `BlobShape`, no `color`, no `squish` (wiggle now lives on the outer widget transform).

> Note: `BlobShape` and `BlobPainter` are removed entirely. The body is now the SVG.

- [ ] **Step 1: Create `mascot_face_painter.dart`**
```dart
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

/// Facial expression parameters, all 0..1 so they interpolate cleanly.
class MascotFace {
  /// 0 = flat happy brow, 1 = steep worried brow.
  final double browAngle;

  /// 0 = closed smile, 1 = wide open mouth.
  final double mouthOpen;

  /// 0 = no cheek blush, 1 = full rosy/flushed cheeks.
  final double blush;

  /// Whether a small sweat drop is shown.
  final bool sweat;

  const MascotFace({
    required this.browAngle,
    required this.mouthOpen,
    required this.blush,
    required this.sweat,
  });

  static MascotFace forBand(RiskBand band) {
    switch (band) {
      case RiskBand.low:
        return const MascotFace(browAngle: 0.0, mouthOpen: 0.15, blush: 0.6, sweat: false);
      case RiskBand.moderate:
        return const MascotFace(browAngle: 0.2, mouthOpen: 0.1, blush: 0.2, sweat: false);
      case RiskBand.high:
        return const MascotFace(browAngle: 0.7, mouthOpen: 0.2, blush: 0.1, sweat: true);
      case RiskBand.veryHigh:
        return const MascotFace(browAngle: 1.0, mouthOpen: 0.8, blush: 0.9, sweat: true);
    }
  }

  static MascotFace lerp(MascotFace a, MascotFace b, double t) => MascotFace(
        browAngle: ui.lerpDouble(a.browAngle, b.browAngle, t)!,
        mouthOpen: ui.lerpDouble(a.mouthOpen, b.mouthOpen, t)!,
        blush: ui.lerpDouble(a.blush, b.blush, t)!,
        sweat: t < 0.5 ? a.sweat : b.sweat,
      );
}

/// Paints just the kawaii face (eyes, brow, blush, mouth, sweat) centred in the
/// given [Size]. The body is now an SVG drawn beneath this painter, so this
/// painter no longer draws a blob or applies a body tint.
class MascotFacePainter extends CustomPainter {
  final MascotFace face;

  /// Eye openness for blink: 1 = fully open, 0 = closed line.
  final double eyeOpen;

  MascotFacePainter({required this.face, this.eyeOpen = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = math.min(size.width, size.height) / 2;
    final rx = r;
    final ry = r;

    final eyeDx = rx * 0.28;
    final eyeY = c.dy - ry * 0.10;
    final eyeR = rx * 0.14;
    const eyeColor = Color(0xFF2E3A2E);

    for (final sign in [-1.0, 1.0]) {
      final center = Offset(c.dx + sign * eyeDx, eyeY);
      if (eyeOpen <= 0.05) {
        final p = Paint()
          ..color = eyeColor
          ..strokeWidth = eyeR * 0.8
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          Offset(center.dx - eyeR, center.dy),
          Offset(center.dx + eyeR, center.dy),
          p,
        );
      } else {
        canvas.drawOval(
          Rect.fromCenter(
            center: center,
            width: eyeR * 2,
            height: eyeR * 2.2 * eyeOpen,
          ),
          Paint()..color = eyeColor,
        );
        canvas.drawCircle(
          Offset(center.dx + eyeR * 0.32, center.dy - eyeR * 0.38),
          eyeR * 0.38,
          Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.9),
        );
      }
    }

    if (face.browAngle > 0.05) {
      final browPaint = Paint()
        ..color = eyeColor
        ..strokeWidth = rx * 0.05
        ..strokeCap = StrokeCap.round;
      final lift = ry * 0.18 * face.browAngle;
      final browY = eyeY - eyeR * 1.8;
      for (final sign in [-1.0, 1.0]) {
        final inner = Offset(c.dx + sign * eyeDx * 0.5, browY - lift);
        final outer = Offset(c.dx + sign * eyeDx * 1.4, browY);
        canvas.drawLine(inner, outer, browPaint);
      }
    }

    if (face.blush > 0.05) {
      final blushPaint = Paint()..color = const Color(0xFFD89B7A).withValues(alpha: 0.5 * face.blush);
      for (final sign in [-1.0, 1.0]) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(c.dx + sign * eyeDx * 1.25, eyeY + ry * 0.16),
            width: rx * 0.28,
            height: ry * 0.18,
          ),
          blushPaint,
        );
      }
    }

    final mouthY = c.dy + ry * 0.28;
    final mouthPaint = Paint()
      ..color = eyeColor
      ..style = face.mouthOpen > 0.4 ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = rx * 0.045
      ..strokeCap = StrokeCap.round;
    if (face.mouthOpen > 0.4) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(c.dx, mouthY), width: rx * 0.3, height: ry * 0.32 * face.mouthOpen),
        mouthPaint,
      );
    } else {
      final mouth = Path()
        ..moveTo(c.dx - rx * 0.18, mouthY)
        ..quadraticBezierTo(c.dx, mouthY + ry * 0.14, c.dx + rx * 0.18, mouthY);
      canvas.drawPath(mouth, mouthPaint);
    }

    if (face.sweat) {
      final dropPaint = Paint()..color = const Color(0xFF6FA8DC).withValues(alpha: 0.8);
      final dropCenter = Offset(c.dx + eyeDx * 1.6, eyeY - ry * 0.05);
      final drop = Path()
        ..moveTo(dropCenter.dx, dropCenter.dy - ry * 0.1)
        ..quadraticBezierTo(dropCenter.dx + rx * 0.08, dropCenter.dy, dropCenter.dx, dropCenter.dy + ry * 0.04)
        ..quadraticBezierTo(dropCenter.dx - rx * 0.08, dropCenter.dy, dropCenter.dx, dropCenter.dy - ry * 0.1)
        ..close();
      canvas.drawPath(drop, dropPaint);
    }
  }

  @override
  bool shouldRepaint(covariant MascotFacePainter old) =>
      old.face.browAngle != face.browAngle ||
      old.face.mouthOpen != face.mouthOpen ||
      old.face.blush != face.blush ||
      old.face.sweat != face.sweat ||
      old.eyeOpen != eyeOpen;
}
```

- [ ] **Step 2: Delete the old painters**
```bash
git rm lib/ui/shared/mascot/blob_painter.dart lib/ui/shared/mascot/mascot_accessories.dart
git rm test/ui/shared/mascot/blob_painter_test.dart
```

- [ ] **Step 3: Write the new face painter test**
Create `test/ui/shared/mascot/mascot_face_painter_test.dart`:
```dart
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/ui/shared/mascot/mascot_face_painter.dart';

void main() {
  for (final band in RiskBand.values) {
    testWidgets('MascotFacePainter paints for $band', (tester) async {
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: SizedBox(width: 160, height: 160),
          ),
        ),
      );
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: SizedBox(
                width: 160,
                height: 160,
                child: CustomPaint(
                  painter: MascotFacePainter(face: MascotFace.forBand(band)),
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.byType(CustomPaint), findsWidgets);
    });
  }

  test('MascotFace.lerp switches sweat at midpoint', () {
    final calm = MascotFace.forBand(RiskBand.low); // sweat false
    final worried = MascotFace.forBand(RiskBand.high); // sweat true
    expect(MascotFace.lerp(calm, worried, 0.49).sweat, isFalse);
    expect(MascotFace.lerp(calm, worried, 0.51).sweat, isTrue);
  });

  test('MascotFacePainter.shouldRepaint reacts to eyeOpen change', () {
    final open = MascotFacePainter(face: MascotFace.forBand(RiskBand.low));
    final closed = MascotFacePainter(face: MascotFace.forBand(RiskBand.low), eyeOpen: 0.0);
    expect(closed.shouldRepaint(open), isTrue);
  });
}
```

- [ ] **Step 4: Run test (will fail to compile until Task 6 fixes mascot_widget.dart imports — expected)**
Run: `flutter test test/ui/shared/mascot/mascot_face_painter_test.dart -r expanded`
Expected: the face-painter test itself passes; but a project-wide compile may still fail because `mascot_widget.dart` still imports the deleted files. That is fixed in Task 6. If you run only this file it should compile (it does not import `mascot_widget.dart`). Proceed to Task 6 before running the full suite.

- [ ] **Step 5: Commit**
```bash
git add lib/ui/shared/mascot/mascot_face_painter.dart test/ui/shared/mascot/mascot_face_painter_test.dart
git commit -m "refactor(mascot): extract MascotFacePainter; delete BlobPainter + accessories"
```

---

### Task 6: Rebuild MascotWidget (SVG body + face + animations + precaching)

**Files:**
- Modify (full rewrite): `lib/ui/shared/mascot/mascot_widget.dart`
- Modify: `lib/main.dart` (precache SVGs at startup)
- Test: `test/ui/shared/mascot/mascot_widget_test.dart` (rewritten in Task 9)

**Interfaces:**
- Consumes: `MascotFace`, `MascotFacePainter` (Task 5); `MascotCharacter`, `mascotAssetPath`, `kDefaultMascotCharacter`, `allMascotAssetPaths` (Task 3).
- Produces:
  - `enum MascotAction { wiggle, wave, blink }` (unchanged, still here).
  - `class MascotController extends ChangeNotifier` with `wiggle()`, `wave()`, `blink()`, `pending`, `ackConsumed()` (unchanged, still here so existing importers compile).
  - `class MascotWidget extends StatefulWidget` with named params: `required RiskBand band`, `MascotCharacter character = kDefaultMascotCharacter`, `double size = 160`, `MascotController? controller`, `VoidCallback? onWiggle`. Public fields `band`, `size`, `character` readable by tests.
  - `Future<void> precacheMascots()` top-level helper for `main.dart`.

> `MascotController` + `MascotAction` MUST remain declared in this file (currently imported from here by `celebration_overlay.dart`, `settings_screen.dart`, `onboarding_screen.dart`, `today_screen.dart`).

- [ ] **Step 1: Rewrite `lib/ui/shared/mascot/mascot_widget.dart`**
```dart
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'mascot_character.dart';
import 'mascot_face_painter.dart';

enum MascotAction { wiggle, wave, blink }

/// Pre-caches all 16 mascot SVGs into the flutter_svg picture cache so the first
/// render does not flash. Call once from `main()` after binding init.
Future<void> precacheMascots() async {
  for (final path in allMascotAssetPaths()) {
    final loader = SvgAssetLoader(path);
    await svg.cache.putIfAbsent(loader.cacheKey(null), () => loader.loadBytes(null));
  }
}

/// Drives one-shot mascot animations from outside the widget tree.
/// Hosts (TodayScreen, log sheets, onboarding, settings) call [wiggle],
/// [wave], or [blink]; a listening [MascotWidget] plays the matching action.
class MascotController extends ChangeNotifier {
  MascotAction? _pending;
  MascotAction? get pending => _pending;

  void wiggle() => _emit(MascotAction.wiggle);
  void wave() => _emit(MascotAction.wave);
  void blink() => _emit(MascotAction.blink);

  void _emit(MascotAction action) {
    _pending = action;
    notifyListeners();
  }

  /// Called by the widget once it has consumed the pending action.
  void ackConsumed() => _pending = null;
}

class MascotWidget extends StatefulWidget {
  final RiskBand band;
  final MascotCharacter character;
  final double size;
  final MascotController? controller;
  final VoidCallback? onWiggle;

  const MascotWidget({
    super.key,
    required this.band,
    this.character = kDefaultMascotCharacter,
    this.size = 160,
    this.controller,
    this.onWiggle,
  });

  @override
  State<MascotWidget> createState() => _MascotWidgetState();
}

class _MascotWidgetState extends State<MascotWidget>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _idle;
  late final AnimationController _action; // wiggle / wave / blink one-shots
  MascotAction _activeAction = MascotAction.wiggle;

  late MascotFace _targetFace;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _targetFace = MascotFace.forBand(widget.band);

    _idle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
    _action = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )
      ..addListener(() => setState(() {}))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          if (_activeAction == MascotAction.wiggle) widget.onWiggle?.call();
          widget.controller?.ackConsumed();
        }
      });

    widget.controller?.addListener(_onControllerAction);
    _idle.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant MascotWidget old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller?.removeListener(_onControllerAction);
      widget.controller?.addListener(_onControllerAction);
    }
    if (old.band != widget.band) {
      _targetFace = MascotFace.forBand(widget.band);
      if (widget.band.index < old.band.index) {
        _playAction(MascotAction.wiggle);
      }
    }
  }

  void _onControllerAction() {
    final pending = widget.controller?.pending;
    if (pending != null) _playAction(pending);
  }

  void _playAction(MascotAction action) {
    _activeAction = action;
    _action
      ..reset()
      ..forward();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_idle.isAnimating) _idle.repeat(reverse: true);
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _idle.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.controller?.removeListener(_onControllerAction);
    _idle.dispose();
    _action.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.of(context).disableAnimations;

    if (reduce && _idle.isAnimating) {
      _idle.stop();
    }

    // One-shot action math (instant under reduced motion -> t jumps to 1).
    final t = reduce ? 1.0 : _action.value;
    double squish = 0; // wiggle: scaleX up, scaleY down
    double eyeOpen = 1;
    double sway = 0; // wave: gentle rotation
    final playing = _action.isAnimating || (!reduce && _action.value > 0 && _action.value < 1);
    if (playing) {
      switch (_activeAction) {
        case MascotAction.wiggle:
          squish = 0.18 * (1 - (2 * t - 1).abs());
        case MascotAction.wave:
          sway = (1 - (2 * t - 1).abs());
        case MascotAction.blink:
          eyeOpen = (2 * t - 1).abs();
      }
    }

    final assetPath = mascotAssetPath(widget.character, widget.band);

    return AnimatedBuilder(
      animation: _idle,
      builder: (context, _) {
        final phase = reduce ? 0.0 : _idle.value;
        final floatY = reduce ? 0.0 : (-3.0 + 6.0 * phase);
        final breathe = reduce ? 1.0 : (1.0 + 0.015 * (phase - 0.5).abs() * 2);

        // Wave = gentle rotation (+/-5deg). Wiggle = horizontal squish.
        final rotation = sway * 0.0873; // ~5 degrees in radians
        final scaleX = breathe * (1 + squish * 0.5);
        final scaleY = breathe * (1 - squish * 0.5);

        return Transform.translate(
          offset: Offset(0, floatY),
          child: Transform.rotate(
            angle: rotation,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.diagonal3Values(scaleX, scaleY, 1),
              child: TweenAnimationBuilder<MascotFace>(
                tween: _MascotFaceTween(end: _targetFace),
                duration: reduce ? Duration.zero : const Duration(milliseconds: 600),
                curve: Curves.easeInOut,
                builder: (context, face, __) {
                  return SizedBox(
                    width: widget.size,
                    height: widget.size,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        AnimatedSwitcher(
                          duration: reduce ? Duration.zero : const Duration(milliseconds: 200),
                          child: SvgPicture.asset(
                            assetPath,
                            key: ValueKey(assetPath),
                            width: widget.size,
                            height: widget.size,
                            fit: BoxFit.contain,
                          ),
                        ),
                        CustomPaint(
                          painter: MascotFacePainter(face: face, eyeOpen: eyeOpen),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MascotFaceTween extends Tween<MascotFace> {
  _MascotFaceTween({required MascotFace end}) : super(end: end);
  @override
  MascotFace lerp(double t) => MascotFace.lerp(begin ?? end!, end!, t);
}
```

- [ ] **Step 2: Pre-cache SVGs in `main.dart`**
In `lib/main.dart`, add the import near the top:
```dart
import 'ui/shared/mascot/mascot_widget.dart';
```
Then inside `main()`, after `WidgetsFlutterBinding.ensureInitialized();` and before `runApp(...)`, add:
```dart
  try {
    await precacheMascots();
  } catch (_) {
    // Asset/codec unavailable in this environment — first frame may flash; fine.
  }
```

- [ ] **Step 3: Analyze to confirm the rename compiles app code**
Run: `flutter analyze lib`
Expected: no errors from `lib/` (test files are rewritten in Task 9; importers `today_screen.dart`, `settings_screen.dart`, `onboarding_screen.dart`, `celebration_overlay.dart` still compile because `MascotController`/`MascotAction`/`MascotWidget` remain exported from `mascot_widget.dart`).

- [ ] **Step 4: Commit**
```bash
git add lib/ui/shared/mascot/mascot_widget.dart lib/main.dart
git commit -m "feat(mascot): SVG body + face stack widget with wave/wiggle/blink + SVG precaching"
```

---

### Task 7: Settings persistence + provider for mascot character

**Files:**
- Modify: `lib/state/settings_provider.dart`
- Test: `test/state/mascot_character_provider_test.dart`

**Interfaces:**
- Consumes: `settingsRepoProvider` (in `lib/state/providers.dart`), `MascotCharacter` (Task 3).
- Produces:
  - `final mascotCharacterProvider = FutureProvider<MascotCharacter>(...)` reading key `'mascot_character'`, default `kDefaultMascotCharacter`.
  - `final setMascotCharacterProvider = Provider<Future<void> Function(MascotCharacter)>(...)` that persists then invalidates `mascotCharacterProvider`.

- [ ] **Step 1: Add imports + providers in `settings_provider.dart`**
At the top of `lib/state/settings_provider.dart`, add:
```dart
import '../ui/shared/mascot/mascot_character.dart';
```
At the bottom of the file, add:
```dart
final mascotCharacterProvider = FutureProvider<MascotCharacter>((ref) async {
  final s = await ref.watch(settingsRepoProvider).getString('mascot_character');
  return MascotCharacter.values.firstWhere(
    (c) => c.name == s,
    orElse: () => kDefaultMascotCharacter,
  );
});

final setMascotCharacterProvider = Provider<Future<void> Function(MascotCharacter)>((ref) {
  return (character) async {
    await ref.read(settingsRepoProvider).setString('mascot_character', character.name);
    ref.invalidate(mascotCharacterProvider);
  };
});
```
Note: `settingsRepoProvider` is declared in `lib/state/providers.dart`, which is already imported as `import 'providers.dart';` in this file — no extra import needed for it.

- [ ] **Step 2: Write the provider test**
Create `test/state/mascot_character_provider_test.dart`:
```dart
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/data/database.dart';
import 'package:migraine_forecast/data/repos/settings_repo.dart';
import 'package:migraine_forecast/state/providers.dart';
import 'package:migraine_forecast/state/settings_provider.dart';
import 'package:migraine_forecast/ui/shared/mascot/mascot_character.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    container = ProviderContainer(overrides: [
      settingsRepoProvider.overrideWithValue(SettingsRepo(db)),
    ]);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  test('defaults to kitty when unset', () async {
    final c = await container.read(mascotCharacterProvider.future);
    expect(c, MascotCharacter.kitty);
  });

  test('setter persists and re-reads as the chosen character', () async {
    await container.read(setMascotCharacterProvider)(MascotCharacter.bee);
    final c = await container.read(mascotCharacterProvider.future);
    expect(c, MascotCharacter.bee);
  });
}
```

> The in-memory constructor `AppDatabase(NativeDatabase.memory())` matches existing usage in `test/data/database_migration_test.dart`.

- [ ] **Step 3: Run test**
Run: `flutter test test/state/mascot_character_provider_test.dart -r expanded`
Expected: both tests pass.

- [ ] **Step 4: Commit**
```bash
git add lib/state/settings_provider.dart test/state/mascot_character_provider_test.dart
git commit -m "feat(mascot): persist MascotCharacter in settings + Riverpod providers"
```

---

### Task 8: Mascot picker bottom sheet

**Files:**
- Create: `lib/ui/shared/mascot/mascot_picker_sheet.dart`
- Test: `test/ui/shared/mascot/mascot_picker_sheet_test.dart`

**Interfaces:**
- Consumes: `MascotCharacter`, `mascotAssetPath` (Task 3); `mascotCharacterProvider`, `setMascotCharacterProvider` (Task 7).
- Produces:
  - `class MascotPickerSheet extends ConsumerWidget` — the sheet body (heading + 2x2 grid). Each tile keyed `Key('mascot-tile-<character.name>')`.
  - `static Future<void> MascotPickerSheet.show(BuildContext context)` convenience that calls `showModalBottomSheet`.

- [ ] **Step 1: Implement the sheet**
```dart
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../app/theme.dart';
import '../../../state/settings_provider.dart';
import 'mascot_character.dart';

class MascotPickerSheet extends ConsumerWidget {
  const MascotPickerSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => const MascotPickerSheet(),
    );
  }

  static const _labels = <MascotCharacter, String>{
    MascotCharacter.flower: 'Flower',
    MascotCharacter.kitty: 'Kitty',
    MascotCharacter.bunny: 'Bunny',
    MascotCharacter.bee: 'Bee',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(mascotCharacterProvider).asData?.value ?? kDefaultMascotCharacter;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Choose your companion', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.0,
              children: [
                for (final c in MascotCharacter.values)
                  _MascotTile(
                    character: c,
                    label: _labels[c]!,
                    selected: c == selected,
                    onTap: () async {
                      await ref.read(setMascotCharacterProvider)(c);
                      if (context.mounted) Navigator.of(context).pop();
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MascotTile extends StatelessWidget {
  final MascotCharacter character;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _MascotTile({
    required this.character,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('mascot-tile-${character.name}'),
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? BrandColors.sage : Colors.transparent,
              width: 3,
            ),
            color: BrandColors.ivory,
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: SvgPicture.asset(
                  mascotAssetPath(character, RiskBand.low),
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 8),
              Text(label, style: Theme.of(context).textTheme.labelLarge),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Write the sheet test**
Create `test/ui/shared/mascot/mascot_picker_sheet_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/state/settings_provider.dart';
import 'package:migraine_forecast/ui/shared/mascot/mascot_character.dart';
import 'package:migraine_forecast/ui/shared/mascot/mascot_picker_sheet.dart';

void main() {
  testWidgets('shows heading and 4 tiles; tapping persists + pops', (tester) async {
    MascotCharacter? saved;
    await tester.pumpWidget(ProviderScope(
      overrides: [
        mascotCharacterProvider.overrideWith((ref) async => MascotCharacter.kitty),
        setMascotCharacterProvider.overrideWithValue((c) async => saved = c),
      ],
      child: const MaterialApp(home: Scaffold(body: MascotPickerSheet())),
    ));
    await tester.pump();

    expect(find.text('Choose your companion'), findsOneWidget);
    expect(find.byKey(const Key('mascot-tile-flower')), findsOneWidget);
    expect(find.byKey(const Key('mascot-tile-kitty')), findsOneWidget);
    expect(find.byKey(const Key('mascot-tile-bunny')), findsOneWidget);
    expect(find.byKey(const Key('mascot-tile-bee')), findsOneWidget);

    await tester.tap(find.byKey(const Key('mascot-tile-bee')));
    await tester.pump();
    expect(saved, MascotCharacter.bee);
  });
}
```

- [ ] **Step 3: Run test**
Run: `flutter test test/ui/shared/mascot/mascot_picker_sheet_test.dart -r expanded`
Expected: passes.

- [ ] **Step 4: Commit**
```bash
git add lib/ui/shared/mascot/mascot_picker_sheet.dart test/ui/shared/mascot/mascot_picker_sheet_test.dart
git commit -m "feat(mascot): add 'Choose your companion' picker bottom sheet"
```

---

### Task 9: Wire entry points (Today + Settings + Onboarding) and fix all affected tests

**Files:**
- Modify: `lib/ui/today/today_screen.dart`
- Modify: `lib/ui/settings/settings_screen.dart`
- Modify: `lib/ui/onboarding/onboarding_screen.dart`
- Modify (rewrite): `test/ui/shared/mascot/mascot_widget_test.dart`
- Modify (rewrite): `test/ui/shared/mascot/blob_painter_golden_test.dart` → renamed `test/ui/shared/mascot/mascot_golden_test.dart`
- Modify: `test/ui/today/today_screen_mascot_test.dart`
- Verify (likely no change): `test/ui/onboarding/onboarding_mascot_test.dart`, `test/ui/settings/settings_celebration_test.dart`, `test/ui/shared/animations/celebration_overlay_test.dart`, `test/app/app_smoke_test.dart`

**Interfaces:**
- Consumes: `MascotWidget` (now with `character`), `MascotPickerSheet.show`, `mascotCharacterProvider`.

- [ ] **Step 1: Today screen — watch character + open picker on tap**
In `lib/ui/today/today_screen.dart`, add the import:
```dart
import '../shared/mascot/mascot_picker_sheet.dart';
```
In `build`, after `final mode = ...`, add:
```dart
    final character = ref.watch(mascotCharacterProvider).asData?.value ?? MascotCharacter.kitty;
```
and add the import for the enum:
```dart
import '../shared/mascot/mascot_character.dart';
```
Replace the existing mascot block:
```dart
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: MascotWidget(band: a.band, size: 160),
                      ),
                    ),
```
with:
```dart
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: InkWell(
                          key: const Key('mascot-tap-target'),
                          borderRadius: BorderRadius.circular(80),
                          onTap: () => MascotPickerSheet.show(context),
                          child: MascotWidget(
                            band: a.band,
                            character: character,
                            size: 160,
                          ),
                        ),
                      ),
                    ),
```

- [ ] **Step 2: Settings screen — Appearance > Mascot row + character on cameo**
In `lib/ui/settings/settings_screen.dart`, add imports:
```dart
import '../shared/mascot/mascot_character.dart';
import '../shared/mascot/mascot_picker_sheet.dart';
```
Make the cameo use the chosen character. Replace:
```dart
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: MascotWidget(band: RiskBand.low, size: 80, controller: _mascot),
            ),
          ),
```
with:
```dart
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: MascotWidget(
                band: RiskBand.low,
                size: 80,
                controller: _mascot,
                character: ref.watch(mascotCharacterProvider).asData?.value ?? MascotCharacter.kitty,
              ),
            ),
          ),
```
Then add an Appearance section. Insert immediately after the cameo `Center(...)` block and before `Text('Display', ...)`:
```dart
          Text('Appearance', style: Theme.of(context).textTheme.titleSmall),
          ref.watch(mascotCharacterProvider).when(
            loading: () => const ListTile(title: Text('Mascot')),
            error: (e, _) => ListTile(title: const Text('Mascot'), subtitle: Text('Error: $e')),
            data: (character) => ListTile(
              key: const Key('settings-mascot-row'),
              title: const Text('Mascot'),
              subtitle: Text(_mascotLabel(character)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => MascotPickerSheet.show(context),
            ),
          ),
          const Divider(),
```
Add this helper method inside `_SettingsScreenState` (next to `_modeLabel`):
```dart
  String _mascotLabel(MascotCharacter c) {
    switch (c) {
      case MascotCharacter.flower: return 'Flower';
      case MascotCharacter.kitty: return 'Kitty';
      case MascotCharacter.bunny: return 'Bunny';
      case MascotCharacter.bee: return 'Bee';
    }
  }
```

- [ ] **Step 3: Onboarding — pass chosen character to the cameo**
In `lib/ui/onboarding/onboarding_screen.dart`, add the import:
```dart
import '../shared/mascot/mascot_character.dart';
```
Replace:
```dart
                child: MascotWidget(band: RiskBand.low, size: 80, controller: _mascot),
```
with:
```dart
                child: MascotWidget(
                  band: RiskBand.low,
                  size: 80,
                  controller: _mascot,
                  character: ref.watch(mascotCharacterProvider).asData?.value ?? MascotCharacter.kitty,
                ),
```
and add the import for the provider (it is in `settings_provider.dart`):
```dart
import '../../state/settings_provider.dart';
```
(If `settings_provider.dart` is already imported, skip.) Run `grep -n "settings_provider" lib/ui/onboarding/onboarding_screen.dart` to confirm.

- [ ] **Step 4: Rewrite `test/ui/shared/mascot/mascot_widget_test.dart`**
The old test read `foregroundPainter as MascotAccessoriesPainter` — that's gone. Replace the whole file:
```dart
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/app/theme.dart';
import 'package:migraine_forecast/ui/shared/mascot/mascot_character.dart';
import 'package:migraine_forecast/ui/shared/mascot/mascot_widget.dart';

Widget reducedMotion(Widget child) => MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: child,
    );

Widget host(RiskBand band, {MascotController? controller, MascotCharacter character = MascotCharacter.kitty}) {
  return MaterialApp(
    theme: buildLightTheme(),
    home: Scaffold(
      body: Center(
        child: reducedMotion(MascotWidget(band: band, controller: controller, character: character)),
      ),
    ),
  );
}

void main() {
  testWidgets('renders the SVG body + face for each band', (tester) async {
    for (final band in RiskBand.values) {
      await tester.pumpWidget(host(band));
      await tester.pump();
      expect(find.byType(MascotWidget), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets); // face painter present
    }
  });

  testWidgets('exposes band, size and character', (tester) async {
    await tester.pumpWidget(host(RiskBand.high, character: MascotCharacter.bee));
    final w = tester.widget<MascotWidget>(find.byType(MascotWidget));
    expect(w.band, RiskBand.high);
    expect(w.character, MascotCharacter.bee);
    expect(w.size, 160);
  });

  testWidgets('idle loop does not hang pumpAndSettle under reduced motion', (tester) async {
    await tester.pumpWidget(host(RiskBand.low));
    await tester.pumpAndSettle();
    expect(find.byType(MascotWidget), findsOneWidget);
  });

  testWidgets('controller.blink runs and acks', (tester) async {
    final controller = MascotController();
    await tester.pumpWidget(host(RiskBand.low, controller: controller));
    controller.blink();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(controller.pending, isNull);
  });

  testWidgets('onWiggle fires when wiggle completes', (tester) async {
    var wiggled = false;
    final controller = MascotController();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: reducedMotion(MascotWidget(
          band: RiskBand.low,
          controller: controller,
          onWiggle: () => wiggled = true,
        )),
      ),
    ));
    controller.wiggle();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(wiggled, isTrue);
  });
}
```

- [ ] **Step 5: Replace the golden test**
Delete the old one and create the new SVG-aware golden test:
```bash
git rm test/ui/shared/mascot/blob_painter_golden_test.dart
```
Create `test/ui/shared/mascot/mascot_golden_test.dart`:
```dart
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/app/theme.dart';
import 'package:migraine_forecast/ui/shared/mascot/mascot_character.dart';
import 'package:migraine_forecast/ui/shared/mascot/mascot_widget.dart';

void main() {
  setUpAll(() async {
    await precacheMascots(); // warm the flutter_svg cache so goldens are stable
  });

  for (final band in RiskBand.values) {
    testWidgets('kitty_${band.name}', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            theme: buildLightTheme(),
            home: Scaffold(
              body: Center(
                child: RepaintBoundary(
                  child: SizedBox(
                    width: 200,
                    height: 200,
                    child: MascotWidget(
                      band: band,
                      character: MascotCharacter.kitty,
                      size: 200,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(RepaintBoundary).first,
        matchesGoldenFile('goldens/kitty_${band.name}.png'),
      );
    });
  }
}
```
Remove the now-stale band goldens and generate the new ones:
```bash
git rm test/ui/shared/mascot/goldens/mascot_low.png test/ui/shared/mascot/goldens/mascot_moderate.png test/ui/shared/mascot/goldens/mascot_high.png test/ui/shared/mascot/goldens/mascot_veryHigh.png
flutter test test/ui/shared/mascot/mascot_golden_test.dart --update-goldens
```
Then verify they match:
Run: `flutter test test/ui/shared/mascot/mascot_golden_test.dart -r expanded`
Expected: 4 golden tests pass against the freshly generated PNGs.

- [ ] **Step 6: Update `test/ui/today/today_screen_mascot_test.dart`**
Add a `mascotCharacterProvider` override (so it doesn't need a real DB) and a tap-opens-picker assertion. Add the import:
```dart
import 'package:migraine_forecast/state/settings_provider.dart';
import 'package:migraine_forecast/ui/shared/mascot/mascot_character.dart';
```
In the `ProviderScope` overrides list, add:
```dart
        mascotCharacterProvider.overrideWith((ref) async => MascotCharacter.kitty),
```
After the existing `expect(mascot.band, RiskBand.high);`, append:
```dart
    expect(mascot.character, MascotCharacter.kitty);

    // Tapping the mascot opens the picker.
    await tester.tap(find.byKey(const Key('mascot-tap-target')));
    await tester.pumpAndSettle();
    expect(find.text('Choose your companion'), findsOneWidget);
```

- [ ] **Step 7: Verify the remaining 4 affected tests still pass; patch only if needed**
Run them:
```bash
flutter test test/ui/onboarding/onboarding_mascot_test.dart test/ui/settings/settings_celebration_test.dart test/ui/shared/animations/celebration_overlay_test.dart test/app/app_smoke_test.dart -r expanded
```
Expected: all pass. These import `MascotController`/`MascotAction`/`MascotWidget` from `mascot_widget.dart`, which still exports them.
- If `settings_celebration_test.dart` errors that `mascotCharacterProvider` needs a DB (because the settings screen now watches it), add to that test's `ProviderScope` overrides:
  ```dart
  mascotCharacterProvider.overrideWith((ref) async => MascotCharacter.kitty),
  ```
  with imports `import 'package:migraine_forecast/ui/shared/mascot/mascot_character.dart';` (the test already imports `settings_provider.dart`).
- If `app_smoke_test.dart` fails resolving `mascotCharacterProvider`, it already provides a DB (smoke test boots the real app); the default `kitty` will resolve via `settingsRepoProvider`. Only override if it errors.

- [ ] **Step 8: Full analyze + full test suite**
Run:
```bash
flutter analyze
flutter test -r expanded
```
Expected: analyzer clean; entire suite green (including the 6 previously-affected test files: `mascot_face_painter_test.dart` [replacing blob_painter_test], `mascot_golden_test.dart` [replacing blob_painter_golden_test], `mascot_widget_test.dart`, `today_screen_mascot_test.dart`, `onboarding_mascot_test.dart`, `settings_celebration_test.dart`, plus `celebration_overlay_test.dart`).

- [ ] **Step 9: Commit**
```bash
git add lib/ui/today/today_screen.dart lib/ui/settings/settings_screen.dart lib/ui/onboarding/onboarding_screen.dart \
        test/ui/shared/mascot/mascot_widget_test.dart test/ui/shared/mascot/mascot_golden_test.dart \
        test/ui/shared/mascot/goldens/ test/ui/today/today_screen_mascot_test.dart \
        test/ui/settings/settings_celebration_test.dart
git commit -m "feat(mascot): wire picker into Today/Settings/Onboarding; update mascot tests + goldens"
```

---

## Verification (run after all tasks)

- [ ] `flutter analyze` — clean.
- [ ] `flutter test -r expanded` — all green.
- [ ] Manual: launch app, tap the Today mascot → picker opens; pick Bee → mascot crossfades to bee live; Settings > Appearance > Mascot shows "Bee" and reopens the picker.
- [ ] Manual: confirm alcohol contributor chip/explanation reads "… alcohol units in last 24h".
