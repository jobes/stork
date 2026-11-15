import 'package:flutter_test/flutter_test.dart';
import 'package:stork/features/map/data/utils/notam_decoder.dart';

void main() {
  group('NotamDecoder Tests', () {
    test('decodeMessage translates contraction words', () {
      final decoded = NotamDecoder.decodeMessage('AD CLSD DUE TO WIP');
      expect(decoded, equals('Aerodrome Closed DUE TO Work in progress'));
    });

    test('decodeMessage translates compound abbreviations before words', () {
      expect(
        NotamDecoder.decodeMessage('AP LGT INOP; (FI/T), FI/P.\nBA\n  FAIR.'),
        'Airport Lighting Inoperative; (Flight Inspection Temporary), '
        'Flight Inspection Permanent.\nBraking action fair.',
      );
    });

    test('decodeMessage leaves partial compound abbreviations alone', () {
      expect(NotamDecoder.decodeMessage('XFI/P FI/T123'), 'XFI/P FI/T123');
    });

    const textOnlyFields = {
      'type': 'D',
      'number': '10/514',
      'startDate': '10/29/2026 0400',
      'endDate': 'PERM',
    };

    test('text-only decoding prefers the normalized ICAO message', () {
      final notam = NotamDecoder.decode({
        ...textOnlyFields,
        'icaoMessage': ' <b>TWY A13</b><br> LGT U/S ',
        'text': 'Different message',
      }, location: 'KJFK');

      expect(notam.msg, 'TWY A13\n LGT U/S');
      expect(notam.icaoMessage, notam.msg);
    });

    test(
      'text-only decoding uses the traditional message when text is empty',
      () {
        final notam = NotamDecoder.decode({
          ...textOnlyFields,
          'text': ' <p><br/></p> ',
          'traditionalMessage': '<p>TWY A13 LGT U/S</p>',
        }, location: 'KJFK');

        expect(notam.msg, 'TWY A13 LGT U/S');
        expect(notam.icaoMessage, notam.msg);
      },
    );

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
        'featureName': 'BRATISLAVA/IVANKA',
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
