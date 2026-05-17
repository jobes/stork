import 'dart:typed_data';

import 'canard_bindings.dart'; // For CanardTransferType

enum DroneCanDataType {
  nodeStatus(341, 0x0F0868D0C1A7C6F1, isService: false),
  dynamicNodeIdAllocation(1, 0xb2a812620a11d40, isService: false),
  getNodeInfo(1, 0xEE468A8121C46A9E, isService: true), // Service
  staticPressure(1028, 0x44DC4133A6B487BA, isService: false),
  magneticFieldStrength(1029, 0x19932AA9E9558988, isService: false),
  getTransportStats(4, 0xbe6f76a7ec312b04, isService: true),
  restartNode(5, 0x569E05394A3017F0, isService: true),
  unknown(-1, 0, isService: false);

  final int id;
  final int signature;
  final bool isService;

  const DroneCanDataType(this.id, this.signature, {required this.isService});

  static DroneCanDataType fromId(int id, CanardTransferType transferType) {
    final bool isSvc = transferType != CanardTransferType.broadcast;
    return values.firstWhere(
      (e) => e.id == id && e.isService == isSvc,
      orElse: () => DroneCanDataType.unknown,
    );
  }
}

enum NodeHealth {
  ok(0),
  warning(1),
  error(2),
  critical(3);

  final int value;
  const NodeHealth(this.value);

  static NodeHealth fromInt(int value) =>
      values.firstWhere((e) => e.value == value, orElse: () => NodeHealth.ok);
}

enum NodeMode {
  operational(0),
  initialization(1),
  maintenance(2),
  softwareUpdate(3),
  offline(7);

  final int value;
  const NodeMode(this.value);

  static NodeMode fromInt(int value) => values.firstWhere(
    (e) => e.value == value,
    orElse: () => NodeMode.offline,
  );
}

class NodeStatus {
  final int uptimeSec;
  final NodeHealth health;
  final NodeMode mode;

  NodeStatus({
    required this.uptimeSec,
    required this.health,
    required this.mode,
  });

  factory NodeStatus.fromPayload(Uint8List payload) {
    if (payload.length < 5) {
      throw FormatException('Payload too short for NodeStatus');
    }

    final byteData = ByteData.sublistView(payload);
    final uptime = byteData.getUint32(0, Endian.little);

    final flags = byteData.getUint8(4);
    final healthInt = flags & 0x03; // Bits 0-1
    final modeInt = (flags >> 2) & 0x07; // Bits 2-4

    return NodeStatus(
      uptimeSec: uptime,
      health: NodeHealth.fromInt(healthInt),
      mode: NodeMode.fromInt(modeInt),
    );
  }

  @override
  String toString() {
    return 'NodeStatus(uptime: ${uptimeSec}s, health: ${health.name}, mode: ${mode.name})';
  }
}

class StaticPressure {
  final double staticPressure;

  StaticPressure({required this.staticPressure});

  factory StaticPressure.fromPayload(Uint8List payload) {
    if (payload.length < 4) {
      throw FormatException('Payload too short for StaticPressure');
    }

    final byteData = ByteData.sublistView(payload);
    final pressure = byteData.getFloat32(0, Endian.little);

    return StaticPressure(staticPressure: pressure);
  }

  @override
  String toString() {
    return 'StaticPressure(${staticPressure.toStringAsFixed(2)} Pa)';
  }
}
