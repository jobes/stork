import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  final double borderWidth;
  final EdgeInsetsGeometry padding;

  const TelemetryCard({
    super.key,
    required this.child,
    this.onTap,
    this.boxShadow,
    this.borderColor,
    this.borderWidth = 2.0,
    this.padding = const EdgeInsets.all(12.0),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider).value;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final areWidgetsDraggable = settings?.areWidgetsDraggable ?? false;

    final defaultBorderColor = isDark
        ? Colors.white.withAlpha(76)
        : Colors.black.withAlpha(51);

    final resolvedBorderColor = borderColor ?? defaultBorderColor;

    final defaultBoxShadow = [
      BoxShadow(
        color: Colors.black.withAlpha(20),
        blurRadius: 8,
        spreadRadius: 0,
      ),
    ];

    final resolvedBoxShadow = boxShadow ?? defaultBoxShadow;

    final widgetContent = AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: resolvedBoxShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: const SizedBox.expand(),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: padding,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withAlpha(76)
                    : Colors.white.withAlpha(128),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: resolvedBorderColor,
                  width: borderWidth,
                ),
              ),
              child: RepaintBoundary(child: child),
            ),
          ],
        ),
      ),
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
