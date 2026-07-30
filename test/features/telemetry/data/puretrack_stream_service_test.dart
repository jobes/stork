import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:stork/features/telemetry/data/puretrack_stream_service.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  group('PureTrackPacket.parseDataRow', () {
    test('parses official PureTrack Traffic API CSV data row string', () {
      const row =
          'T1713592586,L-37.78174,G174.88159,A4685,C338,S144.05,V-13.31,O56,DC828EA,EZK-MZE,mANZ118M,KY-ZK-MZE';

      final packet = PureTrackPacket.parseDataRow(row);

      expect(packet, isNotNull);
      expect(packet!.rawId, equals('C828EA'));
      expect(packet.canonicalId, equals('c828ea'));
      expect(packet.callsign, equals('ANZ118M'));
      expect(packet.registration, equals('ZK-MZE'));
      expect(packet.latitude, equals(-37.78174));
      expect(packet.longitude, equals(174.88159));
      expect(packet.altitude, equals(4685.0));
      expect(packet.track, equals(338.0));
      expect(packet.groundSpeed, equals(144.05));
      expect(packet.verticalSpeed, equals(-13.31));
      expect(packet.aircraftType, equals(56));
      expect(packet.tSent.millisecondsSinceEpoch, equals(1713592586 * 1000));
    });
  });

  group('PureTrackPacket.fromJson', () {
    test('parses valid PureTrack JSON packet correctly', () {
      final json = {
        'id': 'ICAO:1EFCCC',
        'callsign': 'OK-1234',
        'registration': 'OK-1234',
        'model': 'Discus 2',
        'cn': 'D2',
        'lat': 48.1486,
        'lon': 17.1077,
        'alt': 520.5,
        'speed': 32.0,
        'track': 195.0,
        'vs': 1.8,
        'type': 1,
        'timestamp': 1753610000,
      };

      final packet = PureTrackPacket.fromJson(json);

      expect(packet, isNotNull);
      expect(packet!.rawId, equals('ICAO:1EFCCC'));
      expect(packet.canonicalId, equals('1efccc'));
      expect(packet.callsign, equals('OK-1234'));
      expect(packet.registration, equals('OK-1234'));
      expect(packet.model, equals('Discus 2'));
      expect(packet.cn, equals('D2'));
      expect(packet.latitude, equals(48.1486));
      expect(packet.longitude, equals(17.1077));
      expect(packet.altitude, equals(520.5));
      expect(packet.groundSpeed, equals(32.0));
      expect(packet.track, equals(195.0));
      expect(packet.verticalSpeed, equals(1.8));
      expect(packet.aircraftType, equals(1));
      expect(packet.tSent.millisecondsSinceEpoch, equals(1753610000 * 1000));
    });

    test('returns null for invalid JSON or missing lat/lon', () {
      final json = {'id': '1EFCCC', 'callsign': 'OK-1234'};

      final packet = PureTrackPacket.fromJson(json);
      expect(packet, isNull);
    });

    test('handles numeric strings and tolerant type/numeric parsing', () {
      final json = {
        'id': '1EFCCC',
        'lat': '48.1486',
        'lon': '17.1077',
        'alt': '520.5',
        'speed': '32',
        'track': '195.0',
        'vs': '-1.5',
        'type': '56',
      };

      final packet = PureTrackPacket.fromJson(json);

      expect(packet, isNotNull);
      expect(packet!.latitude, equals(48.1486));
      expect(packet.longitude, equals(17.1077));
      expect(packet.altitude, equals(520.5));
      expect(packet.groundSpeed, equals(32.0));
      expect(packet.track, equals(195.0));
      expect(packet.verticalSpeed, equals(-1.5));
      expect(packet.aircraftType, equals(56));
    });

    test(
      'falls back to defaults for invalid numeric values and default type 1',
      () {
        final json = {
          'id': '1EFCCC',
          'lat': 48.1486,
          'lon': 17.1077,
          'alt': 'invalid',
          'speed': null,
          'type': 'invalid',
        };

        final packet = PureTrackPacket.fromJson(json);

        expect(packet, isNotNull);
        expect(packet!.altitude, equals(0.0));
        expect(packet.groundSpeed, equals(0.0));
        expect(packet.aircraftType, equals(1));
      },
    );
  });

  group('PureTrackStreamService tests', () {
    test(
      'processRawPayload emits parsed packet to stream from data array',
      () async {
        final service = PureTrackStreamService();

        final jsonStr = jsonEncode({
          'success': true,
          'http_code': 200,
          'data': [
            'T1713592586,L-37.78174,G174.88159,A4685,C338,S144.05,V-13.31,O1,DC828EA,EZK-MZE,mANZ118M,KY-ZK-MZE',
          ],
        });

        expectLater(
          service.stream,
          emits(
            predicate<PureTrackPacket>(
              (p) =>
                  p.canonicalId == 'c828ea' &&
                  p.aircraftType == 1 &&
                  p.latitude == -37.78174,
            ),
          ),
        );

        service.processRawPayload(jsonStr);
      },
    );

    test(
      'processRawPayload triggers unauthorized handler on status 401',
      () async {
        bool unauthorizedCalled = false;
        final service = PureTrackStreamService(
          onUnauthorized: () {
            unauthorizedCalled = true;
          },
        );

        final jsonStr = jsonEncode({'status': 401, 'http_code': 401});

        service.processRawPayload(jsonStr);

        expect(unauthorizedCalled, isTrue);
      },
    );

    test('dispose does not throw and leaves caller-provided client open', () {
      final mockClient = MockHttpClient();
      final service = PureTrackStreamService(client: mockClient);

      service.dispose();

      verifyNever(() => mockClient.close());
    });
  });
}
