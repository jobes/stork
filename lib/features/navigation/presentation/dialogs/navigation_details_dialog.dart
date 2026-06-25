import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clock/clock.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../settings/domain/models/speed_unit.dart';
import '../../../telemetry/presentation/providers/throttled_telemetry_provider.dart';
import '../providers/navigation_provider.dart';
import '../../../map/presentation/components/dialogs/base_details_dialog.dart';

class NavigationDetailsDialog extends ConsumerWidget {
  const NavigationDetailsDialog({super.key});

  String _formatEta(BuildContext context, DateTime? dateTime) {
    if (dateTime == null) return AppLocalizations.of(context)!.placeholderDash;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

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
    final telemetry = ref.watch(throttledTelemetryProvider);
    final settings = ref.watch(appSettingsProvider).value;
    final navigationAsync = ref.watch(navigationProvider);
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = clock.now();

    final defaultTextColor = isDark ? Colors.white70 : Colors.black87;
    final valueColor = isDark ? Colors.white : Colors.black87;

    return navigationAsync.when(
      data: (navState) {
        final points = navState.points;

        if (points.isEmpty) {
          return BaseDetailsDialog(
            titleText: l10n.navigationDetailsTitle,
            icon: Icons.explore,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  l10n.noNavigationPoints,
                  style: TextStyle(color: defaultTextColor),
                ),
              ),
            ),
          );
        }

        final currentPositionKnown =
            telemetry.latitude != null &&
            telemetry.longitude != null &&
            telemetry.latitude != 0.0 &&
            telemetry.longitude != 0.0;

        final useRealSpeed =
            telemetry.isFlying &&
            telemetry.groundSpeed != null &&
            telemetry.groundSpeed! > 0;
        final activeSpeedMs = useRealSpeed
            ? telemetry.groundSpeed!
            : (settings?.averageSpeed ?? 27.78);
        final speedUnit = settings?.speedUnit ?? SpeedUnit.kmh;
        final speedValFormatted = speedUnit
            .convertFromMs(activeSpeedMs)
            .toStringAsFixed(0);
        final speedUnitAbbr = speedUnit.getAbbreviation(l10n);

        final calculations = NavigationCalculations.calculate(
          points: points,
          currentLatitude: telemetry.latitude,
          currentLongitude: telemetry.longitude,
          activeSpeedMs: activeSpeedMs,
          now: now,
        );

        final hasLegs = calculations.legs.isNotEmpty;
        final distToNearest = hasLegs
            ? calculations.legs.first.legDistanceMeters
            : null;
        final distToDest = hasLegs ? calculations.totalDistanceMeters : null;
        final timeToNearest = hasLegs
            ? calculations.legs.first.legDuration
            : null;
        final timeToDest = hasLegs ? calculations.totalDuration : null;

        final hasMultiplePoints = points.length > 1;

