import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stork/core/native/dronecan/bit_reader.dart';

void main() {
  group('DroneCAN BitReader Tests', () {
    test('User case: byte with 64, read first 3 bits -> expected 2', () {
      // 64 is binary 01000000
      final bytes = Uint8List.fromList([64]);
      final reader = BitReader(bytes);

      final val = reader.readUint(3);
      expect(val, equals(2));
      expect(reader.bitOffset, equals(3));
    });

    test('User case: byte with 128, read first 3 bits -> expected 4', () {
      // 128 is binary 10000000
      final bytes = Uint8List.fromList([128]);
      final reader = BitReader(bytes);

      final val = reader.readUint(3);
      expect(val, equals(4));
      expect(reader.bitOffset, equals(3));
    });

    test('Read single bits', () {
      // 0xA5 = 165 = binary 10100101
      final bytes = Uint8List.fromList([0xA5]);
      final reader = BitReader(bytes);

      expect(reader.readUint(1), equals(1)); // bit 7
      expect(reader.readUint(1), equals(0)); // bit 6
      expect(reader.readUint(1), equals(1)); // bit 5
      expect(reader.readUint(1), equals(0)); // bit 4
      expect(reader.readUint(1), equals(0)); // bit 3
      expect(reader.readUint(1), equals(1)); // bit 2
      expect(reader.readUint(1), equals(0)); // bit 1
      expect(reader.readUint(1), equals(1)); // bit 0
    });

    test('Read multi-byte little endian integers', () {
      // 16-bit little-endian: 0x34, 0x12 -> 0x1234 (4660)
      final bytes = Uint8List.fromList([0x34, 0x12]);
      final reader = BitReader(bytes);

      expect(reader.readUint(16), equals(4660));
    });

    test('Read non-byte aligned crossing boundary', () {
      // bytes: [0x55, 0xAA]
      // 0x55 = 01010101
      // 0xAA = 10101010
      // Let's read 6 bits, then 6 bits.
      // Field 1 (6 bits): stream bits 0-5 from bytes[0] bits 7-2
      // bytes[0] bits 7-2 are 010101.
      // As a 6-bit field:
      // stream 0 -> value bit 5 = 0
      // stream 1 -> value bit 4 = 1
      // stream 2 -> value bit 3 = 0
      // stream 3 -> value bit 2 = 1
      // stream 4 -> value bit 1 = 0
      // stream 5 -> value bit 0 = 1
      // so 6-bit value is 010101 (21)
      // Field 2 (6 bits): stream bits 6-11
      // stream 6-7 from bytes[0] bits 1-0: 01
      // stream 8-11 from bytes[1] bits 7-4: 1010
      // Total 6 bits in stream: 0, 1, 1, 0, 1, 0
      // Since it's a 6-bit scalar, it's a single byte in the output.
      // stream 6 -> value bit 5 = 0
      // stream 7 -> value bit 4 = 1
      // stream 8 -> value bit 3 = 1
      // stream 9 -> value bit 2 = 0
      // stream 10 -> value bit 1 = 1
      // stream 11 -> value bit 0 = 0
      // value bits 5-0: 011010 (binary) = 26
      final bytes = Uint8List.fromList([0x55, 0xAA]);
      final reader = BitReader(bytes);

      expect(reader.readUint(6), equals(21));
      expect(reader.readUint(6), equals(26));
    });

    test('Read signed integers', () {
      // 3-bit signed integer with binary 111 (7 unsigned, -1 signed)
      final bytes = Uint8List.fromList([0xE0]); // binary 11100000
      final reader = BitReader(bytes);
      expect(reader.readInt(3), equals(-1));
    });
  });
}
