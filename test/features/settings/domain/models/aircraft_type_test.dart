import 'package:flutter_test/flutter_test.dart';
import 'package:stork/features/settings/domain/models/aircraft_type.dart';

void main() {
  test('AircraftType enum mappings', () {
    for (final type in AircraftType.values) {
      // Verify map icon IDs are generated
      expect(type.mapIconId, equals('aircraft-icon-${type.assetName}'));
      expect(type.trafficMapIconId, equals('traffic-icon-${type.assetName}'));
    }

    // Verify OGN code mappings
    expect(AircraftType.fromOgnCode(1), equals(AircraftType.glider));
    expect(AircraftType.fromOgnCode(2), equals(AircraftType.towPlane));
    expect(AircraftType.fromOgnCode(3), equals(AircraftType.helicopter));
    expect(AircraftType.fromOgnCode(4), equals(AircraftType.skydiver));
    expect(AircraftType.fromOgnCode(5), equals(AircraftType.dropPlane));
    expect(AircraftType.fromOgnCode(6), equals(AircraftType.hangGlider));
    expect(AircraftType.fromOgnCode(7), equals(AircraftType.paraglider));
    expect(AircraftType.fromOgnCode(8), equals(AircraftType.poweredAircraft));
    expect(AircraftType.fromOgnCode(9), equals(AircraftType.jet));
    expect(AircraftType.fromOgnCode(11), equals(AircraftType.balloon));
    expect(AircraftType.fromOgnCode(12), equals(AircraftType.airship));
    expect(AircraftType.fromOgnCode(13), equals(AircraftType.uav));
    expect(AircraftType.fromOgnCode(99), equals(AircraftType.other));
  });
}
