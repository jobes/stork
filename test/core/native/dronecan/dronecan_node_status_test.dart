import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stork/core/native/dronecan/node_status.dart';

void main() {
  group('NodeStatus', () {
    test('decodes MSB-first packed health and mode bits', () {
      final payload = Uint8List.fromList([
        0x04, 0x03, 0x02, 0x01, // uptime = 0x01020304
        0x50, // health = warning (bits 7-6), mode = maintenance (bits 5-3)
        0x00, 0x00,
      ]);

      final status = NodeStatus.fromPayload(payload);

      expect(status.uptimeSec, equals(0x01020304));
      expect(status.health, equals(NodeHealth.warning));
      expect(status.mode, equals(NodeMode.maintenance));
    });

    test('encodes health and mode MSB-first', () {
      final payload = NodeStatus(
        uptimeSec: 0x01020304,
        health: NodeHealth.warning,
        mode: NodeMode.maintenance,
      ).toPayload();

      expect(payload.sublist(0, 4), equals([0x04, 0x03, 0x02, 0x01]));
      expect(payload[4], equals(0x50));
    });

    test('round-trips every health and mode combination', () {
      for (final health in NodeHealth.values) {
        for (final mode in NodeMode.values) {
          final decoded = NodeStatus.fromPayload(
            NodeStatus(uptimeSec: 1234, health: health, mode: mode).toPayload(),
          );

          expect(decoded.uptimeSec, equals(1234));
          expect(decoded.health, equals(health));
          expect(decoded.mode, equals(mode));
        }
      }
    });

    test('ignores the sub_mode bits', () {
      // health = ok (0), mode = operational (0), sub_mode = 0b111.
      final status = NodeStatus.fromPayload(
        Uint8List.fromList([0, 0, 0, 0, 0x07]),
      );

      expect(status.health, equals(NodeHealth.ok));
      expect(status.mode, equals(NodeMode.operational));
    });

    test('decodes vendor_specific_status_code (little endian)', () {
      final status = NodeStatus.fromPayload(
        Uint8List.fromList([0, 0, 0, 0, 0x00, 0x34, 0x12]),
      );

      expect(status.vendorSpecificStatusCode, equals(0x1234));
    });

    test('treats a truncated vendor code as zero', () {
      final status = NodeStatus.fromPayload(
        Uint8List.fromList([2, 0, 0, 0, 0x00]),
      );

      expect(status.vendorSpecificStatusCode, equals(0));
    });

    test('round-trips vendor_specific_status_code', () {
      final decoded = NodeStatus.fromPayload(
        NodeStatus(
          uptimeSec: 7,
          health: NodeHealth.critical,
          mode: NodeMode.softwareUpdate,
          vendorSpecificStatusCode: 0xABCD,
        ).toPayload(),
      );

      expect(decoded.vendorSpecificStatusCode, equals(0xABCD));
      expect(decoded.health, equals(NodeHealth.critical));
      expect(decoded.mode, equals(NodeMode.softwareUpdate));
    });

    test('rejects a payload that is too short', () {
      expect(
        () => NodeStatus.fromPayload(Uint8List.fromList([0, 0, 0])),
        throwsFormatException,
      );
    });
  });
}
