import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../route/presentation/providers/navigation_provider.dart';
import '../../../weather/presentation/providers/flight_weather_provider.dart';
import '../../../weather/presentation/providers/route_timing_provider.dart';

part 'navigation_eta_provider.g.dart';

/// Navigation-facing arrival estimates. The wind-adjusted timing comes from
/// the weather feature while the aggregate stays with the navigation UI, so it
/// falls back to the plan's speed-based ETA when no forecast is available.
@riverpod
NavigationCalculations navigationEta(Ref ref) {
  final route =
      ref.watch(navigationProvider).value?.points ?? const <NavigationPoint>[];
  final points = ref.watch(flightWeatherPlanProvider);
  final timing = ref.watch(routePointTimingProvider);
  final legs = <NavigationLeg>[];
  var previousDistance = 0.0;
  var previousDuration = Duration.zero;

  for (final point in points) {
    final index = point.waypointIndex;
    if (index == null || index >= route.length) continue;
    final estimate = timing[point.id];
    final cumulativeDuration = estimate?.duration ?? previousDuration;
    legs.add(
      NavigationLeg(
        point: route[index],
        legDistanceMeters: point.distanceMeters - previousDistance,
        cumulativeDistanceMeters: point.distanceMeters,
        legDuration: cumulativeDuration - previousDuration,
        cumulativeDuration: cumulativeDuration,
        eta: estimate?.eta,
      ),
    );
    previousDistance = point.distanceMeters;
    previousDuration = cumulativeDuration;
  }
  return NavigationCalculations(
    legs: legs,
    totalDistanceMeters: previousDistance,
    totalDuration: previousDuration,
  );
}
