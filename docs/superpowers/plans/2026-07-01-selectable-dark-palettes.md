# Selectable Dark Palettes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let users choose which of four dark palettes the app uses as its comfort (dark) theme, persisted across launches.

**Architecture:** Parameterize the existing `buildComfortTheme()` with a `DarkPalette` value object (colors) and define four palette constants in the theme layer. Add a `DarkPaletteChoice` enum plus persistence providers in the state layer, mirroring the existing `comfortModeProvider` pair. Wire `app.dart` to build the comfort theme from the chosen palette, and add a swatch-card picker to the settings screen.

**Tech Stack:** Flutter, Material 3, Riverpod, Drift-backed `SettingsRepo` (string key/value), `flutter_test`.

## Global Constraints

- Persist via `settingsRepoProvider` string key `'dark_palette'`.
- Default palette is `DarkPaletteChoice.moss` (matches current comfort theme; existing users see no change).
- Do not alter the light theme, Comfort Mode auto/always/off logic, severity-band colors, or cycle-phase colors.
- Follow existing provider pattern: `FutureProvider` reader + `Provider<Future<void> Function(...)>` setter that invalidates the reader.

---

### Task 1: DarkPalette value type and four palette constants

**Files:**
- Modify: `lib/app/theme.dart`
- Test: `test/app/dark_palette_theme_test.dart` (create)

**Interfaces:**
- Produces:
  - `class DarkPalette { final Color background, surface, onSurface, primary; final String label; const DarkPalette({...}); }`
  - `const DarkPalette kDeepForestPalette`, `kMossPalette`, `kCharcoalPalette`, `kDeepPlumPalette`
  - `ThemeData buildComfortTheme(DarkPalette palette)` (signature change from no-arg)

- [ ] **Step 1: Write the failing test**

```dart
// test/app/dark_palette_theme_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/app/theme.dart';

void main() {
  test('buildComfortTheme applies palette colors to the scheme', () {
    final theme = buildComfortTheme(kDeepPlumPalette);
    expect(theme.colorScheme.brightness, Brightness.dark);
    expect(theme.colorScheme.surface, kDeepPlumPalette.surface);
    expect(theme.colorScheme.primary, kDeepPlumPalette.primary);
    expect(theme.scaffoldBackgroundColor, kDeepPlumPalette.background);
  });

  test('moss palette matches the legacy comfort background', () {
    expect(kMossPalette.background, const Color(0xFF364236));
  });

  test('all four palettes are distinct', () {
    final backgrounds = {
      kDeepForestPalette.background,
      kMossPalette.background,
      kCharcoalPalette.background,
      kDeepPlumPalette.background,
    };
    expect(backgrounds.length, 4);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/app/dark_palette_theme_test.dart`
Expected: FAIL — `kDeepPlumPalette` / `DarkPalette` undefined, `buildComfortTheme` takes no args.

- [ ] **Step 3: Add the DarkPalette type and palettes, refactor buildComfortTheme**

In `lib/app/theme.dart`, add after `BrandColors`:

```dart
/// A dark theme palette: background, card surface, text, and accent.
class DarkPalette {
  final Color background;
  final Color surface;
  final Color onSurface;
  final Color primary;
  final String label;

  const DarkPalette({
    required this.background,
    required this.surface,
    required this.onSurface,
    required this.primary,
    required this.label,
  });
}

const kDeepForestPalette = DarkPalette(
  background: Color(0xFF2C362F),
  surface: Color(0xFF38423B),
  onSurface: Color(0xFFE5DFD1),
  primary: Color(0xFF8B9D88),
  label: 'Deep Forest',
);

const kMossPalette = DarkPalette(
  background: Color(0xFF364236),
  surface: Color(0xFF4F545C),
  onSurface: Color(0xFFDFD9D0),
  primary: Color(0xFF8B9D88),
  label: 'Moss',
);

const kCharcoalPalette = DarkPalette(
  background: Color(0xFF333333),
  surface: Color(0xFF3D3D3D),
  onSurface: Color(0xFFDFD9D0),
  primary: Color(0xFF889D84),
  label: 'Charcoal',
);

const kDeepPlumPalette = DarkPalette(
  background: Color(0xFF2A2438),
  surface: Color(0xFF352E47),
  onSurface: Color(0xFFE0DAF0),
  primary: Color(0xFF9B8ADB),
  label: 'Deep Plum',
);
```

Then replace the existing `ThemeData buildComfortTheme() { ... }` body so it is parameterized. New version:

