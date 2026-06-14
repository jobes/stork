import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../settings/domain/models/altitude_unit.dart';
import '../providers/agl_provider.dart';
import '../dialogs/altitude_details_dialog.dart';
import 'telemetry_card.dart';

class AltitudeTelemetryWidget extends ConsumerWidget {
  const AltitudeTelemetryWidget({super.key});

  Widget _buildAltitudeRow(
    String value,
    String unit,
    Color valueColor,
    Color unitColor,
    double fontScale, {
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
              fontSize: 16 * fontScale,
              fontWeight: FontWeight.bold,
              color: unitColor,
            ),
          ),
          SizedBox(width: 4 * fontScale),
        ],
        Text(
          value,
          style: TextStyle(
            fontSize: 32 * fontScale,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            color: valueColor,
            height: 1.0,
          ),
        ),
        if (unit.isNotEmpty) ...[
          SizedBox(width: 4 * fontScale),
          Text(unit, style: TextStyle(fontSize: 12 * fontScale, color: unitColor)),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resolved = ref.watch(resolvedAltitudeProvider);
    final aglState = ref.watch(aglProvider);
    final settings = ref.watch(appSettingsProvider).value;
    final l10n = AppLocalizations.of(context)!;
    final fontScale = (settings?.mapFontSize ?? 1.0).toDouble();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultTextColor = isDark
        ? Colors.grey.shade300
        : Colors.grey.shade700;

    final altitudeValueColor = isDark ? Colors.white : Colors.black;
    final activeUnit = settings?.altitudeUnit ?? AltitudeUnit.feet;

    final List<Widget> columnChildren = [];

    // Main altitude number & unit labels
    final String altitudeValueStr;
    final String altitudeUnitLabel;
    final String? prefix;

    if (activeUnit == AltitudeUnit.flightLevel) {
      altitudeValueStr =
          resolved.flightLevel?.toStringAsFixed(0).padLeft(4) ?? '----';
      altitudeUnitLabel = '';
      prefix = 'FL';
    } else {
      final double? mslValue = resolved.mslValue;
      altitudeValueStr = mslValue != null
          ? activeUnit.convertFromMeters(mslValue).toStringAsFixed(0).padLeft(4)
          : '----';
      altitudeUnitLabel = activeUnit.getMslLabel(l10n);
      prefix = null;
    }

    columnChildren.add(
      _buildAltitudeRow(
        altitudeValueStr,
        altitudeUnitLabel,
        altitudeValueColor,
        defaultTextColor,
        fontScale,
        prefix: prefix,
      ),
    );

    // Dynamic Second Row: Only displayed if heightAboveGround (AGL) is not null
    if (aglState.heightAboveGround != null) {
      final heightUnit = settings?.heightUnit ?? AltitudeUnit.meters;

      final double heightVal = heightUnit.convertFromMeters(
        aglState.heightAboveGround!,
      );
      final String heightStr = heightVal.toStringAsFixed(0);
      final String heightUnitLabel = heightUnit.getGndLabel(l10n);

      columnChildren.add(
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: EdgeInsets.only(top: 4.0 * fontScale),
            child: Text(
              '$heightStr $heightUnitLabel',
              style: TextStyle(
                fontSize: 12 * fontScale,
                fontWeight: FontWeight.bold,
                color: defaultTextColor,
                fontFamily: 'monospace',
              ),
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
      padding: EdgeInsets.symmetric(horizontal: 12 * fontScale, vertical: 8 * fontScale),
      child: IntrinsicWidth(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: columnChildren,
          ),
        ),
      ),
    );
  }
}
