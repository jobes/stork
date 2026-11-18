import 'package:flutter_test/flutter_test.dart';
import 'package:stork/features/navigation/domain/models/navigation_point.dart';
import 'package:stork/features/weather/domain/forecast_route.dart';

void main() {
  final time = DateTime.utc(2026, 11, 16, 14);

  test('places stable 10-minute route samples and interpolates climb', () {
    const origin = (latitude: 48.0, longitude: 17.0);
    const waypoints = [
      NavigationPoint(
        latitude: 48.18,
        longitude: 17,
        name: 'A',
        weatherAltitudeFeet: 4000,
      ),
      NavigationPoint(
        latitude: 48.43,
        longitude: 17,
        name: 'B',
        weatherAltitudeFeet: 2000,
      ),
    ];
    final plan = ForecastRoute.plan(origin, waypoints, 20);
    final before = plan.forecastPoints(
      position: origin,
      points: waypoints,
      departure: time,
      groundSpeed: 20,
      flying: false,
      defaultAltitudeFeet: 2000,
    );
    final first = before.firstWhere((point) => point.id == 'sample-0');
    expect(first.duration, const Duration(minutes: 10));
    expect(first.altitudeFeet, closeTo(3200, 2));
    final during = plan.forecastPoints(
      position: (latitude: 48.01, longitude: 17),
      points: waypoints,
      departure: time,
      groundSpeed: 35,
      flying: true,
      defaultAltitudeFeet: 2000,
    );
    final sameSample = during.firstWhere((point) => point.id == first.id);
    expect(sameSample.location, first.location);
    expect(sameSample.duration, lessThan(first.duration));

    final remaining = waypoints.skip(1).toList();
    expect(plan.matches(remaining), isTrue);
    final after = plan.forecastPoints(
      position: (latitude: 48.18, longitude: 17),
      points: remaining,
      departure: time,
      groundSpeed: 20,
      flying: true,
      defaultAltitudeFeet: 2000,
      previousWaypointAltitudeFeet: 4000,
    );
    expect(after.any((point) => point.id == first.id), isFalse);
    expect(
      after.firstWhere((point) => point.waypointIndex == 0).id,
      'waypoint-1',
    );
    expect(after.first.altitudeFeet, 4000);
  });
}
