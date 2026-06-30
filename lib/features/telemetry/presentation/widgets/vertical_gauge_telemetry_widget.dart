import 'package:flutter/material.dart';

import '../../../settings/domain/models/range_thresholds.dart';
import 'telemetry_card.dart';
import 'segmented_gauge_painter.dart';

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
                      painter: SegmentedGaugePainter(
                        currentValue: currentValue!,
                        minValue: minVisualValue,
                        maxValue: maxVisualValue,
                        thresholds: thresholds,
                        isDark: isDark,
                        pointerThickness: 3.5,
                        pointerOverflow: 10.0,
                        tickLength: 2.5,
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


