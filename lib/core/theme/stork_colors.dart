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
  static const Color darkSurface = Color(0xFF111C25);

  static ColorScheme scheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final seed = isDark ? darkPrimary : lightPrimary;
    final base = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);

    return base.copyWith(
      primary: seed,
      onPrimary: isDark ? const Color(0xFF073444) : Colors.white,
      surface: isDark ? darkSurface : lightSurface,
      onSurface: isDark ? const Color(0xFFEAF2F7) : const Color(0xFF182934),
      onSurfaceVariant: isDark
          ? const Color(0xFFABBFCB)
          : const Color(0xFF526976),
      surfaceContainerLowest: isDark ? const Color(0xFF0C161D) : Colors.white,
      surfaceContainerLow: isDark ? const Color(0xFF1A2934) : Colors.white,
      surfaceContainer: isDark
          ? const Color(0xFF22333F)
          : const Color(0xFFEDF3F6),
      surfaceContainerHigh: isDark
          ? const Color(0xFF2B3D49)
          : const Color(0xFFE6EFF3),
      surfaceContainerHighest: isDark
          ? const Color(0xFF344956)
          : const Color(0xFFDCE8ED),
      outline: isDark ? const Color(0xFF8DA2AE) : const Color(0xFF879DAA),
      outlineVariant: isDark
          ? const Color(0xFF394D59)
          : const Color(0xFFD4E0E5),
    );
  }
}
