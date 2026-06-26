import 'package:flutter_test/flutter_test.dart';
import 'package:stork/features/map/domain/models/notam.dart';

void main() {
  group('Notam Model Tests', () {
    test('fromJson handles valid dates correctly', () {
      final json = {
        'facilityDesignator': 'LZIB',
        'notamNumber': 'A1234/26',
        'featureName': 'BRATISLAVA',
        'issueDate': '2026-03-25T13:00:00Z',
        'startDate': '2026-03-25T13:15:00Z',
        'endDate': '2026-06-25T18:00:00Z',
        'icaoMessage': '',
        'id': 'A1234/26',
        'type': 'NOTAMN',
        'issuer': 'LZIB',
        'from': '2026-03-25T13:00:00Z',
        'to': '2026-06-25T18:00:00Z',
        'msg': 'TEST NOTAM MESSAGE',
        'fir': 'LZBB',
        'latitude': 48.17,
        'longitude': 17.17,
        'radius': 5000,
        'flightLevelLowerLimit': 0,
        'flightLevelUpperLimit': 999,
      };

      final notam = Notam.fromJson(json);
      expect(
        notam.from,
        equals(DateTime.parse('2026-03-25T13:00:00Z').toUtc()),
      );
      expect(notam.from.isUtc, isTrue);
      expect(notam.to, equals(DateTime.parse('2026-06-25T18:00:00Z').toUtc()));
      expect(notam.to.isUtc, isTrue);
    });

    test('fromJson handles missing or malformed dates fallback gracefully', () {
      final json = {
        'facilityDesignator': 'LZIB',
        'notamNumber': 'A1234/26',
        'featureName': 'BRATISLAVA',
        'issueDate': '2026-03-25T13:00:00Z',
        'startDate': '2026-03-25T13:15:00Z',
        'endDate': '2026-06-25T18:00:00Z',
        'icaoMessage': '',
        'id': 'A1234/26',
        'type': 'NOTAMN',
        'issuer': 'LZIB',
        'from': 'invalid_date',
        // 'to' is missing entirely
        'msg': 'TEST NOTAM MESSAGE',
        'fir': 'LZBB',
        'latitude': 48.17,
        'longitude': 17.17,
        'radius': 5000,
        'flightLevelLowerLimit': 0,
        'flightLevelUpperLimit': 999,
      };

      final notam = Notam.fromJson(json);
      final fallbackDate = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
      expect(notam.from, equals(fallbackDate));
      expect(notam.from.isUtc, isTrue);
      expect(notam.to, equals(fallbackDate));
      expect(notam.to.isUtc, isTrue);
    });
  });
}
