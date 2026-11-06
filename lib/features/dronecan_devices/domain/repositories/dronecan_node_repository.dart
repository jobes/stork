import 'dart:typed_data';

import '../models/dronecan_node.dart';
import '../models/dronecan_node_info_refresh.dart';
import '../models/dronecan_parameter.dart';
import '../models/firmware_update_progress.dart';
import '../models/transport_statistics.dart';

/// Provides the live list of DroneCAN nodes seen on the bus and lets the user
/// manage them.
///
/// All data is kept only in memory — nothing is persisted between sessions.
abstract interface class DroneCanNodeRepository {
  /// Emits a new snapshot immediately on subscription and then every time a
  /// heartbeat or node info update arrives (also once per second so callers can
  /// recompute "last seen").
  Stream<List<DroneCanNode>> watchNodes();

  /// Re-requests `GetNodeInfo` for every known node.
  ///
  /// Returns how many nodes answered, so the UI can tell a full refresh from a
  /// partial one (a node that does not implement `GetNodeInfo` never answers).
  Future<DroneCanNodeInfoRefresh> refreshNodeInfo();

  /// Restarts the node with [nodeId].
  ///
  /// Returns `true` when the node accepted the restart.
  Future<bool> restartNode(int nodeId);

  /// Reads the transport statistics of the node with [nodeId].
  Future<TransportStatistics> getTransportStats(int nodeId);

  /// Reads the parameter stored at [index] on [nodeId].
  ///
  /// Returns `null` when the node has no parameter with that index, which is
  /// how the end of the parameter list is detected.
  Future<DroneCanParameter?> getParameterByIndex(int nodeId, int index);

  /// Streams the parameter list of [nodeId] while it is read from the node.
  ///
  /// The first event is always empty; every following event carries all
  /// parameters read so far, so the UI can fill its table progressively. The
  /// stream closes when the node reports no further parameter, and emits an
  /// error when a read fails (the snapshots emitted before stay valid).
  Stream<List<DroneCanParameter>> watchParameters(int nodeId);

  /// Assigns [value] to the parameter [name] on [nodeId] and returns the
  /// parameter as reported by the node afterwards.
  ///
  /// Throws [StateError] when the node does not know the parameter.
  Future<DroneCanParameter> setParameterValue(
    int nodeId,
    DroneCanParameter parameter,
    DroneCanParamValue value,
  );

  /// Saves the current configuration of [nodeId] to its non-volatile storage
  /// (`uavcan.protocol.param.ExecuteOpcode` with `OPCODE_SAVE`).
  Future<bool> storeParameters(int nodeId);

  /// Clears the non-volatile storage of [nodeId] and lets the parameters fall
  /// back to their defaults (`OPCODE_ERASE`).
  Future<bool> eraseParameters(int nodeId);

  /// Starts a firmware update of [nodeId] with [firmware].
  ///
  /// [fileName] is the name the node asks for when it pulls the image over
  /// `uavcan.protocol.file.Read`; the image itself is served from memory.
  ///
  /// The returned stream emits the progress until the whole image has been
  /// served (or the update fails) and then closes. Throws [StateError] when
  /// another update is already running.
  Stream<FirmwareUpdateProgress> updateFirmware(
    int nodeId,
    String fileName,
    Uint8List firmware,
  );

  void dispose();
}
