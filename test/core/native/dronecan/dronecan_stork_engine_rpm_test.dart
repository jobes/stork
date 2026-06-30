import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stork/core/native/dronecan/stork_engine_rpm.dart';

class BitWriter {
  final List<int> _bits = [];

  void writeBits(int value, int bitCount) {
    final lastByteIdx = bitCount ~/ 8;
    final rem = bitCount % 8;

    for (int i = 0; i < bitCount; i++) {
      final fByteIdx = i ~/ 8;
      final fBitInByteIdx = i % 8;
      final fBitsInThisByte = (fByteIdx == lastByteIdx) && (rem != 0) ? rem : 8;
      final destBitPos = 8 * fByteIdx + (fBitsInThisByte - 1 - fBitInByteIdx);

      final bitVal = (value >> destBitPos) & 1;
      _bits.add(bitVal);
    }
  }

  void writeUint(int value, int bitCount) => writeBits(value, bitCount);

  Uint8List toBytes() {
    final numBytes = (_bits.length + 7) ~/ 8;
    final bytes = Uint8List(numBytes);
    for (int i = 0; i < _bits.length; i++) {
      final byteIndex = i ~/ 8;
      final bitInByte = 7 - (i % 8);
      bytes[byteIndex] |= (_bits[i] << bitInByte);
    }
    return bytes;
  }
}

void main() {
  group('StorkEngineRpm message decoding', () {
    test('Decodes StorkEngineRpm correctly', () {
      final writer = BitWriter();
      writer.writeUint(2, 2); // state = 2
      writer.writeUint(3, 6); // ecuIndex = 3
      writer.writeUint(65, 7); // engineLoadPercent = 65
      writer.writeUint(5200, 17); // engineSpeedRpm = 5200
      writer.writeUint(80, 7); // throttlePositionPercent = 80

      final payload = writer.toBytes();
      // 39 bits should be padded to 5 bytes (40 bits)
      expect(payload.length, equals(5));

      final msg = StorkEngineRpm.fromPayload(payload);
      expect(msg.state, equals(2));
      expect(msg.ecuIndex, equals(3));
      expect(msg.engineLoadPercent, equals(65));
      expect(msg.engineSpeedRpm, equals(5200));
      expect(msg.throttlePositionPercent, equals(80));
    });

    test('Throws FormatException if payload too short', () {
      final payload = Uint8List(4);
      expect(() => StorkEngineRpm.fromPayload(payload), throwsFormatException);
    });
  });
}
