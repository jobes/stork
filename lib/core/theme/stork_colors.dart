import 'package:flutter/material.dart';

/// Visual identity for Stork's application chrome.
///
/// Flight warning and critical telemetry colors are intentionally separate:
/// their meaning must not change when the app brand or brightness changes.
class StorkColors {
  const StorkColors._();

  static const Color lightPrimary = Color(0xFF12647B);
  static const Color darkPrimary = Color(0xFF80CEE4);
  static const Color lightSurface = Color(0xFFF6F9FB);
  static const Color darkSurface = Color(0xFF000000);
  static const Color darkSurfaceContainer = Color(0xFF121212);

  static ColorScheme scheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final seed = isDark ? darkPrimary : lightPrimary;
    final base = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);

    return base.copyWith(
      primary: seed,
      onPrimary: isDark ? const Color(0xFF073444) : Colors.white,
      surface: isDark ? darkSurface : lightSurface,
      onSurface: isDark ? Colors.white : const Color(0xFF182934),
      onSurfaceVariant: isDark
          ? const Color(0xFFD1D5DB)
          : const Color(0xFF526976),
      // Dark uses black backgrounds and a single neutral surface tone.
      surfaceDim: isDark ? darkSurface : base.surfaceDim,
      surfaceBright: isDark ? darkSurfaceContainer : base.surfaceBright,
      surfaceContainerLowest: isDark ? darkSurface : Colors.white,
      surfaceContainerLow: isDark ? darkSurfaceContainer : Colors.white,
      surfaceContainer: isDark ? darkSurfaceContainer : const Color(0xFFEDF3F6),
      surfaceContainerHigh: isDark
          ? darkSurfaceContainer
          : const Color(0xFFE6EFF3),
      surfaceContainerHighest: isDark
          ? darkSurfaceContainer
          : const Color(0xFFDCE8ED),
      outline: isDark ? const Color(0xFF737373) : const Color(0xFF879DAA),
      outlineVariant: isDark
          ? const Color(0xFF737373)
          : const Color(0xFFD4E0E5),
    );
  }
}
