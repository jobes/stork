// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dronecan_configuration_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Reads and writes the parameters of a single DroneCAN node.
///
/// The node is scanned by index until it reports no further parameter, so the
/// table fills up progressively instead of waiting for the whole list.

@ProviderFor(DroneCanConfigurationNotifier)
final droneCanConfigurationProvider = DroneCanConfigurationNotifierFamily._();

/// Reads and writes the parameters of a single DroneCAN node.
///
/// The node is scanned by index until it reports no further parameter, so the
/// table fills up progressively instead of waiting for the whole list.
final class DroneCanConfigurationNotifierProvider
    extends
        $NotifierProvider<
          DroneCanConfigurationNotifier,
          DroneCanConfigurationState
        > {
  /// Reads and writes the parameters of a single DroneCAN node.
  ///
  /// The node is scanned by index until it reports no further parameter, so the
  /// table fills up progressively instead of waiting for the whole list.
  DroneCanConfigurationNotifierProvider._({
    required DroneCanConfigurationNotifierFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'droneCanConfigurationProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$droneCanConfigurationNotifierHash();

  @override
  String toString() {
    return r'droneCanConfigurationProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  DroneCanConfigurationNotifier create() => DroneCanConfigurationNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DroneCanConfigurationState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DroneCanConfigurationState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DroneCanConfigurationNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$droneCanConfigurationNotifierHash() =>
    r'd6bb3ac96e625768de28c1a16492dc7e45041447';

/// Reads and writes the parameters of a single DroneCAN node.
///
/// The node is scanned by index until it reports no further parameter, so the
/// table fills up progressively instead of waiting for the whole list.

final class DroneCanConfigurationNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          DroneCanConfigurationNotifier,
          DroneCanConfigurationState,
          DroneCanConfigurationState,
          DroneCanConfigurationState,
          int
        > {
  DroneCanConfigurationNotifierFamily._()
    : super(
        retry: null,
        name: r'droneCanConfigurationProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Reads and writes the parameters of a single DroneCAN node.
  ///
  /// The node is scanned by index until it reports no further parameter, so the
  /// table fills up progressively instead of waiting for the whole list.

  DroneCanConfigurationNotifierProvider call(int nodeId) =>
      DroneCanConfigurationNotifierProvider._(argument: nodeId, from: this);

  @override
  String toString() => r'droneCanConfigurationProvider';
}

/// Reads and writes the parameters of a single DroneCAN node.
///
/// The node is scanned by index until it reports no further parameter, so the
/// table fills up progressively instead of waiting for the whole list.

abstract class _$DroneCanConfigurationNotifier
    extends $Notifier<DroneCanConfigurationState> {
  late final _$args = ref.$arg as int;
  int get nodeId => _$args;

  DroneCanConfigurationState build(int nodeId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<DroneCanConfigurationState, DroneCanConfigurationState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                DroneCanConfigurationState,
                DroneCanConfigurationState
              >,
              DroneCanConfigurationState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
