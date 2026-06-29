import 'package:flutter/material.dart';

import '../../../settings/domain/models/range_thresholds.dart';
import 'telemetry_card.dart';

class VerticalGaugeTelemetryWidget extends StatelessWidget {
  final String title;
  final double? currentValue;
  final String valueText;
  final double minVisualValue;
  final double maxVisualValue;
  final RangeThresholds thresholds;
  final ThresholdState state;
  final double fontScale;

  const VerticalGaugeTelemetryWidget({
    super.key,
    required this.title,
    required this.currentValue,
    required this.valueText,
    required this.minVisualValue,
    required this.maxVisualValue,
    required this.thresholds,
    required this.state,
    required this.fontScale,
  });

  Color _getBorderColor(ThresholdState state, bool isDark) {
    switch (state) {
      case ThresholdState.inactive:
      case ThresholdState.operational:
        return isDark
            ? Colors.white.withAlpha(76)
            : Colors.black.withAlpha(51);
      case ThresholdState.minError:
      case ThresholdState.maxError:
        return isDark ? Colors.redAccent.shade200 : Colors.red.shade600;
      case ThresholdState.minWarning:
      case ThresholdState.maxWarning:
        return isDark ? Colors.orangeAccent : Colors.orange.shade700;
    }
  }

  List<BoxShadow> _getBoxShadow(ThresholdState state, bool isDark) {
    switch (state) {
      case ThresholdState.inactive:
      case ThresholdState.operational:
        return [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ];
      case ThresholdState.minError:
      case ThresholdState.maxError:
        final color = isDark ? Colors.redAccent : Colors.red.shade700;
        return [
          BoxShadow(
            color: color.withAlpha(102),
            blurRadius: 16,
            spreadRadius: 3,
          ),
        ];
      case ThresholdState.minWarning:
      case ThresholdState.maxWarning:
        final color = isDark ? Colors.amber : Colors.orange.shade800;
        return [
          BoxShadow(
            color: color.withAlpha(102),
            blurRadius: 16,
            spreadRadius: 3,
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultTextColor = isDark
        ? Colors.grey.shade300
        : Colors.grey.shade700;

    final bool isAbnormal = state != ThresholdState.operational &&
        state != ThresholdState.inactive;

    return TelemetryCard(
      boxShadow: _getBoxShadow(state, isDark),
      borderColor: _getBorderColor(state, isDark),
      borderWidth: 2.0,
      padding: EdgeInsets.symmetric(
        horizontal: 4.0 * fontScale,
        vertical: 8.0 * fontScale,
      ),
      child: SizedBox(
        width: 48 * fontScale,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              title.toUpperCase(),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.0 * fontScale,
                fontWeight: FontWeight.bold,
                color: defaultTextColor,
                letterSpacing: 0.0,
              ),
            ),
            SizedBox(height: 3 * fontScale),
            SizedBox(
              width: 32 * fontScale,
              height: 80 * fontScale,
              child: currentValue != null
                  ? CustomPaint(
                      painter: _GaugePainter(
                        currentValue: currentValue!,
                        minValue: minVisualValue,
                        maxValue: maxVisualValue,
                        thresholds: thresholds,
                        isDark: isDark,
                      ),
                    )
                  : Center(
                      child: Icon(
                        Icons.error_outline,
                        size: 28 * fontScale,
                        color: isDark ? Colors.redAccent.shade200 : Colors.red.shade600,
                      ),
                    ),
            ),
            SizedBox(height: 6 * fontScale),
            SizedBox(
              height: 26 * fontScale,
              child: Center(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  style: TextStyle(
                    fontSize: (isAbnormal ? 24.0 : 18.0) * fontScale,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: isDark ? Colors.white : Colors.black,
                    height: 1.0,
                  ),
                  child: Text(valueText),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double currentValue;
  final double minValue;
  final double maxValue;
  final RangeThresholds thresholds;
  final bool isDark;

  _GaugePainter({
    required this.currentValue,
    required this.minValue,
    required this.maxValue,
    required this.thresholds,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double tubeWidth = size.width * 0.5;
    final double tubeLeft = (size.width - tubeWidth) / 2;

    final inactiveMax = thresholds.inactiveMax ?? minValue;
    final minError = thresholds.minError ?? (minValue + (maxValue - minValue) * 0.1);
    final minWarning = thresholds.minWarning ?? (minValue + (maxValue - minValue) * 0.25);
    final maxWarning = thresholds.maxWarning ?? (minValue + (maxValue - minValue) * 0.75);
    final maxError = thresholds.maxError ?? (minValue + (maxValue - minValue) * 0.9);

    double getY(double val) {
      final ratio = (val - minValue) / (maxValue - minValue);
      return (1.0 - ratio.clamp(0.0, 1.0)) * size.height;
    }

    final paint = Paint()..style = PaintingStyle.fill;

    // Segment boundaries
    final double yInactive = getY(inactiveMax);
    final double yMinError = getY(minError);
    final double yMinWarning = getY(minWarning);
    final double yMaxWarning = getY(maxWarning);
    final double yMaxError = getY(maxError);

    // Tube background path (rounded rectangle at both ends)
    final tubeRect = Rect.fromLTWH(
      tubeLeft,
      0,
      tubeWidth,
      size.height,
    );
    final tubeRRect = RRect.fromRectAndRadius(
      tubeRect,
      Radius.circular(tubeWidth / 2),
    );

    // 1. Clip and draw background segments in the tube
    canvas.save();
    canvas.clipRRect(tubeRRect);

    // Helper to draw vertical segments
    void drawSegment(double topY, double bottomY, Color color) {
      if (topY >= bottomY) return;
      final segmentRect = Rect.fromLTRB(
        tubeLeft,
        topY,
        tubeLeft + tubeWidth,
        bottomY,
      );
      paint.color = color;
      canvas.drawRect(segmentRect, paint);
    }

    // Inactive region (gray)
    drawSegment(yInactive, size.height, Colors.grey.shade500.withAlpha(120));
    // Critical Low (blue)
    drawSegment(yMinError, yInactive, Colors.blue.shade400.withAlpha(160));
    // Warning Low (orange)
    drawSegment(yMinWarning, yMinError, Colors.orange.shade300.withAlpha(160));
    // Operational (green)
    drawSegment(yMaxWarning, yMinWarning, Colors.green.shade400.withAlpha(160));
    // Warning High (orange)
    drawSegment(yMaxError, yMaxWarning, Colors.orange.shade300.withAlpha(160));
    // Critical High (red)
    drawSegment(0.0, yMaxError, Colors.red.shade400.withAlpha(160));

    canvas.restore();

    // 2. Draw outer glass borders/contours
    final glassBorderPaint = Paint()
      ..color = isDark ? Colors.white.withAlpha(60) : Colors.black.withAlpha(40)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawRRect(tubeRRect, glassBorderPaint);

    final double pointerY = getY(currentValue);

    // Draw a prominent horizontal pointer bar at the current level
    final pointerPaint = Paint()
      ..color = isDark ? Colors.white : Colors.black
      ..style = PaintingStyle.fill;
    final pointerRect = Rect.fromCenter(
      center: Offset(size.width / 2, pointerY),
      width: tubeWidth + 10.0,
      height: 3.5,
    );
    final pointerRRect = RRect.fromRectAndRadius(pointerRect, const Radius.circular(1.75));
    canvas.drawRRect(pointerRRect, pointerPaint);

    final outlinePaint = Paint()
      ..color = isDark ? Colors.black : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(pointerRRect, outlinePaint);

    // 4. Draw horizontal tick marks for thresholds next to the tube
    final tickPaint = Paint()
      ..color = isDark ? Colors.white.withAlpha(100) : Colors.black.withAlpha(80)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final List<double> thresholdYs = [
      yMinError,
      yMinWarning,
      yMaxWarning,
      yMaxError,
    ];

    for (final y in thresholdYs) {
      // Draw left tick
      canvas.drawLine(Offset(tubeLeft - 3.0, y), Offset(tubeLeft - 0.5, y), tickPaint);
      // Draw right tick
      canvas.drawLine(Offset(tubeLeft + tubeWidth + 0.5, y), Offset(tubeLeft + tubeWidth + 3.0, y), tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.currentValue != currentValue ||
        oldDelegate.minValue != minValue ||
        oldDelegate.maxValue != maxValue ||
        oldDelegate.thresholds != thresholds ||
        oldDelegate.isDark != isDark;
  }
}
