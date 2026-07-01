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

  test('midnight sage palette preserves the legacy comfort background', () {
    expect(kMidnightSagePalette.background, const Color(0xFF232120));
    expect(kMidnightSagePalette.surface, const Color(0xFF2E2C2B));
  });

  test('midnight sage theme reproduces the legacy scaffoldUnder-derived colors', () {
    final theme = buildComfortTheme(kMidnightSagePalette);
    expect(theme.colorScheme.onPrimary, const Color(0xFF1C1A19));
    expect(theme.colorScheme.onError, const Color(0xFF1C1A19));
  });

  test('all five palettes are distinct', () {
    final backgrounds = {
      kMidnightSagePalette.background,
      kDeepForestPalette.background,
      kMossPalette.background,
      kCharcoalPalette.background,
      kDeepPlumPalette.background,
    };
    expect(backgrounds.length, 5);
  });
}
