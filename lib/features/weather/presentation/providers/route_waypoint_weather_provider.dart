import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/services/terrain_elevation_service.dart';
import '../../../map/presentation/providers/airport_metadata_provider.dart';
import '../../../navigation/presentation/providers/navigation_eta_provider.dart';
import '../../../navigation/presentation/providers/navigation_provider.dart';
import '../../../settings/presentation/providers/aircraft_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../data/models/forecast_series.dart';
import '../../data/repositories/flight_forecast_repository.dart';
import '../../domain/flight_forecast.dart';
import '../../domain/forecast_reference.dart';
import '../../domain/forecast_route.dart';
import '../../domain/weather_hazard.dart';
import '../../domain/wind_route_timing.dart';
import 'flight_weather_provider.dart';

part 'route_waypoint_weather_provider.g.dart';

typedef RouteWaypointWeather = ({
  DateTime? eta,
  Duration? duration,
  Set<RouteTimingSource> sources,
  Duration? windEffect,
  bool blocked,
  double? altitudeFeet,
  ForecastWind? wind,
  double? gustMs,
  double? temperatureC,
  DateTime? intervalEnd,
  Set<WeatherHazard> hazards,
  bool forecastAvailable,
});

/// Forecast at each route waypoint, keyed by the waypoint index in the
/// navigation route. Uses the same timing and profile data as the point
/// details so the route list and the dialogs never disagree.
@riverpod
Map<int, RouteWaypointWeather> routeWaypointWeather(Ref ref) {
  final enabled = ref.watch(
    appSettingsProvider.select((s) => s.value?.showFlightWeather ?? false),
  );
  final points = ref.watch(flightWeatherPlanProvider);
  final timing = ref.watch(routePointTimingProvider);
  final profiles = enabled
      ? ref.watch(flightForecastProfilesProvider).value
      : null;
  final aircraft = ref.watch(selectedAircraftProvider);
  final terrain = enabled ? ref.watch(terrainElevationServiceProvider) : null;

  return {
    for (final point in points)
      ?point.waypointIndex: _weatherForPoint(
        point,
        timing: timing[point.id],
        series: enabled
            ? profiles?.series[forecastLocationKey(
                forecastProfileLocation(point),
              )]
            : null,
        terrainMeters: terrain?.getCachedElevation(
          point.location.latitude,
          point.location.longitude,
        ),
        windLimitMs: aircraft?.dangerousWindMs,
        gustLimitMs: aircraft?.dangerousGustMs,
      ),
  };
}

RouteWaypointWeather _weatherForPoint(
  ForecastRoutePoint point, {
  required TimedRoutePoint? timing,
  required ForecastSeries? series,
  required double? terrainMeters,
  required double? windLimitMs,
  required double? gustLimitMs,
}) {
  final eta = timing == null ? point.eta : timing.eta;
  final altitudeFeet = point.altitudeFeet;
  final forecast = series != null && eta != null && altitudeFeet != null
      ? series.at(
          eta,
          altitudeMeters: altitudeFeet * feetInMeters,
          terrainMeters: terrainMeters,
        )
      : null;
  return (
    eta: eta,
    duration: timing == null ? point.duration : timing.duration,
    sources: timing?.sources ?? const <RouteTimingSource>{},
    windEffect: timing?.windEffect,
    blocked: timing?.sources.contains(RouteTimingSource.blocked) ?? false,
    altitudeFeet: altitudeFeet,
    wind: forecast?.wind,
    gustMs: forecast?.gustMs,
    temperatureC: forecast?.temperatureC,
    intervalEnd: forecast?.intervalEnd,
    hazards: forecast == null
        ? const <WeatherHazard>{}
        : forecastHazards(
            forecast,
            windLimitMs: windLimitMs,
            gustLimitMs: gustLimitMs,
          ),
    forecastAvailable: forecast != null,
  );
}

typedef RoutePointWind = ({ForecastWind? wind, double? gustMs});

/// Wind and surface gusts at every forecast point for its estimated arrival
/// time. Uses the same wind-adjusted timing as the route list.
@riverpod
Future<Map<String, RoutePointWind>> routePointWinds(Ref ref) async {
  final enabled = ref.watch(
    appSettingsProvider.select((s) => s.value?.showFlightWeather ?? false),
  );
  final points = ref.watch(flightWeatherPlanProvider);
  final route =
      ref.watch(navigationProvider).value?.points ?? const <NavigationPoint>[];
  if (!enabled || points.isEmpty) return const {};
  final profiles = ref.watch(flightForecastProfilesProvider).value;
  if (profiles == null) return const {};
  final timing = ref.watch(routePointTimingProvider);

  final winds = await Future.wait([
    for (final point in points)
      _pointWind(
        point,
        timing: timing[point.id],
        series: profiles
            .series[forecastLocationKey(forecastProfileLocation(point))],
        terrainMeters: ref.watch(
          forecastPointTerrainProvider(point.location).future,
        ),
        airportMeters: _airportMeters(ref, point, route),
      ),
  ]);
  return {for (final (index, wind) in winds.indexed) points[index].id: ?wind};
}

Future<double?> _airportMeters(
  Ref ref,
  ForecastRoutePoint point,
  List<NavigationPoint> route,
) async {
  final index = point.waypointIndex;
  final waypoint = index != null && index < route.length ? route[index] : null;
  final airportId = waypoint?.airportId;
  final country = waypoint?.airportCountry;
  if (airportId == null ||
      airportId.isEmpty ||
      country == null ||
      country.isEmpty) {
    return null;
  }
  try {
    return airportElevationMeters(
      await ref.watch(airportMetadataProvider(airportId, country).future),
    );
  } catch (error) {
    debugPrint('Could not load airport elevation for $airportId: $error');
    return null;
  }
}

Future<RoutePointWind?> _pointWind(
  ForecastRoutePoint point, {
  required TimedRoutePoint? timing,
  required ForecastSeries? series,
  required Future<double?> terrainMeters,
  required Future<double?> airportMeters,
}) async {
  final eta = timing == null ? point.eta : timing.eta;
  final altitudeFeet = point.altitudeFeet;
  if (eta == null || series == null || altitudeFeet == null) return null;
  final terrain = await terrainMeters;
  final airport = await airportMeters;
  final forecast = series.at(
    eta,
    altitudeMeters: altitudeFeet * feetInMeters,
    terrainMeters: terrain ?? airport,
    pressureReferenceMeters: airport ?? terrain,
  );
  if (forecast == null) return null;
  return (wind: forecast.wind, gustMs: forecast.gustMs);
}
