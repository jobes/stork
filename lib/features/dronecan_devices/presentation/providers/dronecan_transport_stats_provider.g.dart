// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dronecan_transport_stats_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Re-reads `uavcan.protocol.GetTransportStats` once per second while the
/// statistics dialog is open, turning the counters into a rate meter.

@ProviderFor(DroneCanTransportStatsNotifier)
final droneCanTransportStatsProvider = DroneCanTransportStatsNotifierFamily._();

/// Re-reads `uavcan.protocol.GetTransportStats` once per second while the
/// statistics dialog is open, turning the counters into a rate meter.
final class DroneCanTransportStatsNotifierProvider
    extends
        $NotifierProvider<
          DroneCanTransportStatsNotifier,
          DroneCanTransportStatsState
        > {
  /// Re-reads `uavcan.protocol.GetTransportStats` once per second while the
  /// statistics dialog is open, turning the counters into a rate meter.
  DroneCanTransportStatsNotifierProvider._({
    required DroneCanTransportStatsNotifierFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'droneCanTransportStatsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$droneCanTransportStatsNotifierHash();

  @override
  String toString() {
    return r'droneCanTransportStatsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  DroneCanTransportStatsNotifier create() => DroneCanTransportStatsNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DroneCanTransportStatsState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DroneCanTransportStatsState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DroneCanTransportStatsNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$droneCanTransportStatsNotifierHash() =>
    r'734cde68d51f0a96d6e1faef05aa887a4cb24873';

/// Re-reads `uavcan.protocol.GetTransportStats` once per second while the
/// statistics dialog is open, turning the counters into a rate meter.

final class DroneCanTransportStatsNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          DroneCanTransportStatsNotifier,
          DroneCanTransportStatsState,
          DroneCanTransportStatsState,
          DroneCanTransportStatsState,
          int
        > {
  DroneCanTransportStatsNotifierFamily._()
    : super(
        retry: null,
        name: r'droneCanTransportStatsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Re-reads `uavcan.protocol.GetTransportStats` once per second while the
  /// statistics dialog is open, turning the counters into a rate meter.

  DroneCanTransportStatsNotifierProvider call(int nodeId) =>
      DroneCanTransportStatsNotifierProvider._(argument: nodeId, from: this);

  @override
  String toString() => r'droneCanTransportStatsProvider';
}

/// Re-reads `uavcan.protocol.GetTransportStats` once per second while the
/// statistics dialog is open, turning the counters into a rate meter.

abstract class _$DroneCanTransportStatsNotifier
    extends $Notifier<DroneCanTransportStatsState> {
  late final _$args = ref.$arg as int;
  int get nodeId => _$args;

  DroneCanTransportStatsState build(int nodeId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<DroneCanTransportStatsState, DroneCanTransportStatsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                DroneCanTransportStatsState,
                DroneCanTransportStatsState
              >,
              DroneCanTransportStatsState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
