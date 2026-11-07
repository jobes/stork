import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/models/dronecan_node_info_refresh.dart';
import '../../domain/models/dronecan_result.dart';
import '../../domain/models/transport_statistics.dart';
import 'dronecan_nodes_provider.dart';

part 'dronecan_node_actions_provider.g.dart';

/// User-triggered actions of a single DroneCAN node.
///
/// Repositories throw; the notifier turns the outcome into a
/// [DroneCanResult] so the presentation layer never handles exceptions.
@riverpod
class DroneCanNodeActions extends _$DroneCanNodeActions {
  @override
  void build(int nodeId) {
    // Stateless controller
  }

  /// Restarts the node; the value tells whether it accepted the request.
  Future<DroneCanResult<bool>> restart() async {
    try {
      final accepted = await ref
          .read(droneCanNodeRepositoryProvider)
          .restartNode(nodeId);
      return DroneCanSuccess(accepted);
    } catch (e) {
      debugPrint('DroneCAN restart of node $nodeId failed: $e');
      return DroneCanFailure(e);
    }
  }

  /// Re-reads the transport statistics of the node.
  Future<DroneCanResult<TransportStatistics>> transportStatistics() async {
    try {
      final stats = await ref
          .read(droneCanNodeRepositoryProvider)
          .getTransportStats(nodeId);
      return DroneCanSuccess(stats);
    } catch (e) {
      debugPrint('DroneCAN transport stats of node $nodeId failed: $e');
      return DroneCanFailure(e);
    }
  }
}

/// Actions that concern all known nodes.
@riverpod
class DroneCanNodesActions extends _$DroneCanNodesActions {
  @override
  void build() {
    // Stateless controller
  }

  /// Re-requests `GetNodeInfo` for every known node.
  ///
  /// The refresh succeeds even when only some nodes answered; the returned
  /// [DroneCanNodeInfoRefresh] tells how many of them did.
  Future<DroneCanResult<DroneCanNodeInfoRefresh>> refreshAll() async {
    try {
      final refresh = await ref
          .read(droneCanNodeRepositoryProvider)
          .refreshNodeInfo();
      return DroneCanSuccess(refresh);
    } catch (e) {
      debugPrint('DroneCAN node info refresh failed: $e');
      return DroneCanFailure(e);
    }
  }
}
