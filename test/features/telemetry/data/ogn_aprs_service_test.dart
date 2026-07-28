import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:stork/features/telemetry/data/ogn_aprs_service.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  setUpAll(() {
    registerFallbackValue(Uri());
  });

  group('OgnAprsService Tests', () {
    late OgnAprsService service;

    setUp(() {
      service = OgnAprsService();
    });

    test('parseAprsLine parses standard glider packet correctly', () {
      const packet =
          'FLR1EFCCC>OGFLR,qAS,K2B9:/172500h4432.07N/07306.44W^000/000/A=000646 !W72! id061EFCCC +039fpm -2.1rot 28.0dB';

      final aircraft = service.parseAprsLine(packet);

      expect(aircraft, isNotNull);
      expect(aircraft!.id, equals('1EFCCC'));
      expect(aircraft.callsign, equals('FLR1EFCCC'));

      // 44 + (32.07 + 0.007) / 60 = 44.53461666...
      expect(aircraft.latitude, closeTo(44.534616, 0.0001));
      // -(73 + (6.44 + 0.002) / 60) = -73.1073666...
      expect(aircraft.longitude, closeTo(-73.107366, 0.0001));

      // A=000646 feet = 646 * 0.3048 = 196.9008 meters
      expect(aircraft.altitude, closeTo(196.9, 0.1));

      // +039fpm = 39 * 0.00508 = 0.19812 m/s
      expect(aircraft.verticalSpeed, closeTo(0.198, 0.01));

      // id06...: byte is 0x06. (0x06 >> 2) & 0x0F = 1 (Glider)
      expect(aircraft.aircraftType, equals(1));
    });

    test('parseAprsLine parses OGN !Wxy! high precision extension', () {
      const packet =
          'FLR1EFCCC>OGFLR,qAS,K2B9:/172500h4432.07N/07306.44W^000/000/A=000646 !W58! id061EFCCC +039fpm';

      final aircraft = service.parseAprsLine(packet);

      expect(aircraft, isNotNull);
      // 44 + (32.07 + 0.005) / 60 = 44.5345833...
      expect(aircraft!.latitude, closeTo(44.534583, 0.00001));
      // -(73 + (6.44 + 0.008) / 60) = -73.1074666...
      expect(aircraft.longitude, closeTo(-73.107466, 0.00001));
    });

    test('parseAprsLine respects stealth privacy flag', () {
      // 0x86 has bit 7 set (Stealth mode)
      const packet =
          'FLR1EFCCC>OGFLR,qAS,K2B9:/172500h4432.07N/07306.44W^000/000/A=000646 !W72! id861EFCCC +039fpm';

      final aircraft = service.parseAprsLine(packet);

      expect(aircraft, isNotNull);
      expect(aircraft!.isAnonymous, isTrue);
    });

    test('parseAprsLine respects no-tracking privacy flag', () {
      // 0x46 has bit 6 set (No tracking)
      const packet =
          'FLR1EFCCC>OGFLR,qAS,K2B9:/172500h4432.07N/07306.44W^000/000/A=000646 !W72! id461EFCCC +039fpm';

      final aircraft = service.parseAprsLine(packet);

      expect(aircraft, isNotNull);
      expect(aircraft!.isAnonymous, isTrue);
    });

    test('parseAprsLine ignores comment line starting with #', () {
      const packet = '# aprs.glidernet.org';
      final aircraft = service.parseAprsLine(packet);
      expect(aircraft, isNull);
    });

    test(
      'parseAprsLine parses packet with 3-decimal minutes and missing course/speed',
      () {
        const packet =
            'FLR1EFCCC>OGFLR,qAS,K2B9:/172500h4432.073N/07306.442W^/A=000646 !W72! id061EFCCC +039fpm';

        final aircraft = service.parseAprsLine(packet);

        expect(aircraft, isNotNull);
        expect(aircraft!.latitude, closeTo(44.53455, 0.0001));
        expect(aircraft.longitude, closeTo(-73.10736, 0.0001));
        expect(aircraft.track, equals(0.0));
        expect(aircraft.groundSpeed, equals(0.0));
        expect(aircraft.altitude, closeTo(196.9, 0.1));
      },
    );

    test('lookupDdb parses OGN DDB JSON response successfully', () async {
      final mockClient = MockHttpClient();
      final testService = OgnAprsService(client: mockClient);

      const mockResponse =
          '{"devices":[{"device_type":"F","device_id":"1EFCCC","aircraft_model":"AS 33Me","registration":"OY-XEL","cn":"EL","tracked":"Y","identified":"Y"}]}';

      when(
        () => mockClient.get(
          Uri.https('ddb.glidernet.org', '/download/', {
            'j': '1',
            'device_id': '1EFCCC',
          }),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer((_) async => http.Response(mockResponse, 200));

      final result = await testService.lookupDdb('1EFCCC');

      expect(result, isNotNull);
      expect(result!['registration'], equals('OY-XEL'));
      expect(result['aircraftModel'], equals('AS 33Me'));
      expect(result['cn'], equals('EL'));
    });

    test('lookupDdb converts lowercase device ID to uppercase', () async {
      final mockClient = MockHttpClient();
      final testService = OgnAprsService(client: mockClient);

      const mockResponse =
          '{"devices":[{"device_type":"F","device_id":"1EFCCC","aircraft_model":"AS 33Me","registration":"OY-XEL","cn":"EL","tracked":"Y","identified":"Y"}]}';

      when(
        () => mockClient.get(
          Uri.https('ddb.glidernet.org', '/download/', {
            'j': '1',
            'device_id': '1EFCCC',
          }),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer((_) async => http.Response(mockResponse, 200));

      final result = await testService.lookupDdb('1efccc');

      expect(result, isNotNull);
      expect(result!['registration'], equals('OY-XEL'));
      expect(result['aircraftModel'], equals('AS 33Me'));
      expect(result['cn'], equals('EL'));
    });

    test(
      'lookupDdbMultiple queries multiple IDs in a single request and returns a map',
      () async {
        final mockClient = MockHttpClient();
        final testService = OgnAprsService(client: mockClient);

        const mockResponse =
            '{"devices":['
            '{"device_type":"F","device_id":"1EFCCC","aircraft_model":"AS 33Me","registration":"OY-XEL","cn":"EL","tracked":"Y","identified":"Y"},'
            '{"device_type":"O","device_id":"2ABCDE","aircraft_model":"LS-6","registration":"D-EEAC","cn":"AC","tracked":"Y","identified":"Y"}'
            ']}';

        when(
          () => mockClient.get(
            Uri.https('ddb.glidernet.org', '/download/', {
              'j': '1',
              'device_id': '1EFCCC,2ABCDE',
            }),
            headers: any(named: 'headers'),
          ),
        ).thenAnswer((_) async => http.Response(mockResponse, 200));

        final results = await testService.lookupDdbMultiple([
          '1efccc',
          '2abcde',
        ]);

        expect(results, isNotNull);
        expect(results.length, equals(2));

        expect(results['1EFCCC']!['registration'], equals('OY-XEL'));
        expect(results['1EFCCC']!['aircraftModel'], equals('AS 33Me'));

        expect(results['2ABCDE']!['registration'], equals('D-EEAC'));
        expect(results['2ABCDE']!['aircraftModel'], equals('LS-6'));
      },
    );

    test(
      'lookupDdbMultiple handles non-200 HTTP response gracefully without caching',
      () async {
        final mockClient = MockHttpClient();
        final testService = OgnAprsService(client: mockClient);

        when(
          () => mockClient.get(
            Uri.https('ddb.glidernet.org', '/download/', {
              'j': '1',
              'device_id': '1EFCCC',
            }),
            headers: any(named: 'headers'),
          ),
        ).thenAnswer((_) async => http.Response('Server Error', 500));

        final results = await testService.lookupDdbMultiple(['1EFCCC']);
        expect(results, isEmpty);
      },
    );

    test(
      'lookupDdbMultiple handles HTTP client exception gracefully',
      () async {
        final mockClient = MockHttpClient();
        final testService = OgnAprsService(client: mockClient);

        when(
          () => mockClient.get(
            Uri.https('ddb.glidernet.org', '/download/', {
              'j': '1',
              'device_id': '1EFCCC',
            }),
            headers: any(named: 'headers'),
          ),
        ).thenThrow(http.ClientException('Connection reset'));

        final results = await testService.lookupDdbMultiple(['1EFCCC']);
        expect(results, isEmpty);
      },
    );
  });
}
