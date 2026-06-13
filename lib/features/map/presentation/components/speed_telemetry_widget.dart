import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/cannelloni_service_io.dart'
    if (dart.library.html) '../../../../core/services/cannelloni_service_stub.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../telemetry/presentation/providers/telemetry_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../settings/domain/range_thresholds.dart';
import '../../../settings/domain/speed_unit.dart';
import 'speed_details_dialog.dart';
import 'telemetry_card.dart';

class SpeedTelemetryWidget extends ConsumerWidget {
  const SpeedTelemetryWidget({super.key});

  Color _getBorderColor(ThresholdState state, bool isDark) {
    switch (state) {
      case ThresholdState.inactive:
      case ThresholdState.operational:
        return isDark
            ? Colors.white.withAlpha(
                76,
              ) // Increased visibility in dark mode (30% alpha)
            : Colors.black.withAlpha(
                51,
              ); // Increased visibility in light mode (20% alpha)
      case ThresholdState.minError:
      case ThresholdState.maxError:
        return isDark ? Colors.redAccent.shade200 : Colors.red.shade600;
      case ThresholdState.minWarning:
      case ThresholdState.maxWarning:
        return isDark ? Colors.orangeAccent : Colors.orange.shade700;
    }
  }

  double _getBorderWidth(ThresholdState state) {
    return 2.0; // Constant width prevents layout shifting between states
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
            color: color.withAlpha(102), // Glow effect
            blurRadius: 16,
            spreadRadius: 3,
          ),
        ];
      case ThresholdState.minWarning:
      case ThresholdState.maxWarning:
        final color = isDark ? Colors.amber : Colors.orange.shade800;
        return [
          BoxShadow(
            color: color.withAlpha(102), // Glow effect
            blurRadius: 16,
            spreadRadius: 3,
          ),
        ];
    }
  }

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
        Text(unit, style: TextStyle(fontSize: 12 * fontScale, color: unitColor)),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final telemetry = ref.watch(telemetryProvider);
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
    final double? ias = telemetry.indicatedAirSpeed != null
        ? speedUnit.convertFromMs(telemetry.indicatedAirSpeed!)
        : null;
    final double? gs = telemetry.groundSpeed != null
        ? speedUnit.convertFromMs(telemetry.groundSpeed!)
        : null;
    final String unitLabel = speedUnit.getAbbreviation(l10n);

    ThresholdState speedState = ThresholdState.inactive;
    if (!isConnected) {
      if (telemetry.groundSpeed != null) {
        speedState = thresholds.evaluate(telemetry.groundSpeed!);
      }
    } else {
      if (telemetry.indicatedAirSpeed != null) {
        speedState = thresholds.evaluate(telemetry.indicatedAirSpeed!);
      } else if (telemetry.groundSpeed != null) {
        speedState = thresholds.evaluate(telemetry.groundSpeed!);
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
        _buildSpeedRow(l10n.placeholderDash, unitLabel, speedValueColor, defaultTextColor, fontScale),
      );
    }

    return TelemetryCard(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => const SpeedDetailsDialog(),
        );
      },
      boxShadow: _getBoxShadow(speedState, isDark),
      borderColor: _getBorderColor(speedState, isDark),
      borderWidth: _getBorderWidth(speedState),
      padding: EdgeInsets.symmetric(horizontal: 12.0 * fontScale, vertical: 8.0 * fontScale),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: columnChildren,
      ),
    );
  }
}
