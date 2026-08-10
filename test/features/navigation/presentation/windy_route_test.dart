import 'package:flutter_test/flutter_test.dart';
import 'package:stork/features/navigation/domain/models/navigation_point.dart';
import 'package:stork/features/navigation/presentation/windy_route.dart';

void main() {
  group('buildWindyRouteUrl', () {
    final points = [
      NavigationPoint(latitude: 48.716, longitude: 19.099, name: 'A'),
      NavigationPoint(latitude: 49.0, longitude: 20.0, name: 'B'),
    ];

    test('returns empty string for an empty route', () {
      expect(buildWindyRouteUrl(const []), '');
    });

    test('builds a route-planner URL from the route points', () {
      expect(
        buildWindyRouteUrl(points),
        'https://www.windy.com/route-planner/vfr/48.716,19.099;49.0,20.0',
      );
    });

    test('prepends the current GPS position when known', () {
      expect(
        buildWindyRouteUrl(
          points,
          currentLatitude: 48.1,
          currentLongitude: 17.1,
        ),
        'https://www.windy.com/route-planner/vfr/'
        '48.1,17.1;48.716,19.099;49.0,20.0',
      );
    });

    test('prepends the current position when latitude is 0 (equator)', () {
      expect(
        buildWindyRouteUrl(
          points,
          currentLatitude: 0.0,
          currentLongitude: 17.1,
        ),
        'https://www.windy.com/route-planner/vfr/'
        '0.0,17.1;48.716,19.099;49.0,20.0',
      );
    });

    test(
      'prepends the current position when longitude is 0 (prime meridian)',
      () {
        expect(
          buildWindyRouteUrl(
            points,
            currentLatitude: 48.1,
            currentLongitude: 0.0,
          ),
          'https://www.windy.com/route-planner/vfr/'
          '48.1,0.0;48.716,19.099;49.0,20.0',
        );
      },
    );

    test('ignores the current position when it is 0,0', () {
      expect(
        buildWindyRouteUrl(points, currentLatitude: 0.0, currentLongitude: 0.0),
        'https://www.windy.com/route-planner/vfr/48.716,19.099;49.0,20.0',
      );
    });

    test('ignores a partially known current position', () {
      expect(
        buildWindyRouteUrl(
          points,
          currentLatitude: 48.1,
          currentLongitude: null,
        ),
        'https://www.windy.com/route-planner/vfr/48.716,19.099;49.0,20.0',
      );
    });
  });
}
