import 'package:flutter_test/flutter_test.dart';
import 'package:stork/features/telemetry/domain/models/gdl90_target.dart';
import 'package:stork/features/telemetry/domain/models/traffic_aircraft.dart';
import 'package:stork/features/telemetry/domain/repositories/traffic_aggregator.dart';
import 'package:stork/features/telemetry/domain/utils/canonical_id.dart';

TrafficAircraft buildAircraft({
  required String id,
  String? icaoHex,
  String callsign = 'OK-1234',
  DateTime? lastSeen,
  double latitude = 48.0,
  double longitude = 17.0,
}) {
  return TrafficAircraft(
    id: id,
    callsign: callsign,
    icaoHex: icaoHex,
    latitude: latitude,
    longitude: longitude,
    altitude: 500,
    track: 180,
    groundSpeed: 30,
    verticalSpeed: 0,
    aircraftType: 1,
    lastSeen: lastSeen ?? DateTime.now(),
  );
}

void main() {
  group('TrafficAggregator — ICAO cross-source merge', () {
    test(
      'GDL90 target is merged into existing OGN target, no duplicate entry',
      () {
        final aggregator = TrafficAggregator();

        final ogn = buildAircraft(
          id: 'DDA5E6',
          icaoHex: '166752',
          callsign: 'OK-1234',
          lastSeen: DateTime.now(),
        );
        aggregator.processOgnUpdate(ogn);

        final gdl90 = buildAircraft(
          id: '166752',
          icaoHex: '166752',
          callsign: 'OK-1234',
          lastSeen: DateTime.now().add(const Duration(seconds: 1)),
        );
        aggregator.processGdl90Update(gdl90);

        // Exactly one entry for the physical aircraft, stored under the
        // first-seen (OGN) canonical ID.
        expect(aggregator.targets.length, equals(1));
        final merged = aggregator.targets.first;
        expect(merged.id, equals('dda5e6'));
        expect(merged.sources, containsAll({'ogn', 'gdl90'}));
        expect(merged.activeSource, equals('gdl90'));
      },
    );

    test('no merge when ICAO does not match any existing target', () {
      final aggregator = TrafficAggregator();

      aggregator.processOgnUpdate(
        buildAircraft(id: 'DDA5E6', icaoHex: '166752'),
      );
      aggregator.processGdl90Update(
        buildAircraft(id: 'ABCDEF', icaoHex: 'ABCDEF'),
      );

      expect(aggregator.targets.length, equals(2));
    });

    test('stale GDL90 fix does not overwrite newer OGN position but merges '
        'sources', () {
      final aggregator = TrafficAggregator();
      final now = DateTime.now();

      final ogn = buildAircraft(
        id: 'DDA5E6',
        icaoHex: '166752',
        lastSeen: now,
        latitude: 48.1,
      );
      aggregator.processOgnUpdate(ogn);

      // GDL90 fix is older than the OGN fix → position must be preserved.
      final gdl90 = buildAircraft(
        id: '166752',
        icaoHex: '166752',
        lastSeen: now.subtract(const Duration(seconds: 5)),
        latitude: 49.0,
      );
      aggregator.processGdl90Update(gdl90);

      expect(aggregator.targets.length, equals(1));
      final merged = aggregator.targets.first;
      expect(merged.sources, containsAll({'ogn', 'gdl90'}));
      expect(merged.latitude, equals(48.1));
      // activeSource stays on the newer OGN fix.
      expect(merged.activeSource, equals('ogn'));
    });
  });

  group('TrafficAggregator — purgeSource', () {
    test('removes source but keeps aircraft when other sources remain', () {
      final aggregator = TrafficAggregator();
      aggregator.processOgnUpdate(
        buildAircraft(id: 'DDA5E6', icaoHex: '166752'),
      );
      aggregator.processGdl90Update(
        buildAircraft(
          id: '166752',
          icaoHex: '166752',
          lastSeen: DateTime.now().add(const Duration(seconds: 1)),
        ),
      );

      final removed = aggregator.purgeSource('gdl90');

      expect(removed, isEmpty);
      expect(aggregator.targets.length, equals(1));
      expect(aggregator.targets.first.sources, equals({'ogn'}));
      expect(aggregator.targets.first.activeSource, equals('ogn'));
    });

    test('removes aircraft entirely when it had no other source', () {
      final aggregator = TrafficAggregator();
      aggregator.processGdl90Update(
        buildAircraft(id: '166752', icaoHex: '166752'),
      );

      final removed = aggregator.purgeSource('gdl90');

      expect(removed, equals(['166752']));
      expect(aggregator.targets, isEmpty);
    });
  });

  group('TrafficAggregator — purgeSourceFromIcao', () {
    test('only purges targets whose ICAO matches', () {
      final aggregator = TrafficAggregator();
      aggregator.processGdl90Update(
        buildAircraft(id: '166752', icaoHex: '166752'),
      );
      aggregator.processGdl90Update(
        buildAircraft(id: 'ABCDEF', icaoHex: 'ABCDEF'),
      );

      final removed = aggregator.purgeSourceFromIcao('gdl90', '166752');

      expect(removed, equals(['166752']));
      expect(aggregator.targets.length, equals(1));
      expect(aggregator.targets.first.id, equals('abcdef'));
    });

    test('removes the gdl90 source from a merged target, keeping ogn', () {
      final aggregator = TrafficAggregator();
      aggregator.processOgnUpdate(
        buildAircraft(id: 'DDA5E6', icaoHex: '166752'),
      );
      aggregator.processGdl90Update(
        buildAircraft(
          id: '166752',
          icaoHex: '166752',
          lastSeen: DateTime.now().add(const Duration(seconds: 1)),
        ),
      );

      final removed = aggregator.purgeSourceFromIcao('gdl90', '166752');

      expect(removed, isEmpty);
      expect(aggregator.targets.length, equals(1));
      final remaining = aggregator.targets.first;
      expect(remaining.sources, equals({'ogn'}));
      expect(remaining.activeSource, equals('ogn'));
    });
  });

  group('Gdl90Target — expiry', () {
    test('isExpired returns true for stale target with default timeout', () {
      final target = Gdl90Target(
        id: '166752',
        latitude: 48.0,
        longitude: 17.0,
        altitudeFeet: 1500,
        trackDegrees: 180,
        speedKnots: 60,
        verticalSpeedFpm: 0,
        lastUpdated: DateTime.now().subtract(const Duration(minutes: 2)),
      );

      expect(target.isExpired(), isTrue);
    });

    test('isExpired returns false for fresh target', () {
      final target = Gdl90Target(
        id: '166752',
        latitude: 48.0,
        longitude: 17.0,
        altitudeFeet: 1500,
        trackDegrees: 180,
        speedKnots: 60,
        verticalSpeedFpm: 0,
        lastUpdated: DateTime.now(),
      );

      expect(target.isExpired(), isFalse);
    });

    test('isExpired honours custom timeout', () {
      final target = Gdl90Target(
        id: '166752',
        latitude: 48.0,
        longitude: 17.0,
        altitudeFeet: 1500,
        trackDegrees: 180,
        speedKnots: 60,
        verticalSpeedFpm: 0,
        lastUpdated: DateTime.now().subtract(const Duration(seconds: 30)),
      );

      expect(target.isExpired(60), isFalse);
      expect(target.isExpired(10), isTrue);
    });
  });

  group('CanonicalId.isIcaoHex', () {
    test('accepts 6-char hex and rejects others', () {
      expect(CanonicalId.isIcaoHex('166752'), isTrue);
      expect(CanonicalId.isIcaoHex('ABCDEF'), isTrue);
      expect(CanonicalId.isIcaoHex('FLRDDA5E6'), isFalse);
      expect(CanonicalId.isIcaoHex('12345'), isFalse);
      expect(CanonicalId.isIcaoHex(''), isFalse);
    });
  });
}
