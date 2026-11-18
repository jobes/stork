import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../route/presentation/providers/navigation_provider.dart';
import '../../../weather/presentation/providers/weather_hazard_provider.dart';
import '../../../settings/domain/models/range_thresholds.dart';
import '../../../weather/presentation/providers/navigation_eta_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../dialogs/navigation_details_dialog.dart';
import '../../../telemetry/presentation/widgets/telemetry_card.dart';

class NavigationTelemetryWidget extends ConsumerWidget {
  const NavigationTelemetryWidget({super.key});

  String _formatDurationNoSeconds(BuildContext context, Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final minStr = minutes.toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:$minStr';
    } else {
      return '$minutes ${AppLocalizations.of(context)!.minutesAbbrev}';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calculations = ref.watch(navigationEtaProvider);
    final weatherWarning = ref.watch(activeWeatherHazardsProvider).isNotEmpty;
    final settings = ref.watch(appSettingsProvider).value;
    final navigationAsync = ref.watch(navigationProvider);
    final fontScale = (settings?.mapControlScale ?? 1.0).toDouble();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultTextColor = isDark
        ? Colors.grey.shade400
        : Colors.grey.shade700;
    final valueColor = isDark ? Colors.white : Colors.black;

    return navigationAsync.when(
      data: (navState) {
        final points = navState.points;
        final isActive = navState.isActive;

        if (!isActive || points.isEmpty) {
          return const SizedBox.shrink();
        }

        final nearest = calculations.legs.firstOrNull;
        final destination = calculations.legs.lastOrNull;
        final timeToNearest = nearest?.eta == null
            ? null
            : nearest?.legDuration;
        final timeToDest = destination?.eta == null
            ? null
            : calculations.totalDuration;

        final hasMultiplePoints = points.length > 1;

        final l10n = AppLocalizations.of(context)!;
        final timeToNearestStr = timeToNearest != null
            ? _formatDurationNoSeconds(context, timeToNearest)
            : l10n.placeholderDash;
        final timeToDestStr = timeToDest != null
            ? _formatDurationNoSeconds(context, timeToDest)
            : l10n.placeholderDash;

        return TelemetryCard(
          state: weatherWarning
              ? ThresholdState.maxWarning
              : ThresholdState.operational,
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => const NavigationDetailsDialog(),
            );
          },
          padding: EdgeInsets.symmetric(
            horizontal: 12.0 * fontScale,
            vertical: 8.0 * fontScale,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasMultiplePoints) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_right_alt,
                      size: 20 * fontScale,
                      color: defaultTextColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      timeToNearestStr,
                      style: TextStyle(
                        fontSize: 22 * fontScale,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        color: valueColor,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 4.0 * fontScale),
                  child: Container(
                    height: 1,
                    width: 75 * fontScale,
                    color: isDark ? Colors.white12 : Colors.black12,
                  ),
                ),
              ],
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.flag_outlined,
                    size: 24 * fontScale,
                    color: defaultTextColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    timeToDestStr,
                    style: TextStyle(
                      fontSize: 28 * fontScale,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      color: valueColor,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, st) => const SizedBox.shrink(),
    );
  }
}
