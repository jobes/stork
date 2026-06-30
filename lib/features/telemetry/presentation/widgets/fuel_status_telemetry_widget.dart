import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../settings/domain/models/range_thresholds.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../providers/telemetry_provider.dart';
import 'vertical_gauge_telemetry_widget.dart';

class FuelStatusTelemetryWidget extends ConsumerWidget {
  const FuelStatusTelemetryWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final telemetry = ref.watch(telemetryProvider);
    final settings = ref.watch(appSettingsProvider).value;
    final l10n = AppLocalizations.of(context)!;
    final fontScale = (settings?.mapFontSize ?? 1.0).toDouble();

    final thresholds = settings?.fuelThresholds ??
        const RangeThresholds.raw(
          minError: 10.0,
          minWarning: 20.0,
        );

    final double? rawPercent = telemetry.fuelLevelPercent;
    final double? rawLiters = telemetry.fuelVolumeLiters;

    // Use minError as the state fallback if no data
    final ThresholdState fuelState = rawPercent != null
        ? thresholds.evaluate(rawPercent)
        : ThresholdState.minError;

    // "Na widgete teplomer ukazuje hodnoty v %, ale cislo je pocet litrov."
    // Gauge visual min: 0.0, max: 100.0, and currentValue is rawPercent (which is 0..100)
    // Value text shows number of liters
    final String valueStr = rawLiters != null
        ? rawLiters.toStringAsFixed(0)
        : '---';

    return VerticalGaugeTelemetryWidget(
      title: l10n.fuelTankStatusShort,
      currentValue: rawPercent,
      valueText: valueStr,
      minVisualValue: 0.0,
      maxVisualValue: 100.0,
      thresholds: thresholds,
      state: fuelState,
      fontScale: fontScale,
    );
  }
}
