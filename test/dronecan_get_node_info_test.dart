import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stork/core/native/dronecan/get_node_info.dart';
import 'package:stork/core/native/dronecan/node_status.dart';

void main() {
  group('GetNodeInfoResponse', () {
    final validUniqueId = Uint8List.fromList(List.generate(16, (i) => i + 1));
    final invalidUniqueIdTooShort = Uint8List.fromList(List.generate(15, (i) => i + 1));
    final invalidUniqueIdTooLong = Uint8List.fromList(List.generate(17, (i) => i + 1));

    test('Constructing and serializing with valid 16-byte uniqueId works', () {
      final response = GetNodeInfoResponse(
        status: NodeStatus(
          uptimeSec: 100,
          health: NodeHealth.ok,
          mode: NodeMode.operational,
        ),
        swMajor: 1,
        swMinor: 2,
        uniqueId: validUniqueId,
        name: 'test.node',
      );

      expect(response.uniqueId.length, equals(16));
      final payload = response.toPayload();
      expect(payload, isNotNull);
      expect(payload.isNotEmpty, isTrue);
    });

    test('Constructing with invalid uniqueId length throws ArgumentError', () {
      expect(
        () => GetNodeInfoResponse(
          status: NodeStatus(
            uptimeSec: 100,
            health: NodeHealth.ok,
            mode: NodeMode.operational,
          ),
          swMajor: 1,
          swMinor: 2,
          uniqueId: invalidUniqueIdTooShort,
          name: 'test.node',
        ),
        throwsArgumentError,
      );

      expect(
        () => GetNodeInfoResponse(
          status: NodeStatus(
            uptimeSec: 100,
            health: NodeHealth.ok,
            mode: NodeMode.operational,
          ),
          swMajor: 1,
          swMinor: 2,
          uniqueId: invalidUniqueIdTooLong,
          name: 'test.node',
        ),
        throwsArgumentError,
      );
    });

    test('Async factory create works with valid uniqueId and fails with invalid length', () async {
      final response = await GetNodeInfoResponse.create(validUniqueId);
      expect(response.uniqueId, equals(validUniqueId));

      expect(
        () => GetNodeInfoResponse.create(invalidUniqueIdTooShort),
        throwsArgumentError,
      );
    });
  });
}
