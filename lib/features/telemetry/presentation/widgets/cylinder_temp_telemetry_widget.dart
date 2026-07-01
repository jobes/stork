import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../settings/domain/models/range_thresholds.dart';
import '../../../settings/domain/models/temperature_unit.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../providers/telemetry_provider.dart';
import 'telemetry_card.dart';
import 'segmented_gauge_painter.dart';

class CylinderTempTelemetryWidget extends ConsumerWidget {
  const CylinderTempTelemetryWidget({super.key});

  int _stateSeverity(ThresholdState state) {
    switch (state) {
      case ThresholdState.minError:
      case ThresholdState.maxError:
        return 2;
      case ThresholdState.minWarning:
      case ThresholdState.maxWarning:
        return 1;
      case ThresholdState.inactive:
      case ThresholdState.operational:
        return 0;
    }
  }

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
  Widget build(BuildContext context, WidgetRef ref) {
    final telemetry = ref.watch(telemetryProvider);
    final settings = ref.watch(appSettingsProvider).value;
    final l10n = AppLocalizations.of(context)!;
    final fontScale = (settings?.mapFontSize ?? 1.0).toDouble();

    final tempUnit = settings?.temperatureUnit ?? TemperatureUnit.celsius;
    
    // CHT thresholds loaded from settings
    final thresholds = settings?.chtThresholds ?? const RangeThresholds.raw(
      inactiveMax: 323.15, // 50 °C
      minError: 333.15,    // 60 °C
      minWarning: 348.15,  // 75 °C
      maxWarning: 403.15,  // 130 °C
      maxError: 423.15,    // 150 °C
    );

    final double maxVisualK = settings?.chtMaxRange ?? 433.15; // 160 °C
    final double minVisualK = thresholds.inactiveMax ?? 323.15; // 50 °C

    final chts = telemetry.cylinderHeadTemperatures;
    if (chts.isEmpty) {
      return const SizedBox.shrink();
    }

    // Determine the worst state among all cylinders
    ThresholdState worstState = ThresholdState.inactive;
    int worstSeverity = -1;
    for (final temp in chts) {
      final state = temp != null ? thresholds.evaluate(temp) : ThresholdState.maxError;
      final sev = _stateSeverity(state);
      if (sev > worstSeverity) {
        worstSeverity = sev;
        worstState = state;
      }
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultTextColor = isDark ? Colors.grey.shade300 : Colors.grey.shade700;

    // Dynamically calculate column layout sizes
    final double colWidth = (chts.length <= 2 ? 36.0 : 28.0) * fontScale;
    final double totalContentWidth = chts.length * colWidth;

    return TelemetryCard(
      boxShadow: _getBoxShadow(worstState, isDark),
      borderColor: _getBorderColor(worstState, isDark),
      borderWidth: 2.0,
      padding: EdgeInsets.symmetric(
        horizontal: 6.0 * fontScale,
        vertical: 8.0 * fontScale,
      ),
      child: SizedBox(
        width: totalContentWidth + 12.0 * fontScale,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              l10n.cylinderHeadTemperatureShort.toUpperCase(),
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
            SizedBox(height: 6 * fontScale),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(chts.length, (index) {
                final double? rawTemp = chts[index];
                final ThresholdState tempState = rawTemp != null
                    ? thresholds.evaluate(rawTemp)
                    : ThresholdState.maxError;

                final String valueStr = rawTemp != null
                    ? tempUnit.convertFromKelvin(rawTemp).toStringAsFixed(0)
                    : '---';

                final bool isAbnormal = tempState != ThresholdState.operational &&
                    tempState != ThresholdState.inactive;

                return SizedBox(
                  width: colWidth,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Thermometer Gauge
                      SizedBox(
                        width: 24 * fontScale,
                        height: 80 * fontScale,
                        child: rawTemp != null
                            ? TweenAnimationBuilder<double>(
                                tween: Tween<double>(begin: rawTemp, end: rawTemp),
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOut,
                                builder: (context, animTemp, child) {
                                  return CustomPaint(
                                    painter: SegmentedGaugePainter(
                                      currentValue: animTemp,
                                      minValue: minVisualK,
                                      maxValue: maxVisualK,
                                      thresholds: thresholds,
                                      isDark: isDark,
                                      pointerThickness: 3.0,
                                      pointerOverflow: 6.0,
                                      tickLength: 1.5,
                                    ),
                                  );
                                },
                              )
                            : Center(
                                child: Icon(
                                  Icons.error_outline,
                                  size: 20 * fontScale,
                                  color: isDark ? Colors.redAccent.shade200 : Colors.red.shade600,
                                ),
                              ),
                      ),
                      SizedBox(height: 6 * fontScale),
                      // Digital reading below the thermometer
                      SizedBox(
                        height: 20 * fontScale,
                        child: Center(
                          child: Text(
                            valueStr,
                            style: TextStyle(
                              fontSize: (isAbnormal ? 15.0 : 13.0) * fontScale,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                              color: rawTemp == null
                                  ? Colors.grey
                                  : (isDark ? Colors.white : Colors.black),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}


