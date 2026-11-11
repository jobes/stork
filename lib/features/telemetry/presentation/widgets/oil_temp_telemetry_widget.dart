import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../settings/domain/models/temperature_unit.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../domain/models/telemetry_instrument.dart';
import '../providers/instrument_status_provider.dart';
import '../providers/telemetry_provider.dart';
import 'vertical_gauge_telemetry_widget.dart';

class OilTempTelemetryWidget extends ConsumerWidget {
  const OilTempTelemetryWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final oilTemperature = ref.watch(
      telemetryProvider.select((t) => t.oilTemperature),
    );
    final disableAnimations = ref.watch(
      disableTelemetryAnimationsProvider.select(
        (m) => m[TelemetryField.oilTemperature] ?? false,
      ),
    );
    final settings = ref.watch(appSettingsProvider).value;
    final l10n = AppLocalizations.of(context)!;
    final fontScale = (settings?.mapFontSize ?? 1.0).toDouble();

    final tempUnit = settings?.temperatureUnit ?? TemperatureUnit.celsius;
    final thresholds = TelemetryInstrument.oilTemperature.thresholds(settings);

    final double? rawTemp = oilTemperature;
    final tempState = ref.watch(
      instrumentStatusProvider(
        TelemetryInstrument.oilTemperature,
      ).select((status) => status.cardState),
    );

    final String valueStr = rawTemp != null
        ? tempUnit.convertFromKelvin(rawTemp).toStringAsFixed(0)
        : '---';

    final double maxVisualK = settings?.oilTempMaxRange ?? 413.15;
    final double minVisualK = thresholds.inactiveMax ?? 303.15;

    return VerticalGaugeTelemetryWidget(
      title: l10n.oilTemperatureShort,
      currentValue: rawTemp,
      valueText: valueStr,
      minVisualValue: minVisualK,
      maxVisualValue: maxVisualK,
      thresholds: thresholds,
      state: tempState,
      fontScale: fontScale,
      disableAnimations: disableAnimations,
    );
  }
}
