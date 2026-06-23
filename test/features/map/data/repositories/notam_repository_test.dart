import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:maplibre/maplibre.dart';
import 'package:stork/features/map/data/repositories/notam_repository.dart';

void main() {
  group('HttpNotamRepository Tests', () {
    test(
      'fetchNotamsByFirs makes correct request and returns parsed NOTAMs',
      () async {
        final mockNotamList = [
          {
            'facilityDesignator': 'LZIB',
            'notamNumber': 'A1234/26',
            'featureName': 'BRATISLAVA/IVANKA',
            'issueDate': '2026-03-25T13:00:00Z',
            'startDate': '2026-03-25T13:15:00Z',
            'endDate': '2026-06-25T18:00:00Z',
            'traditionalMessage':
                'A1234/26 NOTAMN\n'
                'Q) LZBB/QFAXX/IV/NBO/A/000/999/4810N01710E025\n'
                'A) LZIB\n'
                'B) 2603251315\n'
                'C) 2606251800\n'
                'E) WIP ON APRON',
          },
        ];

        final mockClient = MockClient((request) async {
          expect(request.method, equals('POST'));
          expect(request.url.toString(), contains('notams.aim.faa.gov'));
          expect(request.bodyFields['searchType'], equals('0'));
          expect(
            request.bodyFields['designatorsForLocation'],
            equals('LZBB,LZIB'),
          );
          expect(request.bodyFields['offset'], equals('0'));
          expect(request.bodyFields['notamsOnly'], equals('false'));

          final responsePayload = {'notamList': mockNotamList};
          return http.Response(
            json.encode(responsePayload),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        });

        final repository = HttpNotamRepository(client: mockClient);
        final result = await repository.fetchNotamsByFirs(['LZBB', 'LZIB']);

        expect(result.length, equals(1));
        expect(result.first.id, equals('A1234/26'));
        expect(result.first.fir, equals('LZBB'));
        expect(result.first.msg, equals('Work in progress ON APRON'));
      },
    );

    test('fetchNotamsByFirs throws exception on HTTP error', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final repository = HttpNotamRepository(client: mockClient);
      expect(() => repository.fetchNotamsByFirs(['LZBB']), throwsException);
    });

    test(
      'fetchNotamsAroundPoint formats DMS correctly and calls API',
      () async {
        final mockClient = MockClient((request) async {
          expect(request.method, equals('POST'));
          expect(request.bodyFields['searchType'], equals('3'));
          // 48.16666 N -> latDeg: 48, latMin: 9, latSec: 59, latDir: N
          expect(request.bodyFields['latDegrees'], equals('48'));
          expect(request.bodyFields['latMinutes'], equals('9'));
          expect(request.bodyFields['latitudeDirection'], equals('N'));

          // 17.16666 E -> lonDeg: 17, lonMin: 9, lonSec: 59, lonDir: E
          expect(request.bodyFields['longDegrees'], equals('17'));
          expect(request.bodyFields['longMinutes'], equals('9'));
          expect(request.bodyFields['longitudeDirection'], equals('E'));

          // Radius: 50000m / 1852.0 = 27 NM
          expect(request.bodyFields['radius'], equals('27'));

          final responsePayload = {'notamList': []};
          return http.Response(json.encode(responsePayload), 200);
        });

        final repository = HttpNotamRepository(client: mockClient);
        final result = await repository.fetchNotamsAroundPoint(
          Geographic(lat: 48.16666, lon: 17.16666),
          50000,
        );

        expect(result, isEmpty);
      },
    );
  });
}
