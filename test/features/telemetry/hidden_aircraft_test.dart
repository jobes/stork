import 'package:flutter_test/flutter_test.dart';
import 'package:stork/features/settings/domain/models/app_settings.dart';
import 'package:stork/features/telemetry/domain/models/traffic_aircraft.dart';

void main() {
  group('Hidden Aircraft Tests', () {
    test('hideAircraft and unhideAircraft update AppSettings hiddenAircraftIds correctly', () {
      const settings = AppSettings();
      expect(settings.hiddenAircraftIds, isEmpty);

      final updated1 = settings.copyWith(
        hiddenAircraftIds: {'flrdda5e6', 'ogn123456'},
      );
      expect(updated1.hiddenAircraftIds, contains('flrdda5e6'));
      expect(updated1.hiddenAircraftIds, contains('ogn123456'));

      final updated2 = updated1.copyWith(
        hiddenAircraftIds: Set<String>.from(updated1.hiddenAircraftIds)..remove('flrdda5e6'),
      );
      expect(updated2.hiddenAircraftIds, isNot(contains('flrdda5e6')));
      expect(updated2.hiddenAircraftIds, contains('ogn123456'));
    });

    test('FilteredTraffic excludes aircraft present in hiddenAircraftIds', () {
      final ac1 = TrafficAircraft(
        id: 'FLRDDA5E6',
        callsign: 'OK-1234',
        latitude: 48.0,
        longitude: 17.0,
        altitude: 500,
        track: 180,
        groundSpeed: 30,
        verticalSpeed: 0,
        aircraftType: 1,
        lastSeen: DateTime.now(),
        sources: const {'ogn'},
        activeSource: 'ogn',
      );

      final ac2 = TrafficAircraft(
        id: 'PT998877',
        callsign: 'N12345',
        latitude: 48.1,
        longitude: 17.1,
        altitude: 600,
        track: 90,
        groundSpeed: 40,
        verticalSpeed: 1.0,
        aircraftType: 2,
        lastSeen: DateTime.now(),
        sources: const {'puretrack'},
        activeSource: 'puretrack',
      );

      final ac3 = TrafficAircraft(
        id: '166752',
        callsign: 'SAFE1',
        icaoHex: '166752',
        latitude: 48.2,
        longitude: 17.2,
        altitude: 700,
        track: 270,
        groundSpeed: 50,
        verticalSpeed: -0.5,
        aircraftType: 1,
        lastSeen: DateTime.now(),
        sources: const {'gdl90'},
        activeSource: 'gdl90',
      );

      final hiddenSet = {'flrdda5e6', '166752'};

      final trafficList = [ac1, ac2, ac3];
      final filtered = trafficList.where((ac) {
        final acId = ac.id.trim().toLowerCase();
        final acIcao = ac.icaoHex?.trim().toLowerCase();
        if (hiddenSet.contains(acId) ||
            (acIcao != null && hiddenSet.contains(acIcao))) {
          return false;
        }
        return true;
      }).toList();

      expect(filtered.length, equals(1));
      expect(filtered.first.id, equals('PT998877'));
    });
  });
}
