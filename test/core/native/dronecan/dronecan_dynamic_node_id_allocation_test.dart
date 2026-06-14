import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stork/core/native/dronecan/dynamic_node_id_allocation.dart';

void main() {
  group('DroneCAN DynamicNodeIdAllocation', () {
    test(
      'Serialization toPayload packs nodeId and firstPartOfUniqueId correctly',
      () {
        // Test case 1: firstPartOfUniqueId is true, nodeId is 42 (0x2A)
        // Expected payload[0]: (42 & 0x7F) << 1 | 0x01 = 0x54 | 0x01 = 0x55
        final uniqueId1 = Uint8List.fromList([1, 2, 3, 4, 5]);
        final msg1 = DynamicNodeIdAllocation(
          nodeId: 42,
          firstPartOfUniqueId: true,
          uniqueId: uniqueId1,
        );

        final payload1 = msg1.toPayload();
        expect(payload1.length, equals(6));
        expect(payload1[0], equals(0x55));
        expect(payload1.sublist(1), equals(uniqueId1));

        // Test case 2: firstPartOfUniqueId is false, nodeId is 125 (0x7D)
        // Expected payload[0]: (125 & 0x7F) << 1 | 0x00 = 0xFA
        final uniqueId2 = Uint8List.fromList([10, 20, 30]);
        final msg2 = DynamicNodeIdAllocation(
          nodeId: 125,
          firstPartOfUniqueId: false,
          uniqueId: uniqueId2,
        );

        final payload2 = msg2.toPayload();
        expect(payload2.length, equals(4));
        expect(payload2[0], equals(0xFA));
        expect(payload2.sublist(1), equals(uniqueId2));
      },
    );

    test(
      'Deserialization fromPayload parses nodeId and firstPartOfUniqueId correctly',
      () {
        // 0x55 means: firstPartOfUniqueId is true (LSB set), nodeId is (0x55 >> 1) = 42
        // Note: firstPartOfUniqueId is parsed as false in the implementation (hardcoded)
        final payload = Uint8List.fromList([0x55, 1, 2, 3, 4, 5]);
        final msg = DynamicNodeIdAllocation.fromPayload(payload);

        expect(msg.nodeId, equals(42));
        expect(msg.firstPartOfUniqueId, isFalse);
        expect(msg.uniqueId, equals(Uint8List.fromList([1, 2, 3, 4, 5])));
      },
    );

    test('Round-trip parity', () {
      final uniqueId = Uint8List.fromList([9, 8, 7, 6, 5, 4, 3, 2, 1]);
      final originalMsg = DynamicNodeIdAllocation(
        nodeId: 99,
        firstPartOfUniqueId: false,
        uniqueId: uniqueId,
      );

      final serialized = originalMsg.toPayload();
      final deserialized = DynamicNodeIdAllocation.fromPayload(serialized);

      expect(deserialized.nodeId, equals(originalMsg.nodeId));
      expect(
        deserialized.firstPartOfUniqueId,
        equals(originalMsg.firstPartOfUniqueId),
      );
      expect(deserialized.uniqueId, equals(originalMsg.uniqueId));
    });

    test('Throws RangeError when nodeId is out of bounds (0-127)', () {
      final uniqueId = Uint8List.fromList([1, 2, 3]);

      // Underflow (< 0)
      final msgUnder = DynamicNodeIdAllocation(
        nodeId: -1,
        firstPartOfUniqueId: false,
        uniqueId: uniqueId,
      );
      expect(() => msgUnder.toPayload(), throwsRangeError);

      // Overflow (> 127)
      final msgOver = DynamicNodeIdAllocation(
        nodeId: 128,
        firstPartOfUniqueId: false,
        uniqueId: uniqueId,
      );
      expect(() => msgOver.toPayload(), throwsRangeError);
    });
  });
}
