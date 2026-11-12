import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../settings/domain/models/range_thresholds.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import 'map_telemetry_palette.dart';

/// A map-overlay instrument surface with theme-aware neutral colors.
///
/// Warning and critical borders/glows retain their original aviation severity
/// mapping. Drag/lock behavior, tap handling and telemetry sizing are unchanged.
class TelemetryCard extends ConsumerWidget {
  final Widget child;
  final VoidCallback? onTap;
  final List<BoxShadow>? boxShadow;
  final Color? borderColor;
  final double? borderWidth;
  final EdgeInsetsGeometry padding;
  final ThresholdState state;
  final bool disableAnimations;

  const TelemetryCard({
    super.key,
    required this.child,
    this.onTap,
    this.boxShadow,
    this.borderColor,
    this.borderWidth,
    this.padding = const EdgeInsets.all(12.0),
    this.state = ThresholdState.operational,
    this.disableAnimations = false,
  });

  static Color warningColor({required bool isDark}) =>
      isDark ? Colors.orangeAccent : Colors.orange.shade700;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider).value;
    final palette = MapTelemetryPalette.of(context);
    final isDark = palette.isDark;
    final areWidgetsDraggable = settings?.areWidgetsDraggable ?? false;

    final isError =
        state == ThresholdState.minError || state == ThresholdState.maxError;
    final isWarning =
        state == ThresholdState.minWarning ||
        state == ThresholdState.maxWarning;

    final Color defaultBorderColor;
    if (isError) {
      defaultBorderColor = isDark
          ? Colors.redAccent.shade400
          : Colors.red.shade700;
    } else if (isWarning) {
      defaultBorderColor = warningColor(isDark: isDark);
    } else {
      defaultBorderColor = palette.neutralBorder;
    }
    final resolvedBorderColor = borderColor ?? defaultBorderColor;

    const double defaultBorderWidth = 2.0;
    final resolvedBorderWidth = borderWidth ?? defaultBorderWidth;

    final List<BoxShadow> defaultBoxShadow;
    if (isError) {
      final color = isDark ? Colors.redAccent.shade400 : Colors.red.shade600;
      defaultBoxShadow = [
        BoxShadow(color: color.withAlpha(180), blurRadius: 24, spreadRadius: 6),
      ];
    } else if (isWarning) {
      final color = isDark ? Colors.amber : Colors.orange.shade800;
      defaultBoxShadow = [
        BoxShadow(color: color.withAlpha(100), blurRadius: 16, spreadRadius: 3),
      ];
    } else {
      defaultBoxShadow = [
        BoxShadow(
          color: Colors.black.withAlpha(isDark ? 42 : 20),
          blurRadius: 6,
          spreadRadius: 0,
        ),
      ];
    }
    final resolvedBoxShadow = boxShadow ?? defaultBoxShadow;

    final Gradient resolvedGradient;
    if (isError) {
      resolvedGradient = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [
                Color.alphaBlend(
                  Colors.red.shade800.withAlpha(180),
                  palette.colors.surfaceContainerLow,
                ),
                palette.colors.surface,
              ]
            : [Colors.red.shade100, Colors.red.shade50],
      );
    } else if (isWarning) {
      resolvedGradient = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [
                Color.alphaBlend(
                  Colors.orange.shade900.withAlpha(100),
                  palette.colors.surfaceContainerLow,
                ),
                palette.colors.surface,
              ]
            : [Colors.orange.shade50, Colors.white],
      );
    } else {
      resolvedGradient = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: palette.neutralGradient,
      );
    }

    final widgetContent = AnimatedContainer(
      duration: disableAnimations
          ? Duration.zero
          : const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: resolvedBoxShadow,
        border: Border.all(
          color: resolvedBorderColor,
          width: resolvedBorderWidth,
        ),
        gradient: resolvedGradient,
      ),
      child: RepaintBoundary(child: child),
    );

    if (!areWidgetsDraggable && onTap != null) {
      return Semantics(
        button: true,
        child: GestureDetector(
          onTap: onTap,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: widgetContent,
          ),
        ),
      );
    }

    return widgetContent;
  }
}
