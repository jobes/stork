import 'package:freezed_annotation/freezed_annotation.dart';

part 'dronecan_node.freezed.dart';

/// Health reported by a `uavcan.protocol.NodeStatus` heartbeat.
enum DroneCanNodeHealth { ok, warning, error, critical }

/// Operating mode reported by a `uavcan.protocol.NodeStatus` heartbeat.
enum DroneCanNodeMode {
  operational,
  initialization,
  maintenance,
  softwareUpdate,
  offline,
}

/// A DroneCAN node (flight instrument) discovered on the bus.
///
/// Instances are transient: they exist only for the current connection and are
/// never persisted.
@freezed
abstract class DroneCanNode with _$DroneCanNode {
  const DroneCanNode._();

  const factory DroneCanNode({
    required int nodeId,
    required DroneCanNodeHealth health,
    required DroneCanNodeMode mode,
    required int uptimeSec,
    required DateTime lastSeen,
    @Default(0) int vendorSpecificStatusCode,
    String? name,
    String? uniqueId,
    int? swMajor,
    int? swMinor,
    int? swOptionalFieldFlags,
    int? swVcsCommit,
    String? swImageCrc,
    int? hwMajor,
    int? hwMinor,
    String? certificateOfAuthenticity,
  }) = _DroneCanNode;

  /// Time elapsed since the last received heartbeat.
  Duration lastSeenAgo([DateTime? now]) =>
      (now ?? DateTime.now()).difference(lastSeen);
}
