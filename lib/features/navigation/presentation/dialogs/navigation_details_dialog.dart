import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/number_formatter.dart';
import '../../../../core/widgets/stork_detail_surface.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../map/presentation/components/dialogs/base_details_dialog.dart';
import '../providers/navigation_provider.dart';
import '../../../settings/domain/models/speed_unit.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../telemetry/presentation/providers/throttled_telemetry_provider.dart';
import '../../../weather/domain/flight_forecast.dart';
import '../../../weather/domain/forecast_profile.dart';
import '../../../weather/domain/forecast_query.dart';
import '../../../weather/domain/forecast_route.dart';
import '../../../weather/domain/wind_route_timing.dart';
import '../../../weather/presentation/components/weather_attribution_link.dart';
import '../../../weather/presentation/components/weather_warning_summary.dart';
import '../../../weather/presentation/providers/flight_weather_provider.dart';
import '../../../weather/presentation/providers/route_timing_provider.dart';
import '../../../weather/presentation/providers/weather_hazard_provider.dart';
import '../providers/navigation_eta_provider.dart';
import '../utils/navigation_formatters.dart';
import '../utils/windy_route.dart';

class NavigationDetailsDialog extends ConsumerWidget {
  const NavigationDetailsDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final telemetry = ref.watch(throttledTelemetryProvider);
    final settings = ref.watch(appSettingsProvider).value;
    final navigationAsync = ref.watch(navigationProvider);
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final calculations = ref.watch(navigationEtaProvider);
    final forecastPoints = ref.watch(flightWeatherPlanProvider);
    final planByWaypoint = forecastPointsByWaypoint(forecastPoints);
    final timing = ref.watch(routePointTimingProvider);
    final profiles = ref.watch(flightForecastProfilesProvider).value;
    final references = settings?.showFlightWeather == true
        ? ref.watch(routeForecastReferencesProvider).value ??
              const <String, ForecastReference>{}
        : const <String, ForecastReference>{};
    final locations = settings?.showFlightWeather == true
        ? ref.watch(flightWeatherProfileLocationsProvider)
        : const <String, ForecastLocation>{};
    final speedUnit = settings?.windSpeedUnit ?? SpeedUnit.kmh;
    final hasWeatherWarnings = ref
        .watch(activeWeatherHazardDetailsProvider)
        .isNotEmpty;

    final defaultTextColor = scheme.onSurfaceVariant;
    final valueColor = scheme.onSurface;

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

        final hasLegs = calculations.legs.isNotEmpty;
        final distToNearest = hasLegs
            ? calculations.legs.first.legDistanceMeters
            : null;
        final distToDest = hasLegs ? calculations.totalDistanceMeters : null;
        final nearest = calculations.legs.firstOrNull;
        final destination = calculations.legs.lastOrNull;
        final timeToNearest = nearest?.eta == null
            ? null
            : nearest?.legDuration;
        final timeToDest = destination?.eta == null
            ? null
            : calculations.totalDuration;

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
            final etaWaypointFormatted = formatNavigationTimeUtc(
              context,
              leg.eta,
            );

