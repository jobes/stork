import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import './navigation_eta_provider.dart';
import '../../../settings/presentation/providers/aircraft_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../route/presentation/providers/navigation_provider.dart';
import '../../domain/flight_forecast.dart';
import '../../domain/forecast_profile.dart';
import '../../domain/forecast_query.dart';
import '../../domain/forecast_route.dart';
import '../../domain/weather_hazard.dart';
import 'flight_weather_provider.dart';

part 'weather_hazard_provider.g.dart';

typedef _HazardSample = ({
  ForecastProfile series,
  ForecastRoutePoint point,
  ForecastReference reference,
  DateTime time,
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
    final forecast = sample.series.atReference(
      sample.time,
      altitudeFeet: sample.point.altitudeFeet,
      reference: sample.reference,
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
  final references = await ref.watch(routeForecastReferencesProvider.future);
  final locations = ref.watch(flightWeatherProfileLocationsProvider);
  final input = (
    windLimit: aircraft?.dangerousWindMs,
    gustLimit: aircraft?.dangerousGustMs,
    samples: [
      for (final point in points)
        if (profiles.series[forecastLocationKey(
              locations[point.id] ?? point.location,
            )]
            case final series?)
          if (references[point.id] case final reference?)
            (
              series: series,
              point: point,
              reference: reference,
              time: timing[point.id]?.eta ?? point.eta,
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
