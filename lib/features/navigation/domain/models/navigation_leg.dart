import 'navigation_point.dart';

class NavigationLeg {
  final NavigationPoint point;
  final double legDistanceMeters;
  final Duration legDuration;
  final double cumulativeDistanceMeters;
  final Duration cumulativeDuration;
  final DateTime? eta;

  const NavigationLeg({
    required this.point,
    required this.legDistanceMeters,
    required this.legDuration,
    required this.cumulativeDistanceMeters,
    required this.cumulativeDuration,
    this.eta,
  });
}
