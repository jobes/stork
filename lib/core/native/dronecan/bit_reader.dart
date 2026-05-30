import 'dart:math' as math;
import 'dart:typed_data';

class BitReader {
  final Uint8List bytes;
  int _bitOffset = 0;

  BitReader(this.bytes);

  int get bitOffset => _bitOffset;

  /// Reads [bitCount] bits from the payload and returns them as a signed or unsigned integer.
  int readBits(int bitCount, {bool signed = false}) {
    if (_bitOffset + bitCount > bytes.length * 8) {
      throw RangeError(
        'Reading past end of payload (requested $bitCount bits at $_bitOffset, total bits: ${bytes.length * 8})',
      );
    }

    int value = 0;
    final lastByteIdx = bitCount ~/ 8;
    final rem = bitCount % 8;

    for (int i = 0; i < bitCount; i++) {
      final bitIndex = _bitOffset + i;
      final byteIndex = bitIndex ~/ 8;
      final bitInByte = 7 - (bitIndex % 8);
      final bitVal = (bytes[byteIndex] >> bitInByte) & 1;

      final fByteIdx = i ~/ 8;
      final fBitInByteIdx = i % 8;
      final fBitsInThisByte = (fByteIdx == lastByteIdx) && (rem != 0) ? rem : 8;
      final destBitPos = 8 * fByteIdx + (fBitsInThisByte - 1 - fBitInByteIdx);

      value |= (bitVal << destBitPos);
    }

    _bitOffset += bitCount;

    if (signed) {
      // Sign extend the value
      final signBit = 1 << (bitCount - 1);
      if ((value & signBit) != 0) {
        value = value - (1 << bitCount);
      }
    }

    return value;
  }

  /// Reads [bitCount] bits as unsigned integer.
  int readUint(int bitCount) => readBits(bitCount, signed: false);

  /// Reads [bitCount] bits as signed integer.
  int readInt(int bitCount) => readBits(bitCount, signed: true);

  /// Reads 32 bits as a standard float32 value.
  double readFloat32() {
    final bits = readUint(32);
    final buffer = Uint8List(4);
    final byteData = ByteData.sublistView(buffer);
    byteData.setUint32(0, bits, Endian.little);
    return byteData.getFloat32(0, Endian.little);
  }

  /// Reads 16 bits as an IEEE 754 half-precision float (float16).
  double readFloat16() {
    final bits = readUint(16);
    final sign = (bits & 0x8000) != 0 ? -1.0 : 1.0;
    final exponent = (bits & 0x7C00) >> 10;
    final fraction = bits & 0x03FF;

    if (exponent == 0) {
      if (fraction == 0) {
        return sign * 0.0;
      } else {
        // Subnormal
        return sign * math.pow(2, -14) * (fraction / 1024.0);
      }
    } else if (exponent == 0x1F) {
      if (fraction == 0) {
        return sign * double.infinity;
      } else {
        return double.nan;
      }
    } else {
      // Normalized
      return sign * math.pow(2, exponent - 15) * (1.0 + fraction / 1024.0);
    }
  }
}
