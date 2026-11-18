import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/stork_detail_surface.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../map/presentation/components/dialogs/base_details_dialog.dart';
import '../../../map/presentation/providers/airport_metadata_provider.dart';
import '../../../navigation/presentation/providers/navigation_provider.dart';
import '../../../navigation/presentation/providers/navigation_eta_provider.dart';
import '../../../settings/domain/models/speed_unit.dart';
import '../../../settings/domain/models/temperature_unit.dart';
import '../../../settings/presentation/providers/aircraft_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../telemetry/presentation/widgets/telemetry_card.dart';
import '../../data/repositories/flight_forecast_repository.dart';
import '../../domain/flight_forecast.dart';
import '../../domain/forecast_reference.dart';
import '../../domain/weather_hazard.dart';
import '../../domain/wind_route_timing.dart';
import '../components/weather_attribution_link.dart';
import '../providers/flight_weather_provider.dart';
import 'waypoint_altitude_dialog.dart';

void showFlightWeatherDetails(
  BuildContext context,
  String pointId, {
  String? airportId,
  String? airportCountry,
}) {
  showDialog<void>(
    context: context,
    builder: (_) => FlightWeatherDetailsDialog(
      pointId: pointId,
      airportId: airportId,
      airportCountry: airportCountry,
    ),
  );
}

class FlightWeatherDetailsDialog extends ConsumerWidget {
  final String pointId;
  final String? airportId;
  final String? airportCountry;

