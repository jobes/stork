// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dronecan_nodes_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Live, timestamped snapshots of all DroneCAN nodes seen on the bus.
///
/// The stream re-emits once per second so the UI can refresh "last seen"
/// without persisting any data.

@ProviderFor(droneCanNodes)
final droneCanNodesProvider = DroneCanNodesProvider._();

/// Live, timestamped snapshots of all DroneCAN nodes seen on the bus.
///
/// The stream re-emits once per second so the UI can refresh "last seen"
/// without persisting any data.

final class DroneCanNodesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<DroneCanNode>>,
          List<DroneCanNode>,
          Stream<List<DroneCanNode>>
        >
    with
        $FutureModifier<List<DroneCanNode>>,
        $StreamProvider<List<DroneCanNode>> {
  /// Live, timestamped snapshots of all DroneCAN nodes seen on the bus.
  ///
  /// The stream re-emits once per second so the UI can refresh "last seen"
  /// without persisting any data.
  DroneCanNodesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'droneCanNodesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$droneCanNodesHash();

  @$internal
  @override
  $StreamProviderElement<List<DroneCanNode>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<DroneCanNode>> create(Ref ref) {
    return droneCanNodes(ref);
  }
}

String _$droneCanNodesHash() => r'a65ae65a5b004c9121ed3462aa961a08f25a58af';

/// In-memory registry of the nodes seen on the bus.

@ProviderFor(droneCanNodeRepository)
final droneCanNodeRepositoryProvider = DroneCanNodeRepositoryProvider._();

/// In-memory registry of the nodes seen on the bus.

final class DroneCanNodeRepositoryProvider
    extends
        $FunctionalProvider<
          DroneCanNodeRepository,
          DroneCanNodeRepository,
          DroneCanNodeRepository
        >
    with $Provider<DroneCanNodeRepository> {
  /// In-memory registry of the nodes seen on the bus.
  DroneCanNodeRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'droneCanNodeRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$droneCanNodeRepositoryHash();

  @$internal
  @override
  $ProviderElement<DroneCanNodeRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DroneCanNodeRepository create(Ref ref) {
    return droneCanNodeRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DroneCanNodeRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DroneCanNodeRepository>(value),
    );
  }
}

String _$droneCanNodeRepositoryHash() =>
    r'3b37872b71a421d6d755070935ff4ede8a8edecd';
