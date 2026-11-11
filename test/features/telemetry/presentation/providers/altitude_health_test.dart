import 'package:flutter_test/flutter_test.dart';
import 'package:stork/features/telemetry/presentation/providers/altitude_health_provider.dart';

void main() {
  final now = DateTime.utc(2026, 11, 11, 12);

  bool evaluate({
    bool isFlying = true,
    bool hasMslAltitude = true,
    bool hasTerrainElevation = false,
    bool isFetching = false,
    Duration missingFor = const Duration(minutes: 1),
  }) {
    return evaluateTerrainUnavailable(
      now: now,
      isFlying: isFlying,
      hasMslAltitude: hasMslAltitude,
      hasTerrainElevation: hasTerrainElevation,
      isFetching: isFetching,
      missingSince: now.subtract(missingFor),
    );
  }

  group('evaluateTerrainUnavailable', () {
    test('reports nothing when terrain is known', () {
      expect(evaluate(hasTerrainElevation: true), isFalse);
    });

    test('reports nothing while the elevation request is in flight', () {
      expect(evaluate(isFetching: true), isFalse);
    });

    test('reports nothing without an altitude to compare against', () {
      expect(evaluate(hasMslAltitude: false), isFalse);
    });

    test('reports nothing on the ground', () {
      expect(evaluate(isFlying: false), isFalse);
    });

    test('waits for the grace period before reporting', () {
      expect(evaluate(missingFor: const Duration(seconds: 2)), isFalse);
      expect(evaluate(missingFor: AltitudeHealth.terrainGrace), isTrue);
    });
  });

  test('AltitudeHealthState compares by value', () {
    expect(
      const AltitudeHealthState(terrainUnavailable: true),
      equals(const AltitudeHealthState(terrainUnavailable: true)),
    );
    expect(
      const AltitudeHealthState(terrainUnavailable: true),
      isNot(equals(const AltitudeHealthState(altitudeUnavailable: true))),
    );
  });
}
