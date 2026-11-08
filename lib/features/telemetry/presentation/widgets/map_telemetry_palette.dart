import 'package:flutter/material.dart';

/// Visual tokens for instruments floating above the map.
///
/// These are intentionally separate from the warning/critical colors of
/// [TelemetryCard]. Safety colors are not brand colors and must not change
/// when the application's light/dark palette is redesigned.
class MapTelemetryPalette {
  const MapTelemetryPalette._(this.colors);

  final ColorScheme colors;

  factory MapTelemetryPalette.of(BuildContext context) =>
      MapTelemetryPalette.fromScheme(Theme.of(context).colorScheme);

  factory MapTelemetryPalette.fromScheme(ColorScheme scheme) =>
      MapTelemetryPalette._(scheme);

  bool get isDark => colors.brightness == Brightness.dark;

  Color get value => colors.onSurface;

  Color get label => colors.onSurfaceVariant;

  Color get neutralBorder => colors.outlineVariant;

  /// Near-opaque surfaces ensure labels stay legible over busy map tiles.
  /// Error/warning backgrounds are deliberately NOT defined here.
  List<Color> get neutralGradient => [
    colors.surfaceContainerLow.withValues(alpha: 0.96),
    colors.surface.withValues(alpha: 0.96),
  ];
}
