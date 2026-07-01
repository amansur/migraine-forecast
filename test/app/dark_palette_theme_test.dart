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
