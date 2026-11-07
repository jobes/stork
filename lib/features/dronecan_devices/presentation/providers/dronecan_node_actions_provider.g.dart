// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dronecan_node_actions_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// User-triggered actions of a single DroneCAN node.
///
/// Repositories throw; the notifier turns the outcome into a
/// [DroneCanResult] so the presentation layer never handles exceptions.

@ProviderFor(DroneCanNodeActions)
final droneCanNodeActionsProvider = DroneCanNodeActionsFamily._();

/// User-triggered actions of a single DroneCAN node.
///
/// Repositories throw; the notifier turns the outcome into a
/// [DroneCanResult] so the presentation layer never handles exceptions.
final class DroneCanNodeActionsProvider
    extends $NotifierProvider<DroneCanNodeActions, void> {
  /// User-triggered actions of a single DroneCAN node.
  ///
  /// Repositories throw; the notifier turns the outcome into a
  /// [DroneCanResult] so the presentation layer never handles exceptions.
  DroneCanNodeActionsProvider._({
    required DroneCanNodeActionsFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'droneCanNodeActionsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$droneCanNodeActionsHash();

  @override
  String toString() {
    return r'droneCanNodeActionsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  DroneCanNodeActions create() => DroneCanNodeActions();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DroneCanNodeActionsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$droneCanNodeActionsHash() =>
    r'83ada43e6e25a1064ab9e17169e83956dbba8c59';

/// User-triggered actions of a single DroneCAN node.
///
/// Repositories throw; the notifier turns the outcome into a
/// [DroneCanResult] so the presentation layer never handles exceptions.

final class DroneCanNodeActionsFamily extends $Family
    with $ClassFamilyOverride<DroneCanNodeActions, void, void, void, int> {
  DroneCanNodeActionsFamily._()
    : super(
        retry: null,
        name: r'droneCanNodeActionsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// User-triggered actions of a single DroneCAN node.
  ///
  /// Repositories throw; the notifier turns the outcome into a
  /// [DroneCanResult] so the presentation layer never handles exceptions.

  DroneCanNodeActionsProvider call(int nodeId) =>
      DroneCanNodeActionsProvider._(argument: nodeId, from: this);

  @override
  String toString() => r'droneCanNodeActionsProvider';
}

/// User-triggered actions of a single DroneCAN node.
///
/// Repositories throw; the notifier turns the outcome into a
/// [DroneCanResult] so the presentation layer never handles exceptions.

abstract class _$DroneCanNodeActions extends $Notifier<void> {
  late final _$args = ref.$arg as int;
  int get nodeId => _$args;

  void build(int nodeId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// Actions that concern all known nodes.

@ProviderFor(DroneCanNodesActions)
final droneCanNodesActionsProvider = DroneCanNodesActionsProvider._();

/// Actions that concern all known nodes.
final class DroneCanNodesActionsProvider
    extends $NotifierProvider<DroneCanNodesActions, void> {
  /// Actions that concern all known nodes.
  DroneCanNodesActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'droneCanNodesActionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$droneCanNodesActionsHash();

  @$internal
  @override
  DroneCanNodesActions create() => DroneCanNodesActions();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$droneCanNodesActionsHash() =>
    r'1efa4708570f1123cf3b311b135d5968ea3f1272';

/// Actions that concern all known nodes.

abstract class _$DroneCanNodesActions extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
