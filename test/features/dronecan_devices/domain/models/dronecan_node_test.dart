import 'package:flutter_test/flutter_test.dart';
import 'package:stork/features/dronecan_devices/domain/models/dronecan_node.dart';

void main() {
  final node = DroneCanNode(
    nodeId: 7,
    health: DroneCanNodeHealth.warning,
    mode: DroneCanNodeMode.maintenance,
    uptimeSec: 120,
    lastSeen: DateTime(2026, 1, 1, 12),
    name: 'com.example.instrument',
    uniqueId: '0102030405060708090A0B0C0D0E0F10',
    swMajor: 1,
    swMinor: 2,
    swVcsCommit: 0x1234,
    swImageCrc: 'ABCDEF0123456789',
    hwMajor: 3,
    hwMinor: 4,
    certificateOfAuthenticity: 'CAFE',
  );

  test('keeps the heartbeat data and clears the node info on copyWith', () {
    final cleared = node.copyWith(
      name: null,
      uniqueId: null,
      swMajor: null,
      swMinor: null,
      swVcsCommit: null,
      swImageCrc: null,
      hwMajor: null,
      hwMinor: null,
      certificateOfAuthenticity: null,
    );

    expect(cleared.name, isNull);
    expect(cleared.uniqueId, isNull);
    expect(cleared.swImageCrc, isNull);
    expect(cleared.certificateOfAuthenticity, isNull);
    expect(cleared.health, equals(DroneCanNodeHealth.warning));
    expect(cleared.mode, equals(DroneCanNodeMode.maintenance));
    expect(cleared.uptimeSec, equals(120));
    expect(cleared.lastSeen, equals(DateTime(2026, 1, 1, 12)));
  });

  test('computes the time since the last heartbeat', () {
    expect(
      node.lastSeenAgo(DateTime(2026, 1, 1, 12, 0, 5)),
      equals(const Duration(seconds: 5)),
    );
  });

  test('compares by value', () {
    expect(node, equals(node.copyWith()));
    expect(node, isNot(equals(node.copyWith(nodeId: 8))));
  });
}
