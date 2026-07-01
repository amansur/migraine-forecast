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

  test('classic palette preserves the legacy comfort background', () {
    expect(kClassicPalette.background, const Color(0xFF232120));
    expect(kClassicPalette.surface, const Color(0xFF2E2C2B));
  });

  test('all five palettes are distinct', () {
    final backgrounds = {
      kClassicPalette.background,
      kDeepForestPalette.background,
      kMossPalette.background,
      kCharcoalPalette.background,
      kDeepPlumPalette.background,
    };
    expect(backgrounds.length, 5);
  });
}
