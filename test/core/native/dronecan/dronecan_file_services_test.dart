import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stork/core/native/dronecan/file_services.dart';
import 'package:stork/core/native/dronecan/tail_array.dart';

/// Reference payloads were produced with a bit-packer that mirrors
/// `canardEncodeScalar` (little-endian scalars, most significant bit first in
/// the transfer) so they pin the wire format.
Uint8List _bytes(List<int> values) => Uint8List.fromList(values);

void main() {
  group('BeginFirmwareUpdateRequest', () {
    test('exposes the DroneCAN identifiers', () {
      const request = BeginFirmwareUpdateRequest(imageFileRemotePath: 'fw.bin');
      expect(BeginFirmwareUpdateRequest.messageId, equals(40));
      expect(
        BeginFirmwareUpdateRequest.messageSignature,
        equals(0xB7D725DF72724126),
      );
      expect(request.isService, isTrue);
    });

    test('encodes the source node id and the path without a length prefix', () {
      expect(
        const BeginFirmwareUpdateRequest(
          imageFileRemotePath: 'fw.bin',
        ).toPayload(),
        equals(_bytes([0x00, 0x66, 0x77, 0x2E, 0x62, 0x69, 0x6E])),
      );
      expect(
        const BeginFirmwareUpdateRequest(
          sourceNodeId: 42,
          imageFileRemotePath: 'a.bin',
        ).toPayload(),
        equals(_bytes([0x2A, 0x61, 0x2E, 0x62, 0x69, 0x6E])),
      );
    });

    test('rejects a path that does not fit', () {
      final path = 'A' * (filePathMaxLength + 1);
      expect(
        () => BeginFirmwareUpdateRequest(imageFileRemotePath: path).toPayload(),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('BeginFirmwareUpdateResponse', () {
    test('decodes a successful response', () {
      final response = BeginFirmwareUpdateResponse.fromPayload(_bytes([0x00]));

      expect(response.isOk, isTrue);
      expect(response.optionalErrorMessage, isEmpty);
    });

    test('decodes an error with a message', () {
      final response = BeginFirmwareUpdateResponse.fromPayload(
        _bytes([0x01, ...'busy'.codeUnits]),
      );

      expect(response.isOk, isFalse);
      expect(
        response.error,
        equals(BeginFirmwareUpdateResponse.errorInvalidMode),
      );
      expect(response.optionalErrorMessage, equals('busy'));
    });
  });

  group('FileReadRequest', () {
    test('exposes the DroneCAN identifiers', () {
      const request = FileReadRequest(offset: 0, path: 'fw.bin');
      expect(FileReadRequest.messageId, equals(48));
      expect(FileReadRequest.messageSignature, equals(0x8DCDCA939F33F678));
      expect(request.isService, isTrue);
    });

    test('encodes and decodes the offset and the path', () {
      final payload = const FileReadRequest(
        offset: 0x123456789A,
        path: 'fw.bin',
      ).toPayload();

      expect(
        payload,
        equals(
          _bytes([
            0x9A, 0x78, 0x56, 0x34, 0x12, // offset
            0x66, 0x77, 0x2E, 0x62, 0x69, 0x6E,
          ]),
        ),
      );
      final decoded = FileReadRequest.fromPayload(payload);
      expect(decoded.offset, equals(0x123456789A));
      expect(decoded.path, equals('fw.bin'));
    });

    test('decodes a request from a node', () {
      final decoded = FileReadRequest.fromPayload(
        _bytes([
          0x00,
          0x01,
          0x00,
          0x00,
          0x00,
          0x66,
          0x77,
          0x2E,
          0x62,
          0x69,
          0x6E,
        ]),
      );

      expect(decoded.offset, equals(256));
      expect(decoded.path, equals('fw.bin'));
    });

    test('decodes a length prefixed path', () {
      // 40-bit offset 0 followed by the 8-bit length prefix (capacity 200) and
      // "fw.bin".
      final decoded = FileReadRequest.fromPayload(
        _bytes([
          0x00,
          0x00,
          0x00,
          0x00,
          0x00,
          0x06,
          0x66,
          0x77,
          0x2E,
          0x62,
          0x69,
          0x6E,
        ]),
      );

      expect(decoded.offset, equals(0));
      expect(decoded.path, equals('fw.bin'));
    });

    test('rejects a truncated payload', () {
      expect(
        () => FileReadRequest.fromPayload(_bytes([0x00, 0x01])),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('FileReadResponse', () {
    test('encodes the error and the data without padding', () {
      expect(
        const FileReadResponse(data: [0x01, 0x02, 0x03]).toPayload(),
        equals(_bytes([0x00, 0x00, 0x01, 0x02, 0x03])),
      );
      expect(
        const FileReadResponse(
          error: FileReadResponse.errorNotFound,
        ).toPayload(),
        equals(_bytes([0x02, 0x00])),
      );
    });

    test('round-trips a full chunk', () {
      final data = List<int>.generate(256, (index) => index & 0xFF);
      final payload = FileReadResponse(data: data).toPayload();

      // 16 bits of error plus the 256 data bytes, without any padding.
      expect(payload, hasLength(258));
      final decoded = FileReadResponse.fromPayload(payload);
      expect(decoded.error, equals(FileReadResponse.errorOk));
      expect(decoded.data, equals(data));
    });

    test('round-trips an empty chunk', () {
      final decoded = FileReadResponse.fromPayload(
        const FileReadResponse().toPayload(),
      );

      expect(decoded.data, isEmpty);
    });

    test('rejects more than one chunk of data', () {
      expect(
        () => FileReadResponse(
          data: List<int>.filled(fileReadChunkSize + 1, 0),
        ).toPayload(),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('decodeTailString', () {
    test('returns an empty string when nothing follows', () {
      expect(
        decodeTailString(_bytes([0x00, 0x00]), 16, maxLength: 10),
        isEmpty,
      );
    });

    test('decodes a bare tail array', () {
      expect(
        decodeTailString(_bytes([0x00, ...'abc'.codeUnits]), 8, maxLength: 10),
        equals('abc'),
      );
    });

    test('decodes a prefixed tail array', () {
      expect(
        // A capacity of 100 uses a 7-bit prefix, so 3 occupies the high bits
        // of the second byte.
        decodeTailString(
          _bytes([0x00, 0x06, 0xC2, 0xC4, 0xC6]),
          8,
          maxLength: 100,
        ),
        equals('abc'),
      );
    });

    test('sizes the prefix by the array capacity', () {
      expect(lengthPrefixBits(92), equals(7));
      expect(lengthPrefixBits(100), equals(7));
      expect(lengthPrefixBits(200), equals(8));
      expect(lengthPrefixBits(256), equals(9));
    });

    test('drops zero padding', () {
      expect(
        decodeTailString(
          _bytes([0x00, ...'ab'.codeUnits, 0x00, 0x00]),
          8,
          maxLength: 10,
        ),
        equals('ab'),
      );
    });
  });
}
