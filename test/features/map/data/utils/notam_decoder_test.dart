import 'package:flutter_test/flutter_test.dart';
import 'package:stork/features/map/data/utils/notam_decoder.dart';

void main() {
  group('NotamDecoder Tests', () {
    test('decodeMessage translates contraction words', () {
      final decoded = NotamDecoder.decodeMessage('AD CLSD DUE TO WIP');
      expect(decoded, equals('Aerodrome Closed DUE TO Work in progress'));
    });

    test('separateToParts parses standard parts correctly', () {
      const raw =
          'A1234/26 NOTAMN\n'
          'Q) LZBB/QFAXX/IV/NBO/A/000/999/4810N01710E025\n'
          'A) LZIB\n'
          'B) 2603251315\n'
          'C) 2606251800\n'
          'D) DAILY 0800-1600\n'
          'E) WIP ON APRON\n'
          'F) GND\n'
          'G) 1500FT AGL';

      final parts = NotamDecoder.separateToParts(raw);
      expect(parts['id'], equals('A1234/26 NOTAMN'));
      expect(parts['q'], equals('LZBB/QFAXX/IV/NBO/A/000/999/4810N01710E025'));
      expect(parts['a'], equals('LZIB'));
      expect(parts['b'], equals('2603251315'));
      expect(parts['c'], equals('2606251800'));
      expect(parts['d'], equals('DAILY 0800-1600'));
      expect(parts['e'], equals('WIP ON APRON'));
      expect(parts['f'], equals('GND'));
      expect(parts['g'], equals('1500FT AGL'));
    });

    test('decode decodes raw map to Notam object', () {
      final rawNotam = {
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
      };

      final notam = NotamDecoder.decode(rawNotam);

      expect(notam.id, equals('A1234/26'));
      expect(notam.type, equals('NOTAMN'));
      expect(notam.fir, equals('LZBB'));
      expect(notam.issuer, equals('LZIB'));
      expect(notam.latitude, closeTo(48.16666, 0.001));
      expect(notam.longitude, closeTo(17.16666, 0.001));
      expect(notam.radius, equals(25 * 1852.0)); // 25 NM in meters
      expect(notam.from, equals(DateTime.utc(2026, 3, 25, 13, 15)));
      expect(notam.to, equals(DateTime.utc(2026, 6, 25, 18, 0)));
      expect(notam.msg, equals('Work in progress ON APRON'));
    });
  });
}
