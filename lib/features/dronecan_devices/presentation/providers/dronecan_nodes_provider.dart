import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:stork/core/services/cannelloni_service.dart';

import '../../data/repositories/dronecan_node_repository_impl.dart';
import '../../domain/models/dronecan_node.dart';
import '../../domain/repositories/dronecan_node_repository.dart';

export '../../domain/models/dronecan_node.dart';

part 'dronecan_nodes_provider.g.dart';

/// Live, timestamped snapshots of all DroneCAN nodes seen on the bus.
///
/// The stream re-emits once per second so the UI can refresh "last seen"
/// without persisting any data.
@riverpod
Stream<List<DroneCanNode>> droneCanNodes(Ref ref) {
  return ref.watch(droneCanNodeRepositoryProvider).watchNodes();
}

/// In-memory registry of the nodes seen on the bus.
@riverpod
DroneCanNodeRepository droneCanNodeRepository(Ref ref) {
  final transport = ref.watch(cannelloniServiceProvider.notifier);
  final repository = DroneCanNodeRepositoryImpl(transport);
  ref.onDispose(repository.dispose);
  return repository;
}
