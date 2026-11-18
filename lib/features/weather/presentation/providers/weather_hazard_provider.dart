import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../navigation/presentation/providers/navigation_eta_provider.dart';
import '../../../settings/presentation/providers/aircraft_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../navigation/presentation/providers/navigation_provider.dart';
import '../../data/repositories/flight_forecast_repository.dart';
import '../../domain/flight_forecast.dart';
import '../../domain/weather_hazard.dart';
import '../../domain/forecast_route.dart';
import 'flight_weather_provider.dart';

part 'weather_hazard_provider.g.dart';

typedef _HazardSample = ({
  ForecastSeries series,
  ForecastRoutePoint point,
  DateTime time,
  double? altitude,
});
typedef _HazardInput = ({
  List<_HazardSample> samples,
  double? windLimit,
  double? gustLimit,
});

typedef WeatherHazardDetail = ({
  String pointId,
  ForecastLocation location,
  DateTime time,
  double? altitudeFeet,
  Set<WeatherHazard> hazards,
  double? windMs,
  double? gustMs,
  double? windLimitMs,
  double? gustLimitMs,
  double? precipitationMm,
  DateTime? intervalEnd,
});

List<WeatherHazardDetail> _evaluateHazards(_HazardInput input) {
  final details = <WeatherHazardDetail>[];
  for (final sample in input.samples) {
    final forecast = sample.series.at(
      sample.time,
      altitudeMeters: sample.altitude,
    );
    if (forecast == null) continue;
    final hazards = forecastHazards(
      forecast,
      windLimitMs: input.windLimit,
      gustLimitMs: input.gustLimit,
    );
    if (hazards.isEmpty) continue;
    details.add((
      pointId: sample.point.id,
      location: sample.point.location,
      time: sample.time,
      altitudeFeet: sample.point.altitudeFeet,
      hazards: hazards,
      windMs: forecast.wind?.speedMs,
      gustMs: forecast.gustMs,
      windLimitMs: input.windLimit,
      gustLimitMs: input.gustLimit,
      precipitationMm: forecast.precipitationMm,
      intervalEnd: forecast.intervalEnd,
    ));
  }
  details.sort((a, b) => a.time.compareTo(b.time));
  return details;
}

@riverpod
Future<List<WeatherHazardDetail>> weatherHazardDetails(Ref ref) async {
  final enabled = ref.watch(
    appSettingsProvider.select((s) => s.value?.showFlightWeather ?? false),
  );
  if (!enabled) return const [];
  final points = ref.watch(flightWeatherPlanProvider);
  final timing = ref.watch(routePointTimingProvider);
  final profiles = ref.watch(flightForecastProfilesProvider).value;
  final aircraft = ref.watch(selectedAircraftProvider);
  final route = ref.watch(navigationProvider).value;
  if (profiles == null || (points.length > 1 && route?.isActive != true)) {
    return const [];
  }
  final query = ref.watch(flightWeatherQueryProvider.notifier);
  final input = (
    windLimit: aircraft?.dangerousWindMs,
    gustLimit: aircraft?.dangerousGustMs,
    samples: [
      for (final point in points)
        if (profiles.series[forecastLocationKey(query.locationFor(point))]
            case final series?)
          (
            series: series,
            point: point,
            time: timing[point.id]?.eta ?? point.eta,
            altitude: point.altitudeFeet == null
                ? null
                : point.altitudeFeet! * feetInMeters,
          ),
    ],
  );
  return compute(
    _evaluateHazards,
    input,
    debugLabel: 'Evaluate route weather hazards',
  );
}

@riverpod
Future<Set<WeatherHazard>> weatherHazards(Ref ref) async {
  final details = await ref.watch(weatherHazardDetailsProvider.future);
  return {for (final detail in details) ...detail.hazards};
}

@riverpod
List<WeatherHazardDetail> activeWeatherHazardDetails(Ref ref) {
  final enabled = ref.watch(
    appSettingsProvider.select((s) => s.value?.showFlightWeather ?? false),
  );
  if (!enabled) return const [];
  return ref.watch(weatherHazardDetailsProvider).value ?? const [];
}

@riverpod
Set<WeatherHazard> activeWeatherHazards(Ref ref) {
  final enabled = ref.watch(
    appSettingsProvider.select((s) => s.value?.showFlightWeather ?? false),
  );
  if (!enabled) return const {};
  final result = ref.watch(weatherHazardsProvider);
  return result.value ?? const {};
}