```dart
ThemeData buildComfortTheme(DarkPalette palette) {
  final background = palette.background;
  final surface = palette.surface;
  final onSurface = palette.onSurface;
  final primary = palette.primary;
  final scaffoldUnder = Color.alphaBlend(Colors.black.withAlpha(60), background);

  final scheme = ColorScheme(
    brightness: Brightness.dark,
    primary: primary,
    onPrimary: scaffoldUnder,
    secondary: primary,
    onSecondary: scaffoldUnder,
    error: const Color(0xFFCF6679),
    onError: scaffoldUnder,
    surface: surface,
    onSurface: onSurface,
  );

  final base = ThemeData(useMaterial3: true, colorScheme: scheme);
  return base.copyWith(
    scaffoldBackgroundColor: background,
    textTheme: base.textTheme.apply(
      bodyColor: onSurface,
      displayColor: onSurface,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: surface,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        side: BorderSide(color: onSurface.withAlpha(30)),
      ),
    ),
    appBarTheme: AppBarTheme(
      centerTitle: true,
      backgroundColor: background,
      foregroundColor: onSurface,
      elevation: 0,
      shadowColor: Colors.transparent,
    ),
  );
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/app/dark_palette_theme_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/app/theme.dart test/app/dark_palette_theme_test.dart
git commit -m "feat(theme): parameterize comfort theme with DarkPalette"
```

---

### Task 2: DarkPaletteChoice enum and persistence providers

**Files:**
- Modify: `lib/state/settings_provider.dart`
- Test: `test/state/dark_palette_provider_test.dart` (create)

**Interfaces:**
- Consumes: `settingsRepoProvider` (`getString`/`setString`), theme-layer palette constants from Task 1.
- Produces:
  - `enum DarkPaletteChoice { deepForest, moss, charcoal, deepPlum }`
  - `final darkPaletteProvider = FutureProvider<DarkPaletteChoice>(...)`
  - `final setDarkPaletteProvider = Provider<Future<void> Function(DarkPaletteChoice)>(...)`
  - `DarkPalette paletteFor(DarkPaletteChoice choice)` mapping enum → theme-layer palette

- [ ] **Step 1: Write the failing test**

```dart
// test/state/dark_palette_provider_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/data/database.dart';
import 'package:migraine_forecast/data/repos/settings_repo.dart';
import 'package:migraine_forecast/state/providers.dart';
import 'package:migraine_forecast/state/settings_provider.dart';

void main() {
  test('darkPaletteProvider defaults to moss on fresh install', () async {
    final db = AppDatabase.memory();
    addTearDown(db.close);
    final container = ProviderContainer(overrides: [
      settingsRepoProvider.overrideWithValue(SettingsRepo(db)),
    ]);
    addTearDown(container.dispose);

    final choice = await container.read(darkPaletteProvider.future);
    expect(choice, DarkPaletteChoice.moss);
  });

  test('darkPaletteProvider returns the persisted choice', () async {
    final db = AppDatabase.memory();
    addTearDown(db.close);
    final container = ProviderContainer(overrides: [
      settingsRepoProvider.overrideWithValue(SettingsRepo(db)),
    ]);
    addTearDown(container.dispose);

    await container.read(setDarkPaletteProvider)(DarkPaletteChoice.deepPlum);
    final choice = await container.read(darkPaletteProvider.future);
    expect(choice, DarkPaletteChoice.deepPlum);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/state/dark_palette_provider_test.dart`
Expected: FAIL — `darkPaletteProvider` / `DarkPaletteChoice` undefined.

- [ ] **Step 3: Add enum, mapping, and providers**

In `lib/state/settings_provider.dart`, ensure the theme import is present at the top:

```dart
import '../app/theme.dart';
```

Then add after the existing `setComfortModeProvider` block (around line 99):

```dart
enum DarkPaletteChoice { deepForest, moss, charcoal, deepPlum }

DarkPalette paletteFor(DarkPaletteChoice choice) {
  switch (choice) {
    case DarkPaletteChoice.deepForest:
      return kDeepForestPalette;
    case DarkPaletteChoice.moss:
      return kMossPalette;
    case DarkPaletteChoice.charcoal:
      return kCharcoalPalette;
    case DarkPaletteChoice.deepPlum:
      return kDeepPlumPalette;
  }
}

final darkPaletteProvider = FutureProvider<DarkPaletteChoice>((ref) async {
  final raw = await ref.watch(settingsRepoProvider).getString('dark_palette');
  return DarkPaletteChoice.values.firstWhere(
    (c) => c.name == raw,
    orElse: () => DarkPaletteChoice.moss,
  );
});

final setDarkPaletteProvider =
    Provider<Future<void> Function(DarkPaletteChoice)>((ref) {
  return (choice) async {
    await ref.read(settingsRepoProvider).setString('dark_palette', choice.name);
    ref.invalidate(darkPaletteProvider);
  };
});
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/state/dark_palette_provider_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/state/settings_provider.dart test/state/dark_palette_provider_test.dart
git commit -m "feat(state): persist selectable dark palette choice"
```

---

### Task 3: Wire the chosen palette into the app theme

**Files:**
- Modify: `lib/app/app.dart:45-52`
- Test: `test/app/app_smoke_test.dart` (verify still passes; no new test needed — behavior covered by Tasks 1–2 and Task 4)

**Interfaces:**
- Consumes: `darkPaletteProvider`, `paletteFor(...)` (Task 2), `buildComfortTheme(DarkPalette)` (Task 1).

- [ ] **Step 1: Update the build method**

In `lib/app/app.dart`, replace lines 45–48 (the risk/comfort/theme setup) with:

