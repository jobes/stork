import 'dart:convert';
import 'dart:typed_data';

import 'bit_reader.dart';
import 'bit_writer.dart';

/// Number of bits a dynamic array with [capacity] items uses for its length.
///
/// DroneCAN sizes the prefix so that every length up to the capacity fits, so
/// `uint8[<=92]` uses 7 bits while `uint8[<=200]` uses 8 bits.
int lengthPrefixBits(int capacity) => capacity.bitLength;

/// Encodes a `uint8[<=maxLength]` field that is the last field of a message.
///
/// DroneCAN omits the length prefix of a trailing dynamic array on classic CAN
/// (tail array optimization), so only the bytes are written.
void writeTailString(
  BitWriter writer,
  String value, {
  required int maxLength,
  String fieldName = 'value',
}) {
  final bytes = utf8.encode(value);
  if (bytes.length > maxLength) {
    throw ArgumentError(
      'The $fieldName is longer than $maxLength bytes: ${bytes.length}',
    );
  }
  for (final byte in bytes) {
    writer.writeUint(byte, 8);
  }
}

/// Decodes a trailing `uint8[<=maxLength]` field into its raw bytes.
///
/// Both forms are accepted: the tail array sent without a length prefix (the
/// DroneCAN default on classic CAN) and the length-prefixed form used by
/// libuavcan v0 based nodes.
///
/// [isPlausible] can reject a length-prefixed interpretation whose prefix was
/// assumed by mistake, in which case the tail-array form is used instead.
Uint8List decodeTailBytes(
  Uint8List payload,
  int bitOffset, {
  int maxLength = 200,
  bool Function(Uint8List value)? isPlausible,
}) {
  final totalBits = payload.length * 8;
  if (bitOffset >= totalBits) return Uint8List(0);

  final remainingBits = totalBits - bitOffset;
  final prefixBits = lengthPrefixBits(maxLength);

  if (remainingBits >= prefixBits) {
    final prefixLength = _readBitsAt(payload, bitOffset, prefixBits);
    final prefixedBits = prefixBits + 8 * prefixLength;

    // The prefix is only assumed when it covers the rest of the payload (up to
    // the padding of the last byte).
    if (prefixLength <= maxLength &&
        prefixedBits <= remainingBits &&
        remainingBits - prefixedBits < 8) {
      final value = _readBytes(payload, bitOffset + prefixBits, prefixLength);
      if (isPlausible == null || isPlausible(value)) return value;
    }
  }

  final length = remainingBits ~/ 8;
  if (length > maxLength) {
    throw FormatException('Field is longer than $maxLength bytes: $length');
  }
  return _readBytes(payload, bitOffset, length);
}

/// Decodes a trailing `uint8[<=maxLength]` field as text.
String decodeTailString(
  Uint8List payload,
  int bitOffset, {
  int maxLength = 200,
}) {
  // Producers may pad the payload with zeroes; they are not part of the text.
  return utf8
      .decode(
        decodeTailBytes(payload, bitOffset, maxLength: maxLength),
        allowMalformed: true,
      )
      .replaceAll('\u0000', '');
}

Uint8List _readBytes(Uint8List payload, int bitOffset, int length) {
  final reader = BitReader(payload)..skip(bitOffset);
  return Uint8List.fromList(
    List<int>.generate(length, (_) => reader.readUint(8), growable: false),
  );
}

int _readBitsAt(Uint8List payload, int bitOffset, int bitCount) {
  final reader = BitReader(payload)..skip(bitOffset);
  return reader.readUint(bitCount);
}
