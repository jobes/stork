import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stork/core/native/dronecan/fuel_tank_status.dart';

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

  void writeFloat32(double value) {
    final buffer = Uint8List(4);
    final byteData = ByteData.sublistView(buffer);
    byteData.setFloat32(0, value, Endian.little);
    final bits = byteData.getUint32(0, Endian.little);
    writeUint(bits, 32);
  }

  void writeFloat16(double value) {
    int bits = 0;
    if (value == 0.0) {
      bits = 0;
    } else if (value.isInfinite) {
      bits = 0x7C00 | (value.isNegative ? 0x8000 : 0);
    } else if (value.isNaN) {
      bits = 0x7C00 | 0x0200;
    } else {
      final sign = value.isNegative ? 0x8000 : 0;
      final absVal = value.abs();
      int exponent = (math.log(absVal) / math.ln2).floor() + 15;
      if (exponent >= 31) {
        bits = sign | 0x7C00;
      } else if (exponent <= 0) {
        final fraction = (absVal / math.pow(2, -14) * 1024.0).round();
        bits = sign | fraction;
      } else {
        final fraction = ((absVal / math.pow(2, exponent - 15) - 1.0) * 1024.0)
            .round();
        bits = sign | ((exponent & 0x1F) << 10) | (fraction & 0x03FF);
      }
    }
    writeUint(bits, 16);
  }

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
  group('FuelTankStatus message decoding', () {
    test('Decodes FuelTankStatus correctly', () {
      final writer = BitWriter();
      writer.writeUint(0, 9); // void9
      writer.writeUint(45, 7); // percent = 45%
      writer.writeFloat32(12500.0); // volume = 12500 cm³ (12.5 Liters)
      writer.writeFloat32(150.0); // rate = 150 cm³/min
      writer.writeFloat16(298.15); // temp = 298.15 K (25 °C)
      writer.writeUint(1, 8); // tank ID = 1

      final payload = writer.toBytes();
      expect(payload.length, equals(13));

      final msg = FuelTankStatus.fromPayload(payload);
      expect(msg.availableFuelVolumePercent, equals(45));
      expect(msg.availableFuelVolumeCm3, closeTo(12500.0, 0.01));
      expect(msg.fuelConsumptionRateCm3pm, closeTo(150.0, 0.01));
      expect(msg.fuelTemperature, closeTo(298.15, 0.2));
      expect(msg.fuelTankId, equals(1));
    });

    test('Throws FormatException if payload too short', () {
      final payload = Uint8List(12);
      expect(() => FuelTankStatus.fromPayload(payload), throwsFormatException);
    });
  });
}
