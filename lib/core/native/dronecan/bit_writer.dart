import 'dart:typed_data';

/// Bit-level writer for DroneCAN payloads.
///
/// Mirrors [BitReader]: a scalar is first laid out byte-wise in little-endian
/// order (the partial trailing byte is shifted so that the most significant
/// bit of the value lands on the most significant bit of that byte) and the
/// resulting bits are then copied most-significant-bit first into the payload.
class BitWriter {
  BitWriter(this._bytes);

  final Uint8List _bytes;
  int _bitOffset = 0;

  int get bitOffset => _bitOffset;

  /// Number of bytes needed to hold everything written so far.
  int get byteLength => (_bitOffset + 7) ~/ 8;

  /// Returns a copy of the payload truncated to the written bits.
  Uint8List toPayload() =>
      Uint8List.fromList(Uint8List.sublistView(_bytes, 0, byteLength));

  void skip(int bitCount) {
    if (_bitOffset + bitCount > _bytes.length * 8) {
      throw RangeError(
        'Writing past end of buffer (requested $bitCount bits at $_bitOffset, '
        'total bits: ${_bytes.length * 8})',
      );
    }
    _bitOffset += bitCount;
  }

  /// Writes an unsigned value of [bitCount] bits (up to 64).
  void writeUint(int value, int bitCount) {
    if (_bitOffset + bitCount > _bytes.length * 8) {
      throw RangeError(
        'Writing past end of buffer (requested $bitCount bits at $_bitOffset, '
        'total bits: ${_bytes.length * 8})',
      );
    }

    final byteCount = (bitCount + 7) ~/ 8;
    final field = Uint8List(byteCount);
    for (var i = 0; i < byteCount; i++) {
      // Arithmetic shift keeps the two's complement bits of negative values.
      field[i] = (value >> (8 * i)) & 0xFF;
    }
    final remainder = bitCount % 8;
    if (remainder != 0) {
      final lastIndex = bitCount ~/ 8;
      field[lastIndex] = (field[lastIndex] << (8 - remainder)) & 0xFF;
    }

    for (var i = 0; i < bitCount; i++) {
      final bit = (field[i ~/ 8] >> (7 - (i % 8))) & 1;
      if (bit != 0) {
        final absolute = _bitOffset + i;
        _bytes[absolute ~/ 8] |= 1 << (7 - (absolute % 8));
      }
    }
    _bitOffset += bitCount;
  }

  /// Writes a signed value of [bitCount] bits (up to 64) in two's complement.
  void writeInt(int value, int bitCount) => writeUint(value, bitCount);

  /// Writes 32 bits of an IEEE 754 single precision value.
  void writeFloat32(double value) {
    final buffer = ByteData(4)..setFloat32(0, value, Endian.little);
    writeUint(buffer.getUint32(0, Endian.little), 32);
  }
}
