import 'package:flutter_test/flutter_test.dart';
import 'package:stork/features/settings/domain/models/aircraft_type.dart';

void main() {
  test('AircraftType enum mappings', () {
    for (final type in AircraftType.values) {
      // Verify traffic map icon IDs are generated (from the app sprite)
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

  test('AircraftType GDL90 emitter category mappings', () {
    // GDL90 ICD table: 1-6 powered, 7 rotorcraft, 9 glider, 10 lighter-than-
    // air, 11 parachutist, 12 ultralight/hang glider/paraglider, 14 UAV.
    // 8 and 13 are reserved (must not map to a specific type).
    expect(
      AircraftType.fromGdl90EmitterCategory(1),
      equals(AircraftType.poweredAircraft),
    );
    expect(
      AircraftType.fromGdl90EmitterCategory(6),
      equals(AircraftType.poweredAircraft),
    );
    expect(
      AircraftType.fromGdl90EmitterCategory(7),
      equals(AircraftType.helicopter),
    );
    expect(
      AircraftType.fromGdl90EmitterCategory(9),
      equals(AircraftType.glider),
      reason: 'GDL90 glider code is 9 (SafeSky sends 9 for gliders)',
    );
    expect(
      AircraftType.fromGdl90EmitterCategory(10),
      equals(AircraftType.balloon),
    );
    expect(
      AircraftType.fromGdl90EmitterCategory(11),
      equals(AircraftType.skydiver),
    );
    expect(
      AircraftType.fromGdl90EmitterCategory(12),
      equals(AircraftType.paraglider),
    );
    expect(AircraftType.fromGdl90EmitterCategory(14), equals(AircraftType.uav));
    // Reserved / unknown codes fall back to 'other'.
    expect(
      AircraftType.fromGdl90EmitterCategory(8),
      equals(AircraftType.other),
    );
    expect(
      AircraftType.fromGdl90EmitterCategory(13),
      equals(AircraftType.other),
    );
    expect(
      AircraftType.fromGdl90EmitterCategory(0),
      equals(AircraftType.other),
    );
    expect(
      AircraftType.fromGdl90EmitterCategory(99),
      equals(AircraftType.other),
    );
  });
}
