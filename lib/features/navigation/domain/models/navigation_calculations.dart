import 'package:clock/clock.dart';
import 'navigation_point.dart';
import 'navigation_leg.dart';

class NavigationCalculations {
  final List<NavigationLeg> legs;
  final double totalDistanceMeters;
  final Duration totalDuration;

  const NavigationCalculations({
    required this.legs,
    required this.totalDistanceMeters,
    required this.totalDuration,
  });

  factory NavigationCalculations.calculate({
    required List<NavigationPoint> points,
    required double? currentLatitude,
    required double? currentLongitude,
    required double activeSpeedMs,
    DateTime? now,
  }) {
    if (points.isEmpty ||
        currentLatitude == null ||
        currentLongitude == null ||
        currentLatitude == 0.0 ||
        currentLongitude == 0.0) {
      return const NavigationCalculations(
        legs: [],
        totalDistanceMeters: 0.0,
        totalDuration: Duration.zero,
      );
    }

    final effectiveNow = now ?? clock.now();
    final List<NavigationLeg> computedLegs = [];
    double accumulatedDistance = 0.0;
    double accumulatedSeconds = 0.0;

    double lastLat = currentLatitude;
    double lastLon = currentLongitude;

    for (final p in points) {
      final dist = p.distanceTo(lastLat, lastLon);
      accumulatedDistance += dist;

      final legSecs = activeSpeedMs > 0 ? dist / activeSpeedMs : 0.0;
      accumulatedSeconds += legSecs;

      final cumulativeDuration = Duration(seconds: accumulatedSeconds.round());

      computedLegs.add(
        NavigationLeg(
          point: p,
          legDistanceMeters: dist,
          legDuration: Duration(seconds: legSecs.round()),
          cumulativeDistanceMeters: accumulatedDistance,
          cumulativeDuration: cumulativeDuration,
          eta: effectiveNow.add(cumulativeDuration),
        ),
      );

      lastLat = p.latitude;
      lastLon = p.longitude;
    }

    return NavigationCalculations(
      legs: computedLegs,
      totalDistanceMeters: accumulatedDistance,
      totalDuration: Duration(seconds: accumulatedSeconds.round()),
    );
  }
}
