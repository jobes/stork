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
  final bool disableAnimations;

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
    this.disableAnimations = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultTextColor = isDark
        ? Colors.grey.shade300
        : Colors.grey.shade700;

    final bool isAbnormal =
        state != ThresholdState.operational && state != ThresholdState.inactive;

    return TelemetryCard(
      state: state,
      disableAnimations: disableAnimations,
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
                  ? TweenAnimationBuilder<double>(
                      tween: Tween<double>(
                        begin: currentValue!,
                        end: currentValue!,
                      ),
                      duration: disableAnimations
                          ? Duration.zero
                          : const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      builder: (context, animValue, child) {
                        return CustomPaint(
                          painter: SegmentedGaugePainter(
                            currentValue: animValue,
                            minValue: minVisualValue,
                            maxValue: maxVisualValue,
                            thresholds: thresholds,
                            isDark: isDark,
                            pointerThickness: 3.5,
                            pointerOverflow: 10.0,
                            tickLength: 2.5,
                          ),
                        );
                      },
                    )
                  : Center(
                      child: Icon(
                        Icons.error_outline,
                        size: 28 * fontScale,
                        color: isDark
                            ? Colors.redAccent.shade200
                            : Colors.red.shade600,
                      ),
                    ),
            ),
            SizedBox(height: 6 * fontScale),
            SizedBox(
              height: 26 * fontScale,
              child: Center(
                child: AnimatedDefaultTextStyle(
                  duration: disableAnimations
                      ? Duration.zero
                      : const Duration(milliseconds: 300),
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
