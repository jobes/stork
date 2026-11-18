import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../settings/presentation/providers/aircraft_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../domain/flight_forecast.dart';
import '../../domain/forecast_profile.dart';
import '../../domain/forecast_query.dart';
import '../../domain/forecast_route.dart';
import '../../domain/weather_hazard.dart';
import '../../domain/wind_route_timing.dart';
import 'flight_weather_provider.dart';
import 'navigation_eta_provider.dart';

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
  final references = enabled
      ? ref.watch(routeForecastReferencesProvider).value ??
            const <String, ForecastReference>{}
      : const <String, ForecastReference>{};
  final locations = enabled
      ? ref.watch(flightWeatherProfileLocationsProvider)
      : const <String, ForecastLocation>{};

  return {
    for (final point in points)
      ?point.waypointIndex: _weatherForPoint(
        point,
        timing: timing[point.id],
        series: enabled
            ? profiles?.series[forecastLocationKey(
                locations[point.id] ?? point.location,
              )]
            : null,
        reference: references[point.id],
        windLimitMs: aircraft?.dangerousWindMs,
        gustLimitMs: aircraft?.dangerousGustMs,
      ),
  };
}

RouteWaypointWeather _weatherForPoint(
  ForecastRoutePoint point, {
  required TimedRoutePoint? timing,
  required ForecastProfile? series,
  required ForecastReference? reference,
  required double? windLimitMs,
  required double? gustLimitMs,
}) {
  final eta = timing == null ? point.eta : timing.eta;
  final altitudeFeet = point.altitudeFeet;
  final forecast = series != null && eta != null && altitudeFeet != null
      ? series.atReference(
          eta,
          altitudeFeet: altitudeFeet,
          reference: reference,
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
/// time. Uses the same wind-adjusted timing and forecast reference as the
/// route list and the details dialog.
@riverpod
Map<String, RoutePointWind> routePointWinds(Ref ref) {
  final enabled = ref.watch(
    appSettingsProvider.select((s) => s.value?.showFlightWeather ?? false),
  );
  final points = ref.watch(flightWeatherPlanProvider);
  if (!enabled || points.isEmpty) return const {};
  final profiles = ref.watch(flightForecastProfilesProvider).value;
  if (profiles == null) return const {};
  final timing = ref.watch(routePointTimingProvider);
  final references =
      ref.watch(routeForecastReferencesProvider).value ??
      const <String, ForecastReference>{};
  final locations = ref.watch(flightWeatherProfileLocationsProvider);

  final winds = <String, RoutePointWind>{};
  for (final point in points) {
    final wind = _pointWind(
      point,
      timing: timing[point.id],
      series: profiles
          .series[forecastLocationKey(locations[point.id] ?? point.location)],
      reference: references[point.id],
    );
    if (wind != null) winds[point.id] = wind;
  }
  return winds;
}

RoutePointWind? _pointWind(
  ForecastRoutePoint point, {
  required TimedRoutePoint? timing,
  required ForecastProfile? series,
  required ForecastReference? reference,
}) {
  final eta = timing == null ? point.eta : timing.eta;
  final altitudeFeet = point.altitudeFeet;
  if (eta == null || series == null || altitudeFeet == null) return null;
  final forecast = series.atReference(
    eta,
    altitudeFeet: altitudeFeet,
    reference: reference,
  );
  if (forecast == null) return null;
  return (wind: forecast.wind, gustMs: forecast.gustMs);
}
