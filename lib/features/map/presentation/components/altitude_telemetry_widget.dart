import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../telemetry/presentation/providers/telemetry_provider.dart';
import '../../../telemetry/domain/models/resolved_altitude.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../settings/domain/altitude_unit.dart';
import 'altitude_details_dialog.dart';
import 'telemetry_card.dart';

class AltitudeTelemetryWidget extends ConsumerWidget {
  const AltitudeTelemetryWidget({super.key});

  Widget _buildAltitudeRow(
    String value,
    String unit,
    Color valueColor,
    Color unitColor, {
    String? prefix,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        if (prefix != null && prefix.isNotEmpty) ...[
          Text(
            prefix,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: unitColor,
            ),
          ),
          const SizedBox(width: 4),
        ],
        Text(
          value,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            color: valueColor,
          ),
        ),
        if (unit.isNotEmpty) ...[
          const SizedBox(width: 4),
          Text(unit, style: TextStyle(fontSize: 12, color: unitColor)),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final telemetry = ref.watch(telemetryProvider);
    final settings = ref.watch(appSettingsProvider).value;
    final l10n = AppLocalizations.of(context)!;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultTextColor = isDark
        ? Colors.grey.shade300
        : Colors.grey.shade700;

    final altitudeValueColor = isDark ? Colors.white : Colors.black;
    final activeUnit = settings?.altitudeUnit ?? AltitudeUnit.feet;

    // Resolve altitude values using the domain model extension
    final resolved = telemetry.resolveAltitude(settings);

    final List<Widget> columnChildren = [];

    // Main altitude number & unit labels
    if (activeUnit == AltitudeUnit.flightLevel) {
      if (resolved.flightLevel != null) {
        columnChildren.add(
          _buildAltitudeRow(
            resolved.flightLevel!.toStringAsFixed(0).padLeft(4),
            '',
            altitudeValueColor,
            defaultTextColor,
            prefix: 'FL',
          ),
        );
      } else {
        columnChildren.add(
          _buildAltitudeRow(
            '----',
            '',
            altitudeValueColor,
            defaultTextColor,
            prefix: 'FL',
          ),
        );
      }
    } else {
      if (resolved.mslValue != null) {
        final double converted = activeUnit.convertFromMeters(resolved.mslValue!);
        columnChildren.add(
          _buildAltitudeRow(
            converted.toStringAsFixed(0).padLeft(4),
            activeUnit.getMslLabel(l10n),
            altitudeValueColor,
            defaultTextColor,
          ),
        );
      } else {
        columnChildren.add(
          _buildAltitudeRow(
            '----',
            activeUnit.getMslLabel(l10n),
            altitudeValueColor,
            defaultTextColor,
          ),
        );
      }
    }

    // Dynamic Second Row: Only displayed if heightAboveGround (AGL) is not null
    if (telemetry.heightAboveGround != null) {
      final heightUnit = settings?.heightUnit ?? AltitudeUnit.meters;

      final double heightVal = heightUnit.convertFromMeters(
        telemetry.heightAboveGround!,
      );
      final String heightStr = heightVal.toStringAsFixed(0);
      final String heightUnitLabel = heightUnit.getGndLabel(l10n);

      columnChildren.add(
        Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            '$heightStr $heightUnitLabel',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: defaultTextColor,
              fontFamily: 'monospace',
            ),
          ),
        ),
      );
    }

    // Constant operational style coordinates with SpeedTelemetryWidget for consistent premium feel
    final borderColor = isDark
        ? Colors.white.withAlpha(76)
        : Colors.black.withAlpha(51);

    return TelemetryCard(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => const AltitudeDetailsDialog(),
        );
      },
      borderColor: borderColor,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: columnChildren,
      ),
    );
  }
}
