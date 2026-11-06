import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/models/dronecan_result.dart';
import '../../domain/models/transport_statistics.dart';
import 'dronecan_node_actions_provider.dart';

part 'dronecan_transport_stats_provider.g.dart';

/// Latest transport statistics sample of a node together with the sample
/// before it, so the UI can show the change since the previous reading.
class DroneCanTransportStatsState {
  const DroneCanTransportStatsState({this.current, this.previous, this.error});

  /// Most recent sample, or `null` until the first answer arrives.
  final TransportStatistics? current;

  /// Sample before [current]; `null` until two samples were read.
  final TransportStatistics? previous;

  /// Last polling failure; [current] stays visible while the node is silent.
  final Object? error;

  bool get hasError => error != null;
}

/// Re-reads `uavcan.protocol.GetTransportStats` once per second while the
/// statistics dialog is open, turning the counters into a rate meter.
@riverpod
class DroneCanTransportStatsNotifier extends _$DroneCanTransportStatsNotifier {
  static const Duration _refreshInterval = Duration(seconds: 1);

  Timer? _timer;
  bool _inFlight = false;

  @override
  DroneCanTransportStatsState build(int nodeId) {
    _timer?.cancel();
    _timer = Timer.periodic(_refreshInterval, (_) => unawaited(refresh()));
    ref.onDispose(() {
      _timer?.cancel();
      _timer = null;
    });
    unawaited(refresh());
    return const DroneCanTransportStatsState();
  }

  /// Reads a new sample; a failure keeps the previous values visible.
  Future<void> refresh() async {
    if (_inFlight) return;
    _inFlight = true;
    try {
      final result = await ref
          .read(droneCanNodeActionsProvider(nodeId).notifier)
          .transportStatistics();
      if (!ref.mounted) return;
      state = switch (result) {
        DroneCanSuccess(:final value) => DroneCanTransportStatsState(
          current: value,
          previous: state.current,
        ),
        DroneCanFailure(:final error) => DroneCanTransportStatsState(
          current: state.current,
          previous: state.previous,
          error: error,
        ),
      };
    } finally {
      _inFlight = false;
    }
  }
}