        // Calculate legs list for waypoint list display
        final List<Widget> waypointWidgets = [];
        if (currentPositionKnown && hasLegs) {
          for (int index = 0; index < calculations.legs.length; index++) {
            final leg = calculations.legs[index];
            final p = leg.point;
            final legDistanceKm = leg.legDistanceMeters / 1000.0;
            final legDuration = leg.legDuration;
            final cumulativeDistanceKm = leg.cumulativeDistanceMeters / 1000.0;
            final cumulativeDuration = leg.cumulativeDuration;
            final etaWaypointFormatted = _formatEta(context, leg.eta);

            waypointWidgets.add(
              Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withAlpha(8)
                      : Colors.black.withAlpha(5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.white12 : Colors.black12,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withAlpha(20),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  p.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: valueColor,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (p.isAirport) ...[
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.local_airport,
                                  size: 14,
                                  color: Colors.blueAccent,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${l10n.leg}: ${legDistanceKm.toStringAsFixed(1)} km • ${_formatDurationNoSeconds(context, legDuration)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: defaultTextColor,
                            ),
                          ),
                          Text(
                            '${l10n.total}: ${cumulativeDistanceKm.toStringAsFixed(1)} km • ${_formatDurationNoSeconds(context, cumulativeDuration)} (${l10n.etaLabel}: $etaWaypointFormatted)',
                            style: TextStyle(
                              fontSize: 11,
                              color: defaultTextColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        } else {
          // If current position is not known, just list points without ETA/Leg info
          for (int index = 0; index < points.length; index++) {
            final p = points[index];
            waypointWidgets.add(
              Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withAlpha(8)
                      : Colors.black.withAlpha(5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.white12 : Colors.black12,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withAlpha(20),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              p.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: valueColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (p.isAirport) ...[
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.local_airport,
                              size: 14,
                              color: Colors.blueAccent,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        }

        final nearestPointName = points.first.name;
        final destPointName = points.last.name;

        final distToNearestStr = distToNearest != null
            ? '${(distToNearest / 1000.0).toStringAsFixed(2)} km'
            : l10n.placeholderDash;
        final distToDestStr = distToDest != null
            ? '${(distToDest / 1000.0).toStringAsFixed(2)} km'
            : l10n.placeholderDash;

        final timeToNearestStr = timeToNearest != null
            ? _formatDurationNoSeconds(context, timeToNearest)
            : l10n.placeholderDash;
        final timeToDestStr = timeToDest != null
            ? _formatDurationNoSeconds(context, timeToDest)
            : l10n.placeholderDash;

        final etaNearestStr = timeToNearest != null
            ? _formatEta(context, now.add(timeToNearest))
            : null;
        final etaDestStr = timeToDest != null
            ? _formatEta(context, now.add(timeToDest))
            : null;

        return BaseDetailsDialog(
          titleText: l10n.navigationDetailsTitle,
          icon: Icons.explore,
          maxWidth: 450,
          maxHeight: 600, // Bound height to allow scrollable content
          child: Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Summary container
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withAlpha(15)
                          : Colors.black.withAlpha(10),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.white12 : Colors.black12,
                      ),
                    ),
                    child: Column(
                      children: [
                        if (hasMultiplePoints) ...[
                          _buildDetailRow(
                            context: context,
                            icon: Icons.arrow_right_alt,
                            iconColor: Colors.orangeAccent,
                            label: '${l10n.nearestPoint} ($nearestPointName)',
                            distance: distToNearestStr,
                            time: timeToNearestStr,
                            eta: etaNearestStr,
                            isDark: isDark,
                          ),
                          const Divider(height: 20),
                        ],
                        _buildDetailRow(
                          context: context,
                          icon: Icons.flag_outlined,
                          iconColor: Colors.green,
                          label: '${l10n.destinationPoint} ($destPointName)',
                          distance: distToDestStr,
                          time: timeToDestStr,
                          eta: etaDestStr,
                          isDark: isDark,
                        ),
                        const Divider(height: 20),
                        Row(
                          children: [
                            Icon(
                              Icons.speed_outlined,
                              size: 16,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                l10n.activeSpeedLabel(
                                  speedValFormatted,
                                  speedUnitAbbr,
                                ),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: defaultTextColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.waypointsList,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: valueColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...waypointWidgets,
                ],
              ),
            ),
          ),
        );
      },
      loading: () => BaseDetailsDialog(
        titleText: l10n.navigationDetailsTitle,
        icon: Icons.explore,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, st) => BaseDetailsDialog(
        titleText: l10n.navigationDetailsTitle,
        icon: Icons.explore,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(child: Text(e.toString())),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String distance,
    required String time,
    required String? eta,
    required bool isDark,
  }) {
    final defaultTextColor = isDark ? Colors.white70 : Colors.black87;
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 26),
              child: Text(
                distance,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: defaultTextColor,
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                if (eta != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${l10n.etaLabel}: $eta',
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: defaultTextColor,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ],
    );
  }
}
