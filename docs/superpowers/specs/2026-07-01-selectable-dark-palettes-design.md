# Selectable Dark Palettes — Design

## Goal

Let users choose which dark color palette the app uses for its "comfort"
(dark) theme. The single light theme (Sage & Ivory) is unchanged, and the
existing Comfort Mode auto/always/off switching behavior is untouched — this
only changes *which* dark theme is shown when comfort mode is active.

## Palettes

The light theme (`buildLightTheme`, Sage & Ivory) stays as-is.

Four selectable dark palettes, each defined by a small value object:

| Palette              | Background | Surface   | onSurface (text) | Accent/primary |
|----------------------|-----------|-----------|------------------|----------------|
| Deep Forest & Parchment | `#2C362F` | `#38423B` | `#E5DFD1`        | `#8B9D88`      |
| Moss & Warmgray (default) | `#364236` | `#4F545C` | `#DFD9D0`      | `#8B9D88`      |
| Charcoal & Eucalyptus | `#333333` | `#3D3D3D` | `#DFD9D0`        | `#889D84`      |
| Deep Plum & Lilac    | `#2A2438` | `#352E47` | `#E0DAF0`        | `#9B8ADB`      |

Moss is the default because it most closely matches the app's current
`buildComfortTheme()`, so existing users see no visible change.

## Architecture

### Theme layer (`lib/app/theme.dart`)

- Introduce a `DarkPalette` value type holding `background`, `surface`,
  `onSurface`, and `primary` colors, plus a display `label`.
- Define the four palettes as constants.
- Refactor `buildComfortTheme()` to take a `DarkPalette` argument and build
  its `ThemeData` from those colors. The card/appbar/scaffold treatment is
  identical to the current implementation — only the color values become
  parameterized.

Note: `DarkPalette` here is the *theme-layer* palette (colors). The state
layer defines a separate enum used for persistence (below). Keep names
distinct to avoid confusion — e.g. theme-layer `DarkPalette` value objects
selected by a state-layer `DarkPaletteChoice` enum.

### State layer (`lib/state/settings_provider.dart`)

Mirror the existing `comfortModeProvider` / `setComfortModeProvider` pair:

- `enum DarkPaletteChoice { deepForest, moss, charcoal, deepPlum }`
- `darkPaletteProvider` — `FutureProvider<DarkPaletteChoice>` reading string
  key `'dark_palette'` from `settingsRepoProvider`, defaulting to
  `DarkPaletteChoice.moss` when unset or unrecognized.
- `setDarkPaletteProvider` — `Provider<Future<void> Function(DarkPaletteChoice)>`
  that writes the key and invalidates `darkPaletteProvider`.

### App wiring (`lib/app/app.dart`)

Watch `darkPaletteProvider` (defaulting to `moss` while loading) alongside the
existing comfort-mode logic. When `comfort` is true, build the comfort theme
from the chosen palette: `buildComfortTheme(paletteFor(choice))`. The
auto/always/off decision is unchanged.

### UI (`lib/ui/settings/settings_screen.dart`)

Add a "Dark palette" section directly below the existing Comfort Mode
control. Render four tappable swatch cards (one per palette). Each card:

- Renders the palette's actual background color, with a small row of
  surface + accent swatches so the user previews the real colors.
- Shows the palette label.
- Shows a check indicator on the currently selected card.
- On tap, calls `setDarkPaletteProvider`.

Wrapped in the same `ref.watch(darkPaletteProvider).when(...)` pattern used
by the other settings rows.

## Data Flow

1. User taps a swatch card → `setDarkPaletteProvider(choice)` writes
   `'dark_palette'` and invalidates `darkPaletteProvider`.
2. `app.dart` rebuilds; if comfort mode is active, the new palette's
   `ThemeData` is applied immediately.

## Error Handling

- Unknown/missing stored value → default to `moss` (same defensive pattern as
  `comfortModeProvider`).
- Provider `error`/`loading` states in the settings UI render nothing / the
  default, consistent with existing rows.

## Testing

- **Theme unit test:** `buildComfortTheme(palette)` produces the expected
  `colorScheme.surface` / `primary` / scaffold background for each palette.
- **Provider test:** `darkPaletteProvider` returns the stored choice, and
  defaults to `moss` when the key is absent or invalid; `setDarkPaletteProvider`
  persists the value.
- **Widget test:** tapping a swatch card updates the selected indicator and
  triggers the setter.

## Out of Scope (YAGNI)

- No additional light themes (image has only one light palette).
- No per-palette customization of severity-band or cycle-phase colors.
- No live theme animation/transition work beyond the existing rebuild.
