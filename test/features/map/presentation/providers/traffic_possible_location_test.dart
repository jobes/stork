import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre/maplibre.dart';
import 'package:stork/core/utils/geo_utils.dart';
import 'package:stork/features/telemetry/domain/models/traffic_aircraft.dart';

import '../../../../helpers/sprite_test_utils.dart';

void main() {
  group('Traffic Possible Location Tests', () {
    test('possibleLoc sprite frame exists and fits the sheet', () {
      final index = loadSpriteIndex();
      expect(
        index.containsKey('possibleLoc'),
        isTrue,
        reason: 'Sprite frame missing: possibleLoc',
      );
      expect(
        overflowingFrames(index),
        isEmpty,
        reason: 'Some sprite frames overflow the sheet',
      );
    });

    test(
      'calculateDestination projects coordinates accurately for aircraft heading & speed',
      () {
        final start = Geographic(lat: 48.1486, lon: 17.1077);
        const heading = 90.0; // Eastbound
        const speedMps = 30.0; // 30 m/s
        const delaySeconds = 20.0; // 20s
        const distanceMeters = speedMps * delaySeconds; // 600 meters

        final destination = GeoUtils.calculateDestination(
          start,
          heading,
          distanceMeters,
        );

        // Eastward movement should increase longitude while keeping latitude nearly equal
        expect(destination.lat, closeTo(start.lat, 0.001));
        expect(destination.lon, greaterThan(start.lon));

        final calculatedDistance = GeoUtils.distanceBetween(
          start.lat,
          start.lon,
          destination.lat,
          destination.lon,
        );
        expect(calculatedDistance, closeTo(600.0, 1.0));
      },
    );

    test(
      'TrafficAircraft data structures retain lastSeen and track correctly',
      () {
        final now = DateTime.now();
        final ac = TrafficAircraft(
          id: 'OGN123456',
          callsign: 'OM-1234',
          latitude: 48.1486,
          longitude: 17.1077,
          altitude: 500,
          track: 180.0,
          groundSpeed: 25.0,
          verticalSpeed: 1.5,
          aircraftType: 1,
          lastSeen: now.subtract(const Duration(seconds: 5)),
        );

        expect(ac.groundSpeed, equals(25.0));
        expect(ac.track, equals(180.0));
        expect(now.difference(ac.lastSeen).inSeconds, closeTo(5, 1));
      },
    );
  });
}
