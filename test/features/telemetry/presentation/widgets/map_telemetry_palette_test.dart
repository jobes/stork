import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stork/core/theme/app_theme.dart';
import 'package:stork/features/settings/domain/models/range_thresholds.dart';
import 'package:stork/features/settings/presentation/utils/threshold_state_extension.dart';
import 'package:stork/features/telemetry/presentation/widgets/map_telemetry_palette.dart';

void main() {
  test('neutral map instruments inherit light and dark theme text colors', () {
    for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
      final palette = MapTelemetryPalette.fromScheme(theme.colorScheme);
      expect(palette.value, theme.colorScheme.onSurface);
      expect(palette.label, theme.colorScheme.onSurfaceVariant);
      expect(palette.neutralBorder, theme.colorScheme.outlineVariant);
      expect(palette.neutralGradient, [
        theme.colorScheme.surfaceContainerLow.withValues(alpha: 0.96),
        theme.colorScheme.surface.withValues(alpha: 0.96),
      ]);
    }
  });

  test('severity colors remain independent of brand palette', () {
    expect(ThresholdState.minError.color, Colors.red);
    expect(ThresholdState.maxError.color, Colors.red);
    expect(ThresholdState.minWarning.color, Colors.orange);
    expect(ThresholdState.maxWarning.color, Colors.orange);
    expect(ThresholdState.operational.color, Colors.green);
  });
}
