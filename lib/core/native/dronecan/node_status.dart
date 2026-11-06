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

/// Application-level event emitted whenever a DroneCAN node status is received
/// or when the known-node registry must be discarded (e.g. on disconnect).
sealed class NodeStatusEvent {
  const NodeStatusEvent();
}

/// A [NodeStatus] heartbeat received from [nodeId] at [receivedAt].
final class NodeStatusReceivedEvent extends NodeStatusEvent {
  const NodeStatusReceivedEvent({
    required this.nodeId,
    required this.status,
    required this.receivedAt,
  });

  final int nodeId;
  final NodeStatus status;
  final DateTime receivedAt;
}

/// Emitted when the DroneCAN link is reset and all previously known nodes are
/// no longer valid.
final class NodeStatusRegistryClearedEvent extends NodeStatusEvent {
  const NodeStatusRegistryClearedEvent();
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

  /// Node-specific status code (`vendor_specific_status_code`).
  ///
  /// Its meaning is defined by the node vendor; `0` means "not provided".
  final int vendorSpecificStatusCode;

  NodeStatus({
    required this.uptimeSec,
    required this.health,
    required this.mode,
    this.vendorSpecificStatusCode = 0,
  });

  factory NodeStatus.fromPayload(Uint8List payload) {
    if (payload.length < 5) {
      throw FormatException('Payload too short for NodeStatus');
    }

    final byteData = ByteData.sublistView(payload);
    final uptime = byteData.getUint32(0, Endian.little);

    final flags = byteData.getUint8(4);
    // DroneCAN packs bit fields MSB-first: health occupies bits 7-6,
    // mode bits 5-3 and sub_mode bits 2-0.
    final healthInt = (flags >> 6) & 0x03;
    final modeInt = (flags >> 3) & 0x07;

    // Nodes may omit the trailing field; treat a truncated payload as zero.
    final vendorSpecificStatusCode = payload.length >= 7
        ? byteData.getUint16(5, Endian.little)
        : 0;

    return NodeStatus(
      uptimeSec: uptime,
      health: NodeHealth.fromInt(healthInt),
      mode: NodeMode.fromInt(modeInt),
      vendorSpecificStatusCode: vendorSpecificStatusCode,
    );
  }

  @override
  Uint8List toPayload() {
    final payload = Uint8List(7);
    final byteData = ByteData.sublistView(payload);
    byteData.setUint32(0, uptimeSec, Endian.little);

    final flags = ((health.value & 0x03) << 6) | ((mode.value & 0x07) << 3);
    byteData.setUint8(4, flags);
    byteData.setUint16(5, vendorSpecificStatusCode & 0xFFFF, Endian.little);
    return payload;
  }

  @override
  String toString() {
    return 'NodeStatus(uptime: ${uptimeSec}s, health: ${health.name}, '
        'mode: ${mode.name}, vendorStatus: $vendorSpecificStatusCode)';
  }
}
