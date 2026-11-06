import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stork/core/native/dronecan/bit_writer.dart';
import 'package:stork/core/native/dronecan/tail_array.dart';

void main() {
  group('decodeTailBytes', () {
    test('decodes a tail array without a length prefix', () {
      final payload = Uint8List.fromList(utf8.encode('com.example.node'));

      expect(decodeTailBytes(payload, 0, maxLength: 80), equals(payload));
    });

    test('decodes a length-prefixed field at a bit offset', () {
      final writer = BitWriter(Uint8List(16))
        ..writeUint(0, 3) // unrelated leading bits
        ..writeUint(5, lengthPrefixBits(80));
      for (final byte in utf8.encode('hello')) {
        writer.writeUint(byte, 8);
      }

      expect(
        decodeTailBytes(writer.toPayload(), 3, maxLength: 80),
        equals(Uint8List.fromList(utf8.encode('hello'))),
      );
    });

    test('falls back to the tail array when the prefix is implausible', () {
      // `0x04 >> 1 == 2`, so this looks like a two-byte prefixed field, but the
      // shifted bytes are control characters rather than text.
      final payload = Uint8List.fromList([0x04, 0x41, 0x42]);

      final decoded = decodeTailBytes(
        payload,
        0,
        maxLength: 80,
        isPlausible: (bytes) =>
            bytes.every((byte) => byte >= 0x20 && byte < 0x7F),
      );

      expect(decoded, equals(payload));
    });

    test('returns an empty field when there is no trailing data', () {
      expect(decodeTailBytes(Uint8List.fromList([1, 2]), 16), isEmpty);
    });

    test('rejects a tail array longer than the field', () {
      final payload = Uint8List.fromList(List<int>.filled(10, 0x41));

      expect(
        () => decodeTailBytes(payload, 0, maxLength: 4),
        throwsFormatException,
      );
    });
  });

  group('decodeTailString', () {
    test('strips zero padding from the decoded text', () {
      final payload = Uint8List.fromList([0x41, 0x42, 0x00]);

      expect(decodeTailString(payload, 0, maxLength: 80), equals('AB'));
    });
  });
}
