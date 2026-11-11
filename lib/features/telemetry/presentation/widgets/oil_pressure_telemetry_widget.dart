import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/number_formatter.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../settings/domain/models/pressure_unit.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../domain/models/telemetry_instrument.dart';
import '../providers/instrument_status_provider.dart';
import '../providers/telemetry_provider.dart';
import 'vertical_gauge_telemetry_widget.dart';

class OilPressureTelemetryWidget extends ConsumerWidget {
  const OilPressureTelemetryWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final oilPressure = ref.watch(
      telemetryProvider.select((t) => t.oilPressure),
    );
    final disableAnimations = ref.watch(
      disableTelemetryAnimationsProvider.select(
        (m) => m[TelemetryField.oilPressure] ?? false,
      ),
    );
    final settings = ref.watch(appSettingsProvider).value;
    final l10n = AppLocalizations.of(context)!;
    final fontScale = (settings?.mapFontSize ?? 1.0).toDouble();

    final pressureUnit = settings?.pressureUnit ?? PressureUnit.bar;
    final thresholds = TelemetryInstrument.oilPressure.thresholds(settings);

    final double? rawPressure = oilPressure;
    final pressureState = ref.watch(
      instrumentStatusProvider(
        TelemetryInstrument.oilPressure,
      ).select((status) => status.cardState),
    );

    final String valueStr = rawPressure != null
        ? (pressureUnit == PressureUnit.bar
              ? context.formatNumber(
                  pressureUnit.convertFromKpa(rawPressure),
                  1,
                )
              : pressureUnit.convertFromKpa(rawPressure).toStringAsFixed(0))
        : '---';

    final double maxVisualKpa = settings?.oilPressureMaxRange ?? 800.0;
    final double minVisualKpa = thresholds.inactiveMax ?? 50.0;

    return VerticalGaugeTelemetryWidget(
      title: l10n.oilPressureShort,
      currentValue: rawPressure,
      valueText: valueStr,
      minVisualValue: minVisualKpa,
      maxVisualValue: maxVisualKpa,
      thresholds: thresholds,
      state: pressureState,
      fontScale: fontScale,
      disableAnimations: disableAnimations,
    );
  }
}
