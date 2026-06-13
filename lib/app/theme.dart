import 'package:flutter/material.dart';

/// Migraine Weatherr brand colors — sage greens + warm ivory.
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

Color colorForBand(String bandName) {
  switch (bandName) {
    case 'low': return BrandColors.bandLow;
    case 'moderate': return BrandColors.bandModerate;
    case 'high': return BrandColors.bandHigh;
    case 'veryHigh': return BrandColors.bandVeryHigh;
    default: return BrandColors.sage;
  }
}
