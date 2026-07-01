import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../settings/presentation/providers/settings_provider.dart';
import '../../../../telemetry/presentation/providers/telemetry_provider.dart';

class _CompassLayout {
  static const double barHeight = 40.0;
  static const double indicatorHeight = 40.0;
  static const double indicatorWidth = 4.0;
  static const double pixelsPerDegreeBase = 8.0;
  static const double labelFontSizeBase = 14.0;
  static const double headingFontSizeBase = 14.0;
  static const double markerHeightSmall = 6.0;
  static const double markerHeightMedium = 10.0;
  static const double markerHeightLarge = 15;
  static const double markerHeightXLarge = 13.0;
  static const double labelOffsetBase = 15.0;
}

// ARCHITECTURAL NOTE:
// CompassBar previously took [heading] as a parameter to remain a pure,
// reusable UI component decoupled from business logic (telemetryProvider).
// However, because the heading updates very frequently (multiple times per second),
// passing it down from MapPage caused the entire map screen to rebuild continuously,
// resulting in severe performance degradation and high CPU usage.
// To resolve this, CompassBar was refactored to consume telemetryProvider directly.
// This tightly couples this map presentation component to the telemetry module,
// but it is a necessary optimization to isolate high-frequency rebuilds to just this widget.
class CompassBar extends ConsumerWidget {
  const CompassBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final heading = ref.watch(telemetryProvider.select((t) => t.heading));
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final fontScale = ref.watch(
      appSettingsProvider.select(
        (s) => (s.value?.mapFontSize ?? 1.0).toDouble(),
      ),
    );

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: _CompassLayout.barHeight * fontScale,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colorScheme.surface.withAlpha(180),
                colorScheme.surface.withAlpha(100),
                colorScheme.surface.withAlpha(20),
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color: colorScheme.onSurface.withAlpha(30),
                width: 0.5,
              ),
            ),
          ),
          child: Stack(
            children: [
              // The scrolling compass tape with horizontal fade
              Positioned.fill(
                child: ShaderMask(
                  shaderCallback: (rect) {
                    return LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: const [
                        Colors.transparent,
                        Colors.black,
                        Colors.black,
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.15, 0.85, 1.0],
                    ).createShader(rect);
                  },
                  blendMode: BlendMode.dstIn,
                  child: CustomPaint(
                    painter: CompassPainter(
                      heading: heading ?? 0.0,
                      color: colorScheme.onSurface,
                      fontScale: fontScale,
                    ),
                  ),
                ),
              ),
              // Center indicator
              Align(
                alignment: Alignment.center,
                child: Container(
                  width: _CompassLayout.indicatorWidth,
                  height: _CompassLayout.indicatorHeight * fontScale,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        colorScheme.primary.withAlpha(0),
                        colorScheme.primary,
                        colorScheme.primary.withAlpha(0),
                      ],
                    ),
                  ),
                ),
              ),
              // Heading text
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withAlpha(100),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      heading != null
                          ? '${(heading.round() % 360).toString().padLeft(3, '0')}°'
                          : '---°',
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize:
                            _CompassLayout.headingFontSizeBase * fontScale,
                        fontFamily: 'Roboto Mono',
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2 * fontScale,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CompassPainter extends CustomPainter {
  final double heading;
  final Color color;
  final double fontScale;

  CompassPainter({
    required this.heading,
    required this.color,
    required this.fontScale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withAlpha(200)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    final double pixelsPerDegree =
        _CompassLayout.pixelsPerDegreeBase * fontScale;
    final double centerX = size.width / 2;

    // Calculate shadow once
    final shadowColor =
        ThemeData.estimateBrightnessForColor(color) == Brightness.light
        ? Colors.black.withAlpha(100)
        : Colors.white.withAlpha(100);

    // Calculate range of degrees to draw
    final int startDegree = (heading - (centerX / pixelsPerDegree)).floor();
    final int endDegree = (heading + (centerX / pixelsPerDegree)).ceil();

    for (int i = startDegree; i <= endDegree; i++) {
      final double x = centerX + (i - heading) * pixelsPerDegree;
      final int normalizedDegree = (i % 360 + 360) % 360;

      // Draw markers from bottom
      double markerHeight = _CompassLayout.markerHeightSmall * fontScale;
      bool showText = false;
      String? label;

      if (normalizedDegree % 90 == 0) {
        markerHeight = _CompassLayout.markerHeightXLarge * fontScale;
        showText = true;
        label = _getCardinalLabel(normalizedDegree);
      } else if (normalizedDegree % 30 == 0) {
        markerHeight = _CompassLayout.markerHeightLarge * fontScale;
        showText = true;
        label = normalizedDegree.toString().padLeft(3, '0');
      } else if (normalizedDegree % 10 == 0) {
        markerHeight = _CompassLayout.markerHeightMedium * fontScale;
      }

      canvas.drawLine(
        Offset(x, size.height),
        Offset(x, size.height - markerHeight),
        paint,
      );

      if (showText && label != null) {
        final baseStyle = TextStyle(
          color: color,
          fontSize: _CompassLayout.labelFontSizeBase * fontScale,
          fontWeight: normalizedDegree % 90 == 0
              ? FontWeight.bold
              : FontWeight.normal,
          fontFamily: 'Roboto',
        );

        final double textY =
            size.height -
            markerHeight -
            (_CompassLayout.labelOffsetBase * fontScale);

        // NOTE: We draw the text shadow/outline manually in 4 diagonal directions.
        // We do not use standard TextStyle(shadows: [...]) here because of a known Flutter
        // graphics engine (Skia/Impeller) caching bug inside CustomPainters, where text shadows
        // could remain static on the screen during fast repaints/canvas translations while the
        // foreground text moves. Drawing the shadow manually as text at offset coordinates
        // guarantees the shadow moves in perfect sync with the foreground label.
        textPainter.text = TextSpan(
          text: label,
          style: baseStyle.copyWith(color: shadowColor),
        );
        textPainter.layout();

        final double shadowOffset = 1.2 * fontScale;
        final double textX = x - textPainter.width / 2;

        textPainter.paint(
          canvas,
          Offset(textX - shadowOffset, textY - shadowOffset),
        );
        textPainter.paint(
          canvas,
          Offset(textX + shadowOffset, textY - shadowOffset),
        );
        textPainter.paint(
          canvas,
          Offset(textX - shadowOffset, textY + shadowOffset),
        );
        textPainter.paint(
          canvas,
          Offset(textX + shadowOffset, textY + shadowOffset),
        );

        // Draw main text
        textPainter.text = TextSpan(text: label, style: baseStyle);
        textPainter.layout();
        textPainter.paint(canvas, Offset(textX, textY));
      }
    }
  }

  String _getCardinalLabel(int degree) {
    return switch (degree) {
      0 || 360 => 'N',
      90 => 'E',
      180 => 'S',
      270 => 'W',
      _ => '',
    };
  }

  @override
  bool shouldRepaint(covariant CompassPainter oldDelegate) {
    return oldDelegate.heading != heading ||
        oldDelegate.fontScale != fontScale ||
        oldDelegate.color != color;
  }
}
