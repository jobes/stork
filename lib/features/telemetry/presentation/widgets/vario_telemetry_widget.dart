import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../settings/domain/models/range_thresholds.dart';
import '../providers/vario_provider.dart';
import '../dialogs/vario_details_dialog.dart';
import 'telemetry_card.dart';

class VarioTelemetryWidget extends ConsumerWidget {
  const VarioTelemetryWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final varioState = ref.watch(varioProvider);
    final l10n = AppLocalizations.of(context)!;
    final fontScale = ref.watch(
      appSettingsProvider.select(
        (s) => (s.value?.mapFontSize ?? 1.0).toDouble(),
      ),
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultTextColor = isDark
        ? Colors.grey.shade300
        : Colors.grey.shade700;
    final valueColor = isDark ? Colors.white : Colors.black;

    final String valueStr;
    final bool hasData = varioState.verticalSpeed != null;
    final ThresholdState cardState = hasData
        ? ThresholdState.operational
        : ThresholdState.inactive;

    if (hasData) {
      final v = varioState.verticalSpeed!;
      if (v.abs() < 0.05) {
        valueStr = '0.0';
      } else {
        final sign = v >= 0 ? '+' : '';
        valueStr = '$sign${v.toStringAsFixed(1)}';
      }
    } else {
      valueStr = l10n.placeholderDash;
    }

    return TelemetryCard(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => const VarioDetailsDialog(),
        );
      },
      state: cardState,
      padding: EdgeInsets.symmetric(
        horizontal: 12.0 * fontScale,
        vertical: 8.0 * fontScale,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              SizedBox(
                width: 100 * fontScale,
                child: Text(
                  valueStr,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: 32 * fontScale,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: valueColor,
                  ),
                ),
              ),
              SizedBox(width: 4 * fontScale),
              Text(
                l10n.varioUnitMs,
                style: TextStyle(
                  fontSize: 12 * fontScale,
                  color: defaultTextColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
