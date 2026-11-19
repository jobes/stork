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
}
