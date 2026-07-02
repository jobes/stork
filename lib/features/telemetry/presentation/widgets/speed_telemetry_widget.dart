import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/cannelloni_service_io.dart'
    if (dart.library.html) '../../../../core/services/cannelloni_service_stub.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/telemetry_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../settings/domain/models/range_thresholds.dart';
import '../../../settings/domain/models/speed_unit.dart';
import '../dialogs/speed_details_dialog.dart';
import 'telemetry_card.dart';

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
    final indicatedAirSpeed = ref.watch(telemetryProvider.select((t) => t.indicatedAirSpeed));
    final groundSpeed = ref.watch(telemetryProvider.select((t) => t.groundSpeed));
    final isConnected = ref.watch(cannelloniServiceProvider);
    final settings = ref.watch(appSettingsProvider).value;
    final thresholds =
        settings?.flightSpeedThresholds ?? const RangeThresholds.raw();
    final l10n = AppLocalizations.of(context)!;
    final fontScale = (settings?.mapFontSize ?? 1.0).toDouble();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultTextColor = isDark
        ? Colors.grey.shade300
        : Colors.grey.shade700;

    final speedValueColor = isDark ? Colors.white : Colors.black;

    final speedUnit = settings?.speedUnit ?? SpeedUnit.kmh;
    final double? ias = indicatedAirSpeed != null
        ? speedUnit.convertFromMs(indicatedAirSpeed)
        : null;
    final double? gs = groundSpeed != null
        ? speedUnit.convertFromMs(groundSpeed)
        : null;
    final String unitLabel = speedUnit.getAbbreviation(l10n);

    ThresholdState speedState = ThresholdState.inactive;
    if (!isConnected) {
      if (groundSpeed != null) {
        speedState = thresholds.evaluate(groundSpeed);
      }
    } else {
      if (indicatedAirSpeed != null) {
        speedState = thresholds.evaluate(indicatedAirSpeed);
      } else if (groundSpeed != null) {
        speedState = thresholds.evaluate(groundSpeed);
      }
    }

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