```dart
    final hasActiveAttack = ref.watch(activeAttackProvider).asData?.value ?? false;
    final mode = ref.watch(comfortModeProvider).asData?.value ?? ComfortMode.auto;
    final paletteChoice =
        ref.watch(darkPaletteProvider).asData?.value ?? DarkPaletteChoice.moss;
    final comfort = mode == ComfortMode.always || (mode == ComfortMode.auto && hasActiveAttack);
    final activeTheme =
        comfort ? buildComfortTheme(paletteFor(paletteChoice)) : buildLightTheme();
```

- [ ] **Step 2: Run the app smoke test to verify no regression**

Run: `flutter test test/app/app_smoke_test.dart`
Expected: PASS.

- [ ] **Step 3: Commit**

```bash
git add lib/app/app.dart
git commit -m "feat(app): build comfort theme from selected dark palette"
```

---

### Task 4: Swatch-card palette picker in Settings

**Files:**
- Modify: `lib/ui/settings/settings_screen.dart` (add "Dark palette" section after the Comfort Mode block, ~line 192)
- Test: `test/ui/settings/dark_palette_picker_test.dart` (create)

**Interfaces:**
- Consumes: `darkPaletteProvider`, `setDarkPaletteProvider`, `DarkPaletteChoice`, `paletteFor(...)`.

- [ ] **Step 1: Write the failing widget test**

```dart
// test/ui/settings/dark_palette_picker_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/data/database.dart';
import 'package:migraine_forecast/data/repos/settings_repo.dart';
import 'package:migraine_forecast/state/providers.dart';
import 'package:migraine_forecast/state/settings_provider.dart';
import 'package:migraine_forecast/ui/settings/settings_screen.dart';

void main() {
  testWidgets('tapping a palette card persists the choice', (tester) async {
    final db = AppDatabase.memory();
    addTearDown(db.close);
    final container = ProviderContainer(overrides: [
      settingsRepoProvider.overrideWithValue(SettingsRepo(db)),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: SettingsScreen()),
    ));
    await tester.pumpAndSettle();

    final deepPlumCard = find.byKey(const Key('palette-card-deepPlum'));
    expect(deepPlumCard, findsOneWidget);

    await tester.ensureVisible(deepPlumCard);
    await tester.tap(deepPlumCard);
    await tester.pumpAndSettle();

    final choice = await container.read(darkPaletteProvider.future);
    expect(choice, DarkPaletteChoice.deepPlum);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/ui/settings/dark_palette_picker_test.dart`
Expected: FAIL — no widget with key `palette-card-deepPlum`.

- [ ] **Step 3: Add the Dark palette section**

In `lib/ui/settings/settings_screen.dart`, immediately after the `comfortModeProvider` `.when(...)` block closes (before the `const Divider()` at line 193), insert:

```dart
          ref.watch(darkPaletteProvider).when(
            loading: () => const SizedBox.shrink(),
            error: (e, _) => Text('Error: $e'),
            data: (selected) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Dark palette'),
                  const SizedBox(height: 4),
                  Text(
                    'Colors used when comfort mode is on',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final choice in DarkPaletteChoice.values)
                        _PaletteCard(
                          choice: choice,
                          selected: choice == selected,
                          onTap: () => ref.read(setDarkPaletteProvider)(choice),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
```

Then add a private widget at the bottom of the file (after the existing `_SettingsScreenState` class / helpers):

```dart
class _PaletteCard extends StatelessWidget {
  const _PaletteCard({
    required this.choice,
    required this.selected,
    required this.onTap,
  });

  final DarkPaletteChoice choice;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = paletteFor(choice);
    return InkWell(
      key: Key('palette-card-${choice.name}'),
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: palette.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? palette.primary
                : palette.onSurface.withAlpha(40),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _swatch(palette.surface),
                const SizedBox(width: 6),
                _swatch(palette.primary),
                const Spacer(),
                if (selected)
                  Icon(Icons.check_circle, size: 18, color: palette.primary),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              palette.label,
              style: TextStyle(color: palette.onSurface, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _swatch(Color color) => Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      );
}
```

Confirm `settings_provider.dart` is already imported in this file (it is — `comfortModeProvider` is used); no new import needed since `paletteFor` and the palette providers live there.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/ui/settings/dark_palette_picker_test.dart`
Expected: PASS.

- [ ] **Step 5: Run the settings screen regression test**

Run: `flutter test test/ui/settings/settings_screen_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/ui/settings/settings_screen.dart test/ui/settings/dark_palette_picker_test.dart
git commit -m "feat(settings): add dark palette swatch picker"
```

---

### Task 5: Full-suite verification

**Files:** none (verification only)

- [ ] **Step 1: Run the analyzer**

Run: `flutter analyze`
Expected: No new issues introduced by these changes.

- [ ] **Step 2: Run the full test suite**

Run: `flutter test`
Expected: All tests pass.

- [ ] **Step 3: Commit any lint fixes if needed**

```bash
git add -A
git commit -m "chore: lint fixes for selectable dark palettes"
```
(Skip if nothing changed.)
