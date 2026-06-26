import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/time_utils.dart';
import '../providers/telemetry_provider.dart';
import '../providers/flight_duration_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import 'telemetry_card.dart';
import '../dialogs/flight_time_details_dialog.dart';

class FlightTimeTelemetryWidget extends ConsumerWidget {
  const FlightTimeTelemetryWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFlying = ref.watch(telemetryProvider.select((s) => s.isFlying));
    final flightSummary = ref.watch(flightDurationProvider);
    final settings = ref.watch(appSettingsProvider).value;
    final fontScale = (settings?.mapFontSize ?? 1.0).toDouble();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color timeColor;
    if (isFlying) {
      timeColor = isDark ? Colors.white : Colors.black;
    } else {
      timeColor = isDark
          ? Colors.white.withAlpha(76)
          : Colors.black.withAlpha(76);
    }

    final formattedTime = flightSummary.duration.toHMSString();

    return TelemetryCard(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => const FlightTimeDetailsDialog(),
        );
      },
      padding: EdgeInsets.symmetric(
        horizontal: 12.0 * fontScale,
        vertical: 8.0 * fontScale,
      ),
      child: Text(
        formattedTime,
        style: TextStyle(
          fontSize: 32 * fontScale,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
          color: timeColor,
          height: 1.0,
        ),
      ),
    );
  }
}
