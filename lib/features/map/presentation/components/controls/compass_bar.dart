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
class CompassBar extends ConsumerStatefulWidget {
  const CompassBar({super.key});

  @override
  ConsumerState<CompassBar> createState() => _CompassBarState();
}

class _CompassBarState extends ConsumerState<CompassBar> {
  final Map<String, (TextPainter, TextPainter)> _painterCache = {};
  double? _lastFontScale;
  Color? _lastColor;
  Color? _lastShadowColor;

  @override
  Widget build(BuildContext context) {
    final heading = ref.watch(telemetryProvider.select((t) => t.heading));
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final fontScale = ref.watch(
      appSettingsProvider.select(
        (s) => (s.value?.mapFontSize ?? 1.0).toDouble(),
      ),
    );

    final color = colorScheme.onSurface;
    final shadowColor =
        ThemeData.estimateBrightnessForColor(color) == Brightness.light
        ? Colors.black.withAlpha(100)
        : Colors.white.withAlpha(100);

    if (_lastFontScale != fontScale || _lastColor != color || _lastShadowColor != shadowColor) {
      _painterCache.clear();
      _lastFontScale = fontScale;
      _lastColor = color;
      _lastShadowColor = shadowColor;
    }

    return Container(
      height: _CompassLayout.barHeight * fontScale,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colorScheme.surface.withAlpha(235),
            colorScheme.surface.withAlpha(210),
            colorScheme.surface.withAlpha(150),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: colorScheme.onSurface.withAlpha(45),
            width: 0.5,
          ),
        ),
      ),
      child: RepaintBoundary(
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
                    color: color,
                    shadowColor: shadowColor,
                    fontScale: fontScale,
                    painterCache: _painterCache,
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
                    color: colorScheme.surface.withAlpha(140),
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
    );
  }
}

class CompassPainter extends CustomPainter {
  final double heading;
  final Color color;
  final Color shadowColor;
  final double fontScale;
  final Map<String, (TextPainter, TextPainter)> painterCache;

  CompassPainter({
    required this.heading,
    required this.color,
    required this.shadowColor,
    required this.fontScale,
    required this.painterCache,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withAlpha(200)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final double pixelsPerDegree =
        _CompassLayout.pixelsPerDegreeBase * fontScale;
    final double centerX = size.width / 2;

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
        final double textY =
            size.height -
            markerHeight -
            (_CompassLayout.labelOffsetBase * fontScale);

        final (shadowPainter, foregroundPainter) = painterCache.putIfAbsent(label, () {
          final baseStyle = TextStyle(
            color: color,
            fontSize: _CompassLayout.labelFontSizeBase * fontScale,
            fontWeight: normalizedDegree % 90 == 0
                ? FontWeight.bold
                : FontWeight.normal,
            fontFamily: 'Roboto',
          );
          final sp = TextPainter(
            text: TextSpan(text: label, style: baseStyle.copyWith(color: shadowColor)),
            textDirection: TextDirection.ltr,
          )..layout();
          final fp = TextPainter(
            text: TextSpan(text: label, style: baseStyle),
            textDirection: TextDirection.ltr,
          )..layout();
          return (sp, fp);
        });

        final double shadowOffset = 1.2 * fontScale;
        final double textX = x - foregroundPainter.width / 2;

        shadowPainter.paint(
          canvas,
          Offset(textX - shadowOffset, textY - shadowOffset),
        );
        shadowPainter.paint(
          canvas,
          Offset(textX + shadowOffset, textY - shadowOffset),
        );
        shadowPainter.paint(
          canvas,
          Offset(textX - shadowOffset, textY + shadowOffset),
        );
        shadowPainter.paint(
          canvas,
          Offset(textX + shadowOffset, textY + shadowOffset),
        );

        // Draw main text
        foregroundPainter.paint(canvas, Offset(textX, textY));
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
        oldDelegate.color != color ||
        oldDelegate.shadowColor != shadowColor;
  }
}
