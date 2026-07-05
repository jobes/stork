import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../settings/domain/models/range_thresholds.dart';
import '../../../settings/presentation/providers/settings_provider.dart';

/// A reusable glassmorphic container for telemetry widgets on the map.
///
/// It handles consistent styling (glassmorphism blur, background colors, border, shadow)
/// and wraps the widget in a [GestureDetector] with a hand cursor for clickability
/// when the widgets are not in drag-and-drop edit mode (`areWidgetsDraggable == false`).
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider).value;
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
      defaultBorderColor = isDark
          ? Colors.orangeAccent
          : Colors.orange.shade700;
    } else {
      defaultBorderColor = isDark
          ? Colors.white.withAlpha(76)
          : Colors.black.withAlpha(51);
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
          color: Colors.black.withAlpha(20),
          blurRadius: 8,
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
            ? [Colors.red.shade800.withAlpha(180), Colors.black.withAlpha(240)]
            : [
                Colors.red.shade100.withAlpha(240),
                Colors.red.shade50.withAlpha(200),
              ],
      );
    } else if (isWarning) {
      resolvedGradient = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [
                Colors.orange.shade900.withAlpha(100),
                Colors.black.withAlpha(235),
              ]
            : [
                Colors.orange.shade50.withAlpha(220),
                Colors.white.withAlpha(220),
              ],
      );
    } else {
      resolvedGradient = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [Colors.black.withAlpha(210), Colors.grey.shade900.withAlpha(235)]
            : [
                Colors.white.withAlpha(235),
                Colors.grey.shade100.withAlpha(210),
              ],
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
      return GestureDetector(
        onTap: onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: widgetContent,
        ),
      );
    }

    return widgetContent;
  }
}