  const FlightWeatherDetailsDialog({
    super.key,
    required this.pointId,
    this.airportId,
    this.airportCountry,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final dateTime = DateFormat.yMMMd(l10n.localeName).add_Hm();
    final dateOnly = DateFormat.yMMMd(l10n.localeName);
    final hour = DateFormat.Hm(l10n.localeName);
    final number = NumberFormat.decimalPattern(l10n.localeName);
    final settings = ref.watch(appSettingsProvider).value;
    final aircraft = ref.watch(selectedAircraftProvider);
    final point = weatherPoint(ref.watch(flightWeatherPlanProvider), pointId);
    final route =
        ref.watch(navigationProvider).value?.points ??
        const <NavigationPoint>[];
    final index = point?.waypointIndex;
    final waypoint = index != null && index < route.length
        ? route[index]
        : null;
    final title = waypoint != null
        ? l10n.weatherPointDetails
        : l10n.weatherSampleDetails;
    if (point == null) {
      return BaseDetailsDialog(
        titleText: title,
        child: Text(l10n.weatherForecastUnavailable),
      );
    }
    final timing = ref.watch(routePointTimingProvider)[point.id];
    final eta = timing == null ? point.eta : timing.eta;
    final duration = timing == null ? point.duration : timing.duration;
    final id = waypoint?.airportId ?? airportId;
    final country = waypoint?.airportCountry ?? airportCountry;
    final airport =
        id != null && id.isNotEmpty && country != null && country.isNotEmpty
        ? ref.watch(airportMetadataProvider(id, country)).value
        : null;
    final airportMeters = airportElevationMeters(airport);
    final terrain = ref
        .watch(forecastPointTerrainProvider(point.location))
        .value;
    final reference = airportMeters ?? terrain;
    final enabled = settings?.showFlightWeather ?? false;
    final profiles = enabled ? ref.watch(flightForecastProfilesProvider) : null;
    final location = enabled ? forecastProfileLocation(point) : point.location;
    final altitude = point.altitudeFeet;
    final altitudeMeters = altitude == null ? null : altitude * feetInMeters;
    final series = enabled
        ? profiles?.value?.series[forecastLocationKey(location)]
        : null;
    final forecast = eta == null
        ? null
        : series?.at(
            eta,
            altitudeMeters: altitudeMeters,
            terrainMeters: terrain ?? airportMeters,
            pressureReferenceMeters: reference,
          );
    final speedUnit = settings?.windSpeedUnit ?? SpeedUnit.kmh;
    final temperatureUnit =
        settings?.temperatureUnit ?? TemperatureUnit.celsius;
    final wind = forecast?.wind;
    final bearing = point.bearing;
    final components = wind != null && bearing != null
        ? wind.relativeTo(bearing)
        : null;
    final intervalEnd = forecast?.intervalEnd?.toUtc();
    final interval = intervalEnd == null
        ? null
        : '${hour.format(intervalEnd.subtract(const Duration(hours: 1)))}–${hour.format(intervalEnd)} ${l10n.clockUtc}';
    String speed(double value) =>
        '${number.format(speedUnit.convertFromMs(value).round())} ${speedUnit.getAbbreviation(l10n)}';

    final waypointName = waypoint?.name.trim() ?? '';
    final pointName = waypointName.isNotEmpty
        ? waypointName
        : point.id == 'origin'
        ? l10n.weatherRouteStart
        : title;
    final windValue = switch (wind) {
      final ForecastWind w when w.speedMs < 0.05 => l10n.weatherCalm,
      final ForecastWind w =>
        '${(w.directionFrom.round() % 360).toString().padLeft(3, '0')}° · ${speed(w.speedMs)}',
      _
          when altitudeMeters != null &&
              reference != null &&
              altitudeMeters < reference =>
        l10n.weatherBelowTerrain,
      _ => l10n.weatherWindUnavailable,
    };
    final qfeNote = reference == null
        ? null
        : '${airportMeters != null ? l10n.weatherQfeAirport : l10n.weatherQfeTerrain} · ${number.format((reference / feetInMeters).round())} ${l10n.weatherAltitudeFt}';
    final blocked = timing?.sources.contains(RouteTimingSource.blocked) == true;
    final isDark = theme.brightness == Brightness.dark;
    final warningColor = TelemetryCard.warningColor(isDark: isDark);
    final coldColor = isDark
        ? Colors.lightBlueAccent
        : Colors.lightBlue.shade700;
    final warmColor = isDark ? Colors.orangeAccent : Colors.orange.shade700;
    final cloudColor = isDark
        ? Colors.blueGrey.shade200
        : Colors.blueGrey.shade600;
    final hazards = forecast == null
        ? const <WeatherHazard>{}
        : forecastHazards(
            forecast,
            windLimitMs: aircraft?.dangerousWindMs,
            gustLimitMs: aircraft?.dangerousGustMs,
          );

    return BaseDetailsDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            pointName,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '${point.location.latitude.toStringAsFixed(4)}, '
            '${point.location.longitude.toStringAsFixed(4)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
      icon: waypoint != null ? Icons.place_outlined : Icons.air_outlined,
      maxWidth: 450,
      maxHeight: 600,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _MetricCard(
                    label: l10n.etaLabel,
                    value: eta == null
                        ? l10n.placeholderDash
                        : hour.format(eta.toUtc()),
                    note: eta == null
                        ? null
                        : '${dateOnly.format(eta.toUtc())} · ${l10n.clockUtc}',
                    highlighted: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MetricCard(
                    label: l10n.weatherPlannedAltitude,
                    value: altitude == null
                        ? l10n.placeholderDash
                        : number.format(altitude.round()),
                    note: l10n.weatherAltitudeFt,
                    onTap: waypoint == null
                        ? null
                        : () => unawaited(
                            showWaypointAltitudeDialog(
                              context,
                              ref,
                              waypoint: waypoint,
                              defaultFeet: aircraft?.weatherAltitudeFeet,
                              forecastPoint: point,
                              eta: eta,
                              series: series,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
          if (altitude == null) ...[
            const SizedBox(height: 8),
            Text(
              l10n.weatherMissingAltitude,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
          if (point.distanceMeters > 0) ...[
            const SizedBox(height: 8),
            Text(
              '${l10n.distanceFromUsLabel}: '
              '${number.format((point.distanceMeters / 100).round() / 10)} km'
              ' · ${duration == null ? l10n.placeholderDash : '${number.format((duration.inSeconds / 60).ceil())} ${l10n.minutesAbbrev}'}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (!enabled)
            _StatusNote(l10n.weatherDisabled)
          else if (blocked)
            _StatusNote(l10n.navigationEtaBlocked)
          else if (forecast == null)
            if (profiles?.isLoading == true)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: LinearProgressIndicator(),
                ),
              )
            else
              _StatusNote(l10n.weatherForecastUnavailable)
          else ...[
            _Section(
              title: l10n.weatherSectionAir,
              children: [
                _WeatherRow(
                  icon: Icons.air,
                  iconColor: colors.primary,
                  label: l10n.weatherWindAtAltitude,
                  value: windValue,
                  danger: hazards.contains(WeatherHazard.wind),
                ),
                if (forecast.gustMs case final gust?)
                  _WeatherRow(
                    icon: Icons.speed,
                    iconColor: warningColor,
                    label: l10n.weatherSurfaceGusts,
                    value: speed(gust),
                    note: interval,
                    danger: hazards.contains(WeatherHazard.gust),
                  ),
                if (components != null) ...[
                  _WeatherRow(
                    icon: Icons.swap_vert,
                    iconColor: colors.tertiary,
                    label: components.headwind < 0
                        ? l10n.weatherTailwind
                        : l10n.weatherHeadwind,
                    value: speed(components.headwind.abs()),
                  ),
                  _WeatherRow(
                    icon: Icons.swap_horiz,
                    iconColor: colors.tertiary,
                    label: components.fromRight < 0
                        ? l10n.weatherCrosswindLeft
                        : l10n.weatherCrosswindRight,
                    value: speed(components.fromRight.abs()),
                  ),
                ],
                if (forecast.temperatureC case final temperature?)
                  _WeatherRow(
                    icon: Icons.thermostat,
                    iconColor: temperature <= 0
                        ? coldColor
                        : temperature >= 30
                        ? warmColor
                        : colors.primary,
                    label: l10n.weatherTemperature,
                    value:
                        '${number.format(temperatureUnit.convertFromKelvin(temperature + 273.15).round())} '
                        '${temperatureUnit.getAbbreviation()}',
                  ),
                if (forecast.precipitationMm case final precipitation?)
                  _WeatherRow(
                    icon: Icons.water_drop_outlined,
                    iconColor: coldColor,
                    label: l10n.weatherPrecipitation,
                    value: '${number.format(precipitation)} mm',
                    note: interval,
                    danger: hazards.contains(WeatherHazard.precipitation),
                  ),
                if (forecast.lowCloudPercent case final cloud?)
                  _WeatherRow(
                    icon: Icons.cloud_outlined,
                    iconColor: cloudColor,
                    label: l10n.weatherLowCloud,
                    value: '${number.format(cloud.round())} %',
                    danger: hazards.contains(WeatherHazard.fog),
                  ),
              ],
            ),
            if (forecast.qnhHpa != null || qfeNote != null) ...[
              const SizedBox(height: 12),
              _Section(
                title: l10n.weatherSectionPressure,
                children: [
                  if (forecast.qnhHpa case final qnh?)
                    _WeatherRow(
                      icon: Icons.compress,
                      iconColor: colors.primary,
                      label: l10n.weatherModelQnh,
                      value: '${number.format(qnh.round())} hPa',
                    ),
                  if (forecast.qfeHpa case final qfe?)
                    if (qfeNote != null)
                      _WeatherRow(
                        icon: Icons.height,
                        iconColor: warningColor,
                        label: l10n.weatherModelQfe,
                        value: '${number.format(qfe.round())} hPa',
                        note: qfeNote,
                      ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Text(
              '${l10n.weatherDownloaded}: '
              '${dateTime.format(forecast.downloadedAt.toUtc())} ${l10n.clockUtc}'
              '${profiles?.value?.refreshFailed == true ? ' · ${l10n.weatherCached}' : ''}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const WeatherAttributionLink(),
          ],
        ],
      ),
    );
  }
}

/// Compact card showing a single headline value, used for ETA and altitude.
class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String? note;
  final bool highlighted;
  final VoidCallback? onTap;

  const _MetricCard({
    required this.label,
    required this.value,
    this.note,
    this.highlighted = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return StorkDetailSurface(
      padding: const EdgeInsets.all(12),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (onTap != null)
                  Icon(
                    Icons.edit_outlined,
                    size: 16,
                    color: colors.onSurfaceVariant,
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                color: highlighted ? colors.primary : colors.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (note case final note?)
              Text(
                note,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }
}

/// Labelled group of readings rendered on a shared detail surface.
class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        StorkDetailSurface(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var index = 0; index < children.length; index++) ...[
                if (index > 0)
                  Divider(height: 20, color: theme.colorScheme.outlineVariant),
                children[index],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _WeatherRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String? note;
  final bool danger;

  const _WeatherRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.note,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: danger ? colors.error : iconColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              if (note case final note?)
                Text(
                  note,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (danger) ...[
                Icon(
                  Icons.warning_amber_rounded,
                  size: 16,
                  color: colors.error,
                ),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    color: danger ? colors.error : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusNote extends StatelessWidget {
  final String message;

  const _StatusNote(this.message);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
