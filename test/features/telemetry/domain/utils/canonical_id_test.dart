import 'package:flutter_test/flutter_test.dart';
import 'package:stork/features/telemetry/domain/utils/canonical_id.dart';

void main() {
  group('CanonicalId.normalize', () {
    test('strips ICAO: prefix and lowercases', () {
      expect(CanonicalId.normalize('ICAO:1EFCCC'), equals('1efccc'));
      expect(CanonicalId.normalize('icao:4b1234'), equals('4b1234'));
    });

    test('strips FLR: and OGN: prefixes and lowercases', () {
      expect(CanonicalId.normalize('FLR:1EFCCC'), equals('1efccc'));
      expect(CanonicalId.normalize('OGN:3C12AB'), equals('3c12ab'));
    });

    test('strips FLR and OGN direct prefixes', () {
      expect(CanonicalId.normalize('FLR1EFCCC'), equals('1efccc'));
      expect(CanonicalId.normalize('OGN3C12AB'), equals('3c12ab'));
      expect(CanonicalId.normalize('ICA1EFCCC'), equals('1efccc'));
    });

    test('handles plain hex string without prefix', () {
      expect(CanonicalId.normalize('1EFCCC'), equals('1efccc'));
      expect(CanonicalId.normalize('  4b1234  '), equals('4b1234'));
    });

    test('returns empty string for empty input', () {
      expect(CanonicalId.normalize(''), equals(''));
    });
  });
}
