import 'package:flutter/material.dart';

/// Migraine Forecast brand colors — sage greens + warm ivory.
abstract final class BrandColors {
  static const sage = Color(0xFF7A9B7A);
  static const ivory = Color(0xFFFAF7F0);
  static const ink = Color(0xFF2E3A2E);

  static const bandLow      = Color(0xFF8FB28B);
  static const bandModerate = Color(0xFFE6C98C);
  static const bandHigh     = Color(0xFFD89B7A);
  static const bandVeryHigh = Color(0xFFB46A6A);

  // Cycle phase palette — picked to avoid collision with severity bands and
  // to keep adjacent phases visually distinct on the ribbon.
  static const phaseMenses     = Color(0xFFC15B7A); // rose
  static const phaseFollicular = Color(0xFF6FA8DC); // sharper sky blue
  static const phaseOvulatory  = Color(0xFFB266C7); // saturated magenta-purple
  static const phaseLuteal     = Color(0xFFCBB088); // warm tan
}

ThemeData buildLightTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: BrandColors.sage,
    primary: BrandColors.sage,
    surface: BrandColors.ivory,
    brightness: Brightness.light,
  );
  final base = ThemeData(useMaterial3: true, colorScheme: scheme);
  return base.copyWith(
    scaffoldBackgroundColor: BrandColors.ivory,
    textTheme: base.textTheme.apply(
      bodyColor: BrandColors.ink,
      displayColor: BrandColors.ink,
    ),
    cardTheme: const CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      backgroundColor: BrandColors.ivory,
      foregroundColor: BrandColors.ink,
      elevation: 0,
    ),
  );
}

/// A dark theme palette: background, card surface, text, and accent.
class DarkPalette {
  final Color background;
  final Color surface;
  final Color onSurface;
  final Color primary;
  final String label;

  /// The darkest shade, used for text/icons drawn on the accent color. When
  /// null it is derived from [background]; Classic overrides it to reproduce
  /// the legacy comfort theme byte-for-byte.
  final Color? scaffoldUnder;

  const DarkPalette({
    required this.background,
    required this.surface,
    required this.onSurface,
    required this.primary,
    required this.label,
    this.scaffoldUnder,
  });
}

/// The app's original comfort theme — warm near-black. Default palette so
/// existing comfort-mode users see no change.
const kClassicPalette = DarkPalette(
  background: Color(0xFF232120),
  surface: Color(0xFF2E2C2B),
  onSurface: Color(0xFFDFD9D0),
  primary: Color(0xFF8B9D88),
  label: 'Classic',
  scaffoldUnder: Color(0xFF1C1A19),
);

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

ThemeData buildComfortTheme(DarkPalette palette) {
  final background = palette.background;
  final surface = palette.surface;
  final onSurface = palette.onSurface;
  final primary = palette.primary;
  final scaffoldUnder = palette.scaffoldUnder ??
      Color.alphaBlend(Colors.black.withAlpha(60), background);

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

Color colorForBand(String bandName) {
  switch (bandName) {
    case 'low': return BrandColors.bandLow;
    case 'moderate': return BrandColors.bandModerate;
    case 'high': return BrandColors.bandHigh;
    case 'veryHigh': return BrandColors.bandVeryHigh;
    default: return BrandColors.sage;
  }
}
