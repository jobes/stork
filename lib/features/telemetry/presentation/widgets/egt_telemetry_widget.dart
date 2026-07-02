import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../settings/domain/models/range_thresholds.dart';
import '../../../settings/domain/models/temperature_unit.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../providers/telemetry_provider.dart';
import 'telemetry_card.dart';
import 'segmented_gauge_painter.dart';

class EgtTelemetryWidget extends ConsumerWidget {
  const EgtTelemetryWidget({super.key});

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exhaustGasTemperatures = ref.watch(telemetryProvider.select((t) => t.exhaustGasTemperatures));
    final disableAnimations = ref.watch(
      disableTelemetryAnimationsProvider.select((m) => m[TelemetryField.exhaustGasTemperature] ?? false),
    );
    final settings = ref.watch(appSettingsProvider).value;
    final l10n = AppLocalizations.of(context)!;
    final fontScale = (settings?.mapFontSize ?? 1.0).toDouble();

    final tempUnit = settings?.temperatureUnit ?? TemperatureUnit.celsius;
    
    // EGT thresholds loaded from settings
    final thresholds = settings?.egtThresholds ?? const RangeThresholds.raw(
      inactiveMax: 423.15, // 150 °C
      minError: 773.15,    // 500 °C
      minWarning: 973.15,  // 700 °C
      maxWarning: 1153.15, // 880 °C
      maxError: 1173.15,   // 900 °C
    );

    final double maxVisualK = settings?.egtMaxRange ?? 1223.15; // 950 °C
    final double minVisualK = thresholds.inactiveMax ?? 423.15; // 150 °C

    final egts = exhaustGasTemperatures;
    if (egts.isEmpty) {
      return const SizedBox.shrink();
    }

    // Determine the worst state among all cylinders
    ThresholdState worstState = ThresholdState.inactive;
    int worstSeverity = -1;
    for (final temp in egts) {
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
    final double colWidth = (egts.length <= 2 ? 36.0 : 28.0) * fontScale;
    final double totalContentWidth = egts.length * colWidth;

    return TelemetryCard(
      state: worstState,
      disableAnimations: disableAnimations,
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
              l10n.egtTemperatureShort.toUpperCase(),
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
              children: List.generate(egts.length, (index) {
                final double? rawTemp = egts[index];
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
                                duration: disableAnimations ? Duration.zero : const Duration(milliseconds: 300),
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
