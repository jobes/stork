import 'package:flutter/material.dart';

import '../../../settings/domain/models/range_thresholds.dart';

class SegmentedGaugePainter extends CustomPainter {
  final double currentValue;
  final double minValue;
  final double maxValue;
  final RangeThresholds thresholds;
  final bool isDark;
  final double pointerThickness;
  final double pointerOverflow;
  final double tickLength;

  const SegmentedGaugePainter({
    required this.currentValue,
    required this.minValue,
    required this.maxValue,
    required this.thresholds,
    required this.isDark,
    this.pointerThickness = 3.5,
    this.pointerOverflow = 10.0,
    this.tickLength = 2.5,
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
    // Critical Low (red)
    drawSegment(yMinError, yInactive, Colors.red.shade400.withAlpha(160));
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
      width: tubeWidth + pointerOverflow,
      height: pointerThickness,
    );
    final pointerRRect = RRect.fromRectAndRadius(pointerRect, Radius.circular(pointerThickness / 2));
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
      canvas.drawLine(Offset(tubeLeft - tickLength - 0.5, y), Offset(tubeLeft - 0.5, y), tickPaint);
      // Draw right tick
      canvas.drawLine(Offset(tubeLeft + tubeWidth + 0.5, y), Offset(tubeLeft + tubeWidth + tickLength + 0.5, y), tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant SegmentedGaugePainter oldDelegate) {
    return oldDelegate.currentValue != currentValue ||
        oldDelegate.minValue != minValue ||
        oldDelegate.maxValue != maxValue ||
        oldDelegate.thresholds != thresholds ||
        oldDelegate.isDark != isDark ||
        oldDelegate.pointerThickness != pointerThickness ||
        oldDelegate.pointerOverflow != pointerOverflow ||
        oldDelegate.tickLength != tickLength;
  }
}
