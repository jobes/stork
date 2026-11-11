import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/models/telemetry_instrument.dart';
import '../providers/instrument_status_provider.dart';
import '../providers/telemetry_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../settings/domain/models/speed_unit.dart';
import '../dialogs/speed_details_dialog.dart';
import 'telemetry_card.dart';
import 'map_telemetry_palette.dart';

class SpeedTelemetryWidget extends ConsumerWidget {
  const SpeedTelemetryWidget({super.key});

  Widget _buildSpeedRow(
    String value,
    String unit,
    Color valueColor,
    Color unitColor,
    double fontScale,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 32 * fontScale,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            color: valueColor,
          ),
        ),
        SizedBox(width: 4 * fontScale),
        Text(
          unit,
          style: TextStyle(fontSize: 12 * fontScale, color: unitColor),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final indicatedAirSpeed = ref.watch(
      telemetryProvider.select((t) => t.indicatedAirSpeed),
    );
    final groundSpeed = ref.watch(
      telemetryProvider.select((t) => t.groundSpeed),
    );
    final settings = ref.watch(appSettingsProvider).value;
    final l10n = AppLocalizations.of(context)!;
    final fontScale = (settings?.mapFontSize ?? 1.0).toDouble();

    final palette = MapTelemetryPalette.of(context);
    final defaultTextColor = palette.label;
    final speedValueColor = palette.value;

    final speedUnit = settings?.speedUnit ?? SpeedUnit.kmh;
    final double? ias = indicatedAirSpeed != null
        ? speedUnit.convertFromMs(indicatedAirSpeed)
        : null;
    final double? gs = groundSpeed != null
        ? speedUnit.convertFromMs(groundSpeed)
        : null;
    final String unitLabel = speedUnit.getAbbreviation(l10n);

    final speedState = ref.watch(
      instrumentStatusProvider(
        TelemetryInstrument.speed,
      ).select((status) => status.cardState),
    );

    final List<Widget> columnChildren = [];

    if (ias != null && gs != null) {
      columnChildren.add(
        _buildSpeedRow(
          ias.toStringAsFixed(0).padLeft(3),
          unitLabel,
          speedValueColor,
          defaultTextColor,
          fontScale,
        ),
      );
      columnChildren.add(
        Text(
          l10n.gsSpeedLabel(gs.toStringAsFixed(0).padLeft(3), unitLabel),
          style: TextStyle(
            fontSize: 12 * fontScale,
            color: defaultTextColor,
            fontFamily: 'monospace',
          ),
        ),
      );
    } else if (ias != null) {
      columnChildren.add(
        _buildSpeedRow(
          ias.toStringAsFixed(0).padLeft(3),
          unitLabel,
          speedValueColor,
          defaultTextColor,
          fontScale,
        ),
      );
    } else if (gs != null) {
      columnChildren.add(
        _buildSpeedRow(
          gs.toStringAsFixed(0).padLeft(3),
          unitLabel,
          speedValueColor,
          defaultTextColor,
          fontScale,
        ),
      );
    } else {
      columnChildren.add(
        _buildSpeedRow(
          l10n.placeholderDash,
          unitLabel,
          speedValueColor,
          defaultTextColor,
          fontScale,
        ),
      );
    }

    return TelemetryCard(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => const SpeedDetailsDialog(),
        );
      },
      state: speedState,
      padding: EdgeInsets.symmetric(
        horizontal: 12.0 * fontScale,
        vertical: 8.0 * fontScale,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: columnChildren,
      ),
    );
  }
}
