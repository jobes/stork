import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/cannelloni_service_io.dart'
    if (dart.library.html) '../../../../core/services/cannelloni_service_stub.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/telemetry_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../settings/domain/models/range_thresholds.dart';
import '../../../settings/presentation/pages/flight_settings_page.dart';
import 'telemetry_card.dart';

class RpmHorizontalTelemetryWidget extends ConsumerWidget {
  const RpmHorizontalTelemetryWidget({super.key});

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

  double _getBorderWidth(ThresholdState state) {
    return 2.0;
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
  Widget build(BuildContext context, WidgetRef ref) {
    final telemetry = ref.watch(telemetryProvider);
    final isConnected = ref.watch(cannelloniServiceProvider);
    final settings = ref.watch(appSettingsProvider).value;
    final thresholds = settings?.rpmThresholds ?? const RangeThresholds.raw(
      inactiveMax: 10.0,
      minError: 1400.0,
      minWarning: 1800.0,
      maxWarning: 5500.0,
      maxError: 5800.0,
    );
    final maxVisualValue = settings?.rpmMaxRange ?? 6000.0;
    const double minVisualValue = 0.0;

    final l10n = AppLocalizations.of(context)!;
    final fontScale = (settings?.mapFontSize ?? 1.0).toDouble();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultTextColor = isDark
        ? Colors.grey.shade400
        : Colors.grey.shade600;

    final int? currentRpm = telemetry.engineRPM;
    final String rpmText = currentRpm != null ? currentRpm.toString() : l10n.placeholderDash;

    ThresholdState rpmState = ThresholdState.inactive;
    if (currentRpm != null) {
      rpmState = thresholds.evaluate(currentRpm.toDouble());
    }

    final bool isAbnormal = rpmState != ThresholdState.operational &&
        rpmState != ThresholdState.inactive;

    return TelemetryCard(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const FlightSettingsPage()),
        );
      },
      boxShadow: _getBoxShadow(rpmState, isDark),
      borderColor: _getBorderColor(rpmState, isDark),
      borderWidth: _getBorderWidth(rpmState),
      padding: EdgeInsets.symmetric(
        horizontal: 12.0 * fontScale,
        vertical: 8.0 * fontScale,
      ),
      child: SizedBox(
        width: 140 * fontScale,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 22.0 * fontScale,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    l10n.engineRpmShort.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11.0 * fontScale,
                      fontWeight: FontWeight.bold,
                      color: defaultTextColor,
                    ),
                  ),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    style: TextStyle(
                      fontSize: (isAbnormal ? 18.0 : 15.0) * fontScale,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      color: isDark ? Colors.white : Colors.black,
                      height: 1.0,
                    ),
                    child: Text(rpmText),
                  ),
                ],
              ),
            ),
            SizedBox(height: 6 * fontScale),
            SizedBox(
              height: 14 * fontScale,
              child: currentRpm != null
                  ? CustomPaint(
                      painter: HorizontalSegmentedGaugePainter(
                        currentValue: currentRpm.toDouble(),
                        minValue: minVisualValue,
                        maxValue: maxVisualValue,
                        thresholds: thresholds,
                        isDark: isDark,
                        pointerThickness: 3.5,
                        pointerOverflow: 12.0,
                        tickLength: 2.0,
                      ),
                    )
                  : Center(
                      child: Icon(
                        Icons.error_outline,
                        size: 16 * fontScale,
                        color: isDark ? Colors.redAccent.shade200 : Colors.red.shade600,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class HorizontalSegmentedGaugePainter extends CustomPainter {
  final double currentValue;
  final double minValue;
  final double maxValue;
  final RangeThresholds thresholds;
  final bool isDark;
  final double pointerThickness;
  final double pointerOverflow;
  final double tickLength;

  const HorizontalSegmentedGaugePainter({
    required this.currentValue,
    required this.minValue,
    required this.maxValue,
    required this.thresholds,
    required this.isDark,
    this.pointerThickness = 3.5,
    this.pointerOverflow = 4.0,
    this.tickLength = 2.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double tubeHeight = size.height * 0.7;
    final double tubeTop = (size.height - tubeHeight) / 2;

    final inactiveMax = thresholds.inactiveMax ?? minValue;
    final minError = thresholds.minError ?? inactiveMax;
    final minWarning = thresholds.minWarning ?? minError;
    final maxWarning = thresholds.maxWarning ?? maxValue;
    final maxError = thresholds.maxError ?? maxWarning;

    double getX(double val) {
      final ratio = (val - minValue) / (maxValue - minValue);
      return ratio.clamp(0.0, 1.0) * size.width;
    }

    final paint = Paint()..style = PaintingStyle.fill;

    // Segment boundaries
    final double xInactive = getX(inactiveMax);
    final double xMinError = getX(minError);
    final double xMinWarning = getX(minWarning);
    final double xMaxWarning = getX(maxWarning);
    final double xMaxError = getX(maxError);

    // Tube background path (rounded rectangle at both ends)
    final tubeRect = Rect.fromLTWH(
      0,
      tubeTop,
      size.width,
      tubeHeight,
    );
    final tubeRRect = RRect.fromRectAndRadius(
      tubeRect,
      Radius.circular(tubeHeight / 2),
    );

    // 1. Clip and draw background segments in the tube
    canvas.save();
    canvas.clipRRect(tubeRRect);

    // Helper to draw horizontal segments
    void drawSegment(double leftX, double rightX, Color color) {
      if (leftX >= rightX) return;
      final segmentRect = Rect.fromLTRB(
        leftX,
        tubeTop,
        rightX,
        tubeTop + tubeHeight,
      );
      paint.color = color;
      canvas.drawRect(segmentRect, paint);
    }

    // Inactive region (gray)
    drawSegment(0.0, xInactive, Colors.grey.shade500.withAlpha(120));
    // Critical Low (red)
    drawSegment(xInactive, xMinError, Colors.red.shade400.withAlpha(160));
    // Warning Low (orange)
    drawSegment(xMinError, xMinWarning, Colors.orange.shade300.withAlpha(160));
    // Operational (green)
    drawSegment(xMinWarning, xMaxWarning, Colors.green.shade400.withAlpha(160));
    // Warning High (orange)
    drawSegment(xMaxWarning, xMaxError, Colors.orange.shade300.withAlpha(160));
    // Critical High (red)
    drawSegment(xMaxError, size.width, Colors.red.shade400.withAlpha(160));

    canvas.restore();

    // 2. Draw outer glass borders/contours
    final glassBorderPaint = Paint()
      ..color = isDark ? Colors.white.withAlpha(60) : Colors.black.withAlpha(40)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawRRect(tubeRRect, glassBorderPaint);

    final double pointerX = getX(currentValue);

    // Draw a prominent vertical pointer bar at the current level
    final pointerPaint = Paint()
      ..color = isDark ? Colors.white : Colors.black
      ..style = PaintingStyle.fill;
    final pointerRect = Rect.fromCenter(
      center: Offset(pointerX, size.height / 2),
      width: pointerThickness,
      height: tubeHeight + pointerOverflow,
    );
    final pointerRRect = RRect.fromRectAndRadius(pointerRect, Radius.circular(pointerThickness / 2));
    canvas.drawRRect(pointerRRect, pointerPaint);

    final outlinePaint = Paint()
      ..color = isDark ? Colors.black : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(pointerRRect, outlinePaint);

    // 4. Draw vertical tick marks for thresholds next to the tube
    final tickPaint = Paint()
      ..color = isDark ? Colors.white.withAlpha(100) : Colors.black.withAlpha(80)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final List<double> thresholdXs = [];
    if (thresholds.minError != null) thresholdXs.add(xMinError);
    if (thresholds.minWarning != null) thresholdXs.add(xMinWarning);
    if (thresholds.maxWarning != null) thresholdXs.add(xMaxWarning);
    if (thresholds.maxError != null) thresholdXs.add(xMaxError);

    for (final x in thresholdXs) {
      // Draw top tick
      canvas.drawLine(Offset(x, tubeTop - tickLength - 0.5), Offset(x, tubeTop - 0.5), tickPaint);
      // Draw bottom tick
      canvas.drawLine(Offset(x, tubeTop + tubeHeight + 0.5), Offset(x, tubeTop + tubeHeight + tickLength + 0.5), tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant HorizontalSegmentedGaugePainter oldDelegate) {
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
