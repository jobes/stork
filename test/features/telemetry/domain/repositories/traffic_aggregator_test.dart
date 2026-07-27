import 'package:flutter_test/flutter_test.dart';
import 'package:stork/features/telemetry/data/ogn_aprs_service.dart';
import 'package:stork/features/telemetry/data/puretrack_stream_service.dart';
import 'package:stork/features/telemetry/domain/repositories/traffic_aggregator.dart';

void main() {
  group('TrafficAggregator Tests', () {
    late TrafficAggregator aggregator;

    setUp(() {
      aggregator = TrafficAggregator();
    });

    test('deduplicates identical aircraft across OGN and PureTrack', () {
      final baseTime = DateTime.now().subtract(const Duration(seconds: 10));

      final ognPacket = OgnTrafficAircraft(
        id: 'FLR1EFCCC',
        callsign: 'FLR1EFCCC',
        latitude: 48.1486,
        longitude: 17.1077,
        altitude: 500.0,
        track: 90.0,
        groundSpeed: 30.0,
        verticalSpeed: 1.0,
        aircraftType: 1,
        lastSeen: baseTime,
      );

      final pureTrackPacket = PureTrackPacket(
        rawId: 'ICAO:1efccc',
        canonicalId: '1efccc',
        callsign: 'OK-1234',
        model: 'Discus 2c',
        latitude: 48.1490,
        longitude: 17.1080,
        altitude: 510.0,
        groundSpeed: 31.0,
        track: 92.0,
        verticalSpeed: 1.2,
        aircraftType: 1,
        tSent: baseTime.add(const Duration(seconds: 2)),
      );

      aggregator.processOgnUpdate(ognPacket);
      expect(aggregator.targets.length, equals(1));
      expect(aggregator.targets.first.id, equals('1efccc'));
      expect(aggregator.targets.first.activeSource, equals('ogn'));
      expect(aggregator.targets.first.sources, contains('ogn'));

      aggregator.processPureTrackPacket(pureTrackPacket);
      expect(aggregator.targets.length, equals(1));
      expect(aggregator.targets.first.id, equals('1efccc'));
      expect(aggregator.targets.first.latitude, equals(48.1490));
      expect(aggregator.targets.first.altitude, equals(510.0));
      expect(aggregator.targets.first.activeSource, equals('puretrack'));
      expect(aggregator.targets.first.sources, containsAll(['ogn', 'puretrack']));
      expect(aggregator.targets.first.aircraftModel, equals('Discus 2c'));
    });

    test('Position Arbitration: discards out-of-order delayed packet with older T_sent', () {
      final now = DateTime.now();
      final timeSentNew = now.subtract(const Duration(seconds: 5));
      final timeSentOld = now.subtract(const Duration(seconds: 15));

      // Packet from fast feed (T_sent = T-5s) arrives first
      final pureTrackPacket = PureTrackPacket(
        rawId: '1efccc',
        canonicalId: '1efccc',
        callsign: 'OK-1234',
        latitude: 48.1500,
        longitude: 17.1100,
        altitude: 600.0,
        groundSpeed: 35.0,
        track: 180.0,
        verticalSpeed: 2.0,
        aircraftType: 1,
        tSent: timeSentNew,
      );

      // Packet from delayed feed (T_sent = T-15s) arrives later
      final delayedOgnPacket = OgnTrafficAircraft(
        id: '1EFCCC',
        callsign: 'FLR1EFCCC',
        latitude: 48.1400, // Older position
        longitude: 17.1000,
        altitude: 550.0,
        track: 170.0,
        groundSpeed: 30.0,
        verticalSpeed: 0.5,
        aircraftType: 1,
        lastSeen: timeSentOld,
      );

      aggregator.processPureTrackPacket(pureTrackPacket);
      expect(aggregator.targets.first.latitude, equals(48.1500));
      expect(aggregator.targets.first.lastSeen, equals(timeSentNew));

      // Process delayed packet
      aggregator.processOgnUpdate(delayedOgnPacket);

      // Target position should NOT jump backward to older position
      expect(aggregator.targets.first.latitude, equals(48.1500));
      expect(aggregator.targets.first.altitude, equals(600.0));
      expect(aggregator.targets.first.lastSeen, equals(timeSentNew));
      expect(aggregator.targets.first.sources, containsAll(['ogn', 'puretrack']));
    });

    test('Transmitter Clock Drift: clamps future T_sent to prevent lock-out', () {
      final now = DateTime.now();
      final farFutureTime = now.add(const Duration(seconds: 300)); // +5 mins drift

      final driftedPacket = PureTrackPacket(
        rawId: '1efccc',
        canonicalId: '1efccc',
        callsign: 'DRIFTED',
        latitude: 48.1500,
        longitude: 17.1100,
        altitude: 600.0,
        groundSpeed: 35.0,
        track: 180.0,
        verticalSpeed: 2.0,
        aircraftType: 1,
        tSent: farFutureTime,
      );

      aggregator.processPureTrackPacket(driftedPacket);

      // Verify T_sent was clamped near now, not locked 5 mins in the future
      expect(aggregator.targets.first.lastSeen.isBefore(now.add(const Duration(seconds: 5))), isTrue);
    });

    test('Aircraft Type Consistency: maps PureTrack core categories 1:1', () {
      final categories = [
        {'type': 1, 'expectedOgnCode': 1}, // Glider
        {'type': 6, 'expectedOgnCode': 6}, // Hang Glider
        {'type': 7, 'expectedOgnCode': 7}, // Paraglider
        {'type': 8, 'expectedOgnCode': 8}, // Powered Aircraft
        {'type': 11, 'expectedOgnCode': 11}, // Balloon
      ];

      for (final cat in categories) {
        final agg = TrafficAggregator();
        final packet = PureTrackPacket(
          rawId: 'ac_${cat['type']}',
          canonicalId: 'ac_${cat['type']}',
          callsign: 'CAT_${cat['type']}',
          latitude: 48.0,
          longitude: 17.0,
          altitude: 100.0,
          groundSpeed: 10.0,
          track: 0.0,
          verticalSpeed: 0.0,
          aircraftType: cat['type'] as int,
          tSent: DateTime.now(),
        );

        agg.processPureTrackPacket(packet);
        expect(agg.targets.first.aircraftType, equals(cat['expectedOgnCode']));
      }
    });

    test('Garbage Collection: purges targets inactive for > 15 minutes', () {
      final oldTime = DateTime.now().subtract(const Duration(minutes: 16));
      final recentTime = DateTime.now().subtract(const Duration(minutes: 2));

      final stalePacket = OgnTrafficAircraft(
        id: '1EFCCC',
        callsign: 'STALE',
        latitude: 48.0,
        longitude: 17.0,
        altitude: 100.0,
        track: 0.0,
        groundSpeed: 0.0,
        verticalSpeed: 0.0,
        aircraftType: 1,
        lastSeen: oldTime,
      );

      final activePacket = OgnTrafficAircraft(
        id: '2AB345',
        callsign: 'ACTIVE',
        latitude: 48.0,
        longitude: 17.0,
        altitude: 100.0,
        track: 0.0,
        groundSpeed: 0.0,
        verticalSpeed: 0.0,
        aircraftType: 1,
        lastSeen: recentTime,
      );

      aggregator.processOgnUpdate(stalePacket);
      aggregator.processOgnUpdate(activePacket);
      expect(aggregator.targets.length, equals(2));

      final purgedCount = aggregator.purgeStaleTargets(maxAge: const Duration(minutes: 15));
      expect(purgedCount, equals(1));
      expect(aggregator.targets.length, equals(1));
      expect(aggregator.targets.first.id, equals('2ab345'));
    });
  });
}
