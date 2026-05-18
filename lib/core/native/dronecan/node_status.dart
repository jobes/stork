import 'dart:typed_data';
import 'dronecan_message.dart';

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

class NodeStatus implements DroneCanRequestResponseMessage {
  static const int messageId = 341;
  static const int messageSignature = 0x0F0868D0C1A7C6F1;
  static const bool messageIsService = false;

  @override
  int get id => messageId;

  @override
  int get signature => messageSignature;

  @override
  bool get isService => messageIsService;

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
  Uint8List toPayload() {
    final payload = Uint8List(7);
    final byteData = ByteData.sublistView(payload);
    byteData.setUint32(0, uptimeSec, Endian.little);

    final flags = (health.value & 0x03) | ((mode.value & 0x07) << 2);
    byteData.setUint8(4, flags);
    byteData.setUint16(
      5,
      0,
      Endian.little,
    ); // vendor_specific_status_code (bytes 5-6)
    return payload;
  }

  @override
  String toString() {
    return 'NodeStatus(uptime: ${uptimeSec}s, health: ${health.name}, mode: ${mode.name})';
  }
}
