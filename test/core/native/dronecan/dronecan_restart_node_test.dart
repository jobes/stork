import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stork/core/native/dronecan/restart_node.dart';

void main() {
  group('RestartNode', () {
    test('encodes the magic number as uint40 little endian', () {
      final payload = RestartNode().toPayload();

      expect(payload, equals([0x1E, 0x1B, 0x55, 0xCE, 0xAC]));
    });

    test('response decodes ok = true', () {
      expect(
        RestartNodeResponse.fromPayload(Uint8List.fromList([0x80])).ok,
        isTrue,
      );
    });

    test('response decodes ok = false', () {
      expect(
        RestartNodeResponse.fromPayload(Uint8List.fromList([0x00])).ok,
        isFalse,
      );
    });

    test('response rejects an empty payload', () {
      expect(
        () => RestartNodeResponse.fromPayload(Uint8List(0)),
        throwsFormatException,
      );
    });
  });
}