            waypointWidgets.add(
              Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: scheme.onPrimaryContainer,
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
                                Icon(
                                  Icons.local_airport,
                                  size: 14,
                                  color: scheme.primary,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${l10n.leg}: ${context.formatNumber(legDistanceKm, 1)} km • ${leg.eta == null ? l10n.placeholderDash : formatNavigationDuration(context, legDuration)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: defaultTextColor,
                            ),
                          ),
                          Text(
                            '${l10n.total}: ${context.formatNumber(cumulativeDistanceKm, 1)} km • ${leg.eta == null ? l10n.placeholderDash : formatNavigationDuration(context, cumulativeDuration)} (${l10n.etaLabel}: $etaWaypointFormatted)',
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
                  color: scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: scheme.onPrimaryContainer,
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
                            Icon(
                              Icons.local_airport,
                              size: 14,
                              color: scheme.primary,
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
            ? '${context.formatNumber(distToNearest / 1000.0, 2)} km'
            : l10n.placeholderDash;
        final distToDestStr = distToDest != null
            ? '${context.formatNumber(distToDest / 1000.0, 2)} km'
            : l10n.placeholderDash;

        final timeToNearestStr = timeToNearest != null
            ? formatNavigationDuration(context, timeToNearest)
            : l10n.placeholderDash;
        final timeToDestStr = timeToDest != null
            ? formatNavigationDuration(context, timeToDest)
            : l10n.placeholderDash;

        final etaNearestStr = nearest?.eta != null
            ? formatNavigationTimeUtc(context, nearest?.eta)
            : null;
        final etaDestStr = destination?.eta != null
            ? formatNavigationTimeUtc(context, destination?.eta)
            : null;

        Widget forecastSummary(int index, {required bool includeGust}) {
          final point = planByWaypoint[index];
          if (point == null) return const SizedBox.shrink();
          return _buildForecastSummary(
            context,
            point,
            timing[point.id],
            profiles?.series[forecastLocationKey(
              locations[point.id] ?? point.location,
            )],
            references[point.id],
            speedUnit,
            includeGust: includeGust,
          );
        }

        return BaseDetailsDialog(
          titleText: l10n.navigationDetailsTitle,
          icon: Icons.explore,
          maxWidth: 450,
          maxHeight: 600, // Bound height to allow scrollable content
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const WeatherWarningSummary(),
              // Summary container
              StorkDetailSurface(
                padding: const EdgeInsets.all(16),
                radius: 16,
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
                      ),
                      forecastSummary(0, includeGust: false),
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
                    ),
                    forecastSummary(points.length - 1, includeGust: true),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                onPressed: () => openWindyRoute(
                  points,
                  currentLatitude: telemetry.latitude,
                  currentLongitude: telemetry.longitude,
                ),
                icon: const Icon(Icons.cloud_outlined),
                label: Text(l10n.weatherInWindy),
              ),
              if (!hasWeatherWarnings) const WeatherAttributionLink(),
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

  Widget _buildForecastSummary(
    BuildContext context,
    ForecastRoutePoint point,
    TimedRoutePoint? timing,
    ForecastProfile? series,
    ForecastReference? reference,
    SpeedUnit speedUnit, {
    required bool includeGust,
  }) {
    if (timing == null || timing.sources.isEmpty) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context)!;
    final blocked = timing.sources.contains(RouteTimingSource.blocked);
    final estimatedAt = timing.eta;
    final feet = point.altitudeFeet;
    final forecast = estimatedAt == null
        ? null
        : series?.atReference(
            estimatedAt,
            altitudeFeet: feet,
            reference: reference,
          );
    final values = <String>[];
    String speed(double ms) =>
        '${context.formatNumber(speedUnit.convertFromMs(ms), 0)} ${speedUnit.getAbbreviation(l10n)}';
    if (forecast?.wind case final wind?) {
      values.add(
        wind.speedMs < 0.05
            ? l10n.weatherCalm
            : '${l10n.weatherWindAtAltitude} · ${(wind.directionFrom.round() % 360).toString().padLeft(3, '0')}° ${speed(wind.speedMs)}',
      );
    }
    if (includeGust && forecast?.gustMs != null) {
      values.add('${l10n.weatherSurfaceGusts} · ${speed(forecast!.gustMs!)}');
    }
    final windMinutes = ((timing.windEffect?.inSeconds ?? 0) / 60).round();
    if (windMinutes != 0) {
      values.add(
        l10n.navigationWindTimeChange(
          '${windMinutes > 0 ? '+' : '−'}${context.formatNumber(windMinutes.abs().toDouble(), 0)}',
        ),
      );
    }
    final sources = timing.sources.map(
      (source) => switch (source) {
        RouteTimingSource.gps => l10n.navigationEtaGps,
        RouteTimingSource.wind => l10n.navigationEtaWind,
        RouteTimingSource.profile => l10n.navigationEtaProfile,
        RouteTimingSource.blocked => l10n.navigationEtaBlocked,
        RouteTimingSource.incompleteWind => l10n.weatherForecastUnavailable,
      },
    );
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          [
            if (blocked) l10n.navigationEtaBlocked else sources.join(' + '),
            ...values,
          ].join('\n'),
          style: Theme.of(context).textTheme.bodySmall,
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
  }) {
    final scheme = Theme.of(context).colorScheme;
    final defaultTextColor = scheme.onSurfaceVariant;
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
                  color: scheme.onSurface,
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
                    color: scheme.onSurface,
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
