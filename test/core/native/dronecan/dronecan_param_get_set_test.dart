import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stork/core/native/dronecan/bit_reader.dart';
import 'package:stork/core/native/dronecan/bit_writer.dart';
import 'package:stork/core/native/dronecan/param_get_set.dart';

/// Reference payloads were produced with a bit-packer that mirrors
/// `canardEncodeScalar` (little-endian scalars, most significant bit first in
/// the transfer), so they pin the wire format rather than re-using the encoder
/// under test.
Uint8List _bytes(List<int> values) => Uint8List.fromList(values);

void main() {
  group('BitWriter', () {
    test('round-trips scalars through BitReader', () {
      final payload = Uint8List(16);
      final writer = BitWriter(payload);
      writer.writeUint(1234, 13);
      writer.writeUint(5, 3);
      writer.writeInt(-42, 64);
      writer.writeUint(200, 16);

      final reader = BitReader(payload);
      expect(reader.readUint(13), equals(1234));
      expect(reader.readUint(3), equals(5));
      expect(reader.readInt(64), equals(-42));
      expect(reader.readUint(16), equals(200));
    });

    test('round-trips float32 values', () {
      final payload = Uint8List(8);
      BitWriter(payload)
        ..skip(5)
        ..writeFloat32(-12.25);

      final reader = BitReader(payload)..skip(5);
      expect(reader.readFloat32(), equals(-12.25));
    });
  });

  group('GetSetRequest', () {
    test('exposes the DroneCAN identifiers', () {
      expect(GetSetRequest.messageId, equals(11));
      expect(GetSetRequest.messageSignature, equals(0xA7B622F939D1A4D5));
      expect(const GetSetRequest.byIndex(0).isService, isTrue);
    });

    test('encodes a request by index', () {
      // 13 bits index + an empty value; the empty name tail array is omitted.
      expect(
        const GetSetRequest.byIndex(3).toPayload(),
        equals(_bytes([0x03, 0x00])),
      );
      expect(
        const GetSetRequest.byIndex(0x1234).toPayload(),
        equals(_bytes([0x34, 0x90])),
      );
    });

    test('encodes a read request by name', () {
      expect(
        const GetSetRequest.byName('P1').toPayload(),
        equals(_bytes([0x00, 0x00, 0x50, 0x31])),
      );
    });

    test('encodes a real value together with the name', () {
      expect(
        const GetSetRequest.byName(
          'P1',
          value: ParamValue.real(1.5),
        ).toPayload(),
        equals(_bytes([0x00, 0x02, 0x00, 0x00, 0xC0, 0x3F, 0x50, 0x31])),
      );
    });

    test('encodes an integer value together with the name', () {
      expect(
        const GetSetRequest.byName(
          'ESC_INDEX',
          value: ParamValue.integer(3),
        ).toPayload(),
        equals(
          _bytes([
            0x00, 0x01, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, //
            0x45, 0x53, 0x43, 0x5F, 0x49, 0x4E, 0x44, 0x45, 0x58,
          ]),
        ),
      );
    });

    test('encodes a string value', () {
      expect(
        const GetSetRequest.byName(
          'PARAM',
          value: ParamValue.string('hi'),
        ).toPayload(),
        equals(
          _bytes([0x00, 0x04, 0x02, 0x68, 0x69, 0x50, 0x41, 0x52, 0x41, 0x4D]),
        ),
      );
    });

    test('rejects names that do not fit the name field', () {
      final name = 'A' * (paramMaxNameLength + 1);
      expect(
        () => GetSetRequest.byName(name).toPayload(),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('GetSetResponse', () {
    test('decodes an integer parameter with default, max and min', () {
      final response = GetSetResponse.fromPayload(
        _bytes([
          0x01, 0x0A, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, //
          0x01, 0x0A, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
          0x02, 0x00, 0x00, 0xC8, 0x42, //
          0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, //
          0x50, 0x31,
        ]),
      );

      expect(response.name, equals('P1'));
      expect(response.value, equals(const ParamValue.integer(10)));
      expect(response.defaultValue, equals(const ParamValue.integer(10)));
      expect(response.maxValue?.value, equals(100));
      expect(response.minValue?.value, equals(0));
      expect(response.isKnown, isTrue);
    });

    test('decodes a length prefixed name from libuavcan nodes', () {
      final response = GetSetResponse.fromPayload(
        _bytes([
          0x01, 0x0A, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, //
          0x01, 0x0A, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
          0x02, 0x00, 0x00, 0xC8, 0x42, //
          0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, //
          0x04, 0xA0, 0x62,
        ]),
      );

      expect(response.name, equals('P1'));
      expect(response.value, equals(const ParamValue.integer(10)));
    });

    test('decodes a real parameter without bounds', () {
      final response = GetSetResponse.fromPayload(
        _bytes([
          0x02, 0x00, 0x00, 0x00, 0x3F, //
          0x00, 0x00, 0x00, //
          0x45, 0x53, 0x43,
        ]),
      );

      expect(response.name, equals('ESC'));
      expect(response.value?.type, equals(ParamValueType.real));
      expect(response.value?.realValue, equals(0.5));
      expect(response.defaultValue, isNull);
      expect(response.maxValue, isNull);
      expect(response.minValue, isNull);
    });

    test('decodes a boolean value', () {
      // void5, boolean tag (3), flag 1, void5, empty default, void6, empty
      // max, void6, empty min, then the name.
      final payload = Uint8List(12);
      final writer = BitWriter(payload)
        ..skip(5)
        ..writeUint(ParamValueType.boolean.tag, 3)
        ..writeUint(1, 8)
        ..writeUint(0, 5 + 3)
        ..writeUint(0, 6 + 2)
        ..writeUint(0, 6 + 2);
      for (final char in 'OK'.codeUnits) {
        writer.writeUint(char, 8);
      }

      final response = GetSetResponse.fromPayload(writer.toPayload());

      expect(response.value, equals(const ParamValue.boolean(true)));
      expect(response.name, equals('OK'));
    });

    test('decodes a string value', () {
      final payload = Uint8List(24);
      final writer = BitWriter(payload)
        ..skip(5)
        ..writeUint(ParamValueType.string.tag, 3)
        ..writeUint(2, 8)
        ..writeUint('a'.codeUnitAt(0), 8)
        ..writeUint('b'.codeUnitAt(0), 8)
        ..writeUint(0, 5 + 3)
        ..writeUint(0, 6 + 2)
        ..writeUint(0, 6 + 2);
      for (final char in 'STR'.codeUnits) {
        writer.writeUint(char, 8);
      }

      final response = GetSetResponse.fromPayload(writer.toPayload());

      expect(response.value, equals(const ParamValue.string('ab')));
      expect(response.name, equals('STR'));
    });

    test('treats an unnamed response as an unknown parameter', () {
      final response = GetSetResponse.fromPayload(
        _bytes([0x00, 0x00, 0x00, 0x00]),
      );

      expect(response.name, isEmpty);
      expect(response.value, isNull);
      expect(response.isKnown, isFalse);
    });

    test('tolerates trailing zero truncation', () {
      final response = GetSetResponse.fromPayload(_bytes([0x00, 0x00]));

      expect(response.name, isEmpty);
      expect(response.isKnown, isFalse);
    });
  });

  group('ExecuteOpcode', () {
    test('exposes the DroneCAN identifiers', () {
      expect(ExecuteOpcodeRequest.messageId, equals(10));
      expect(ExecuteOpcodeRequest.messageSignature, equals(0x3B131AC5EB69D2CD));
    });

    test('encodes save and erase requests', () {
      expect(
        const ExecuteOpcodeRequest(ExecuteOpcodeRequest.opcodeSave).toPayload(),
        equals(_bytes([0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])),
      );
      expect(
        const ExecuteOpcodeRequest(
          ExecuteOpcodeRequest.opcodeErase,
        ).toPayload(),
        equals(_bytes([0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])),
      );
    });

    test('decodes a successful response', () {
      final response = ExecuteOpcodeResponse.fromPayload(
        _bytes([0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80]),
      );

      expect(response.ok, isTrue);
      expect(response.argument, equals(0));
    });

    test('decodes a rejected response', () {
      final response = ExecuteOpcodeResponse.fromPayload(
        _bytes([0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]),
      );

      expect(response.ok, isFalse);
    });
  });
}
