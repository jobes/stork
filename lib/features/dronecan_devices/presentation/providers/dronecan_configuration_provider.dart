import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/models/dronecan_parameter.dart';
import '../../domain/models/dronecan_result.dart';
import 'dronecan_nodes_provider.dart';

part 'dronecan_configuration_provider.freezed.dart';
part 'dronecan_configuration_provider.g.dart';

/// Progress of reading the parameter list of a node.
enum DroneCanConfigurationStatus { idle, loading, ready, failed }

/// State of the configuration dialog of one node.
@freezed
abstract class DroneCanConfigurationState with _$DroneCanConfigurationState {
  const DroneCanConfigurationState._();

  const factory DroneCanConfigurationState({
    @Default(DroneCanConfigurationStatus.idle)
    DroneCanConfigurationStatus status,

    /// Parameters read so far; grows while the node is scanned.
    @Default(<DroneCanParameter>[]) List<DroneCanParameter> parameters,

    /// `true` while a set, store or erase request is in flight.
    @Default(false) bool busy,

    /// Last failure, either of the scan or of an individual request.
    Object? error,
  }) = _DroneCanConfigurationState;

  bool get isLoading => status == DroneCanConfigurationStatus.loading;

  bool get hasFailed => status == DroneCanConfigurationStatus.failed;
}

/// Reads and writes the parameters of a single DroneCAN node.
///
/// The node is scanned by index until it reports no further parameter, so the
/// table fills up progressively instead of waiting for the whole list.
@riverpod
class DroneCanConfigurationNotifier extends _$DroneCanConfigurationNotifier {
  @override
  DroneCanConfigurationState build(int nodeId) {
    return const DroneCanConfigurationState();
  }

  /// `true` while a request or a scan is in flight.
  bool get _isBusy => state.busy || state.isLoading;

  /// Re-reads the whole parameter list.
  Future<void> refresh() async {
    if (_isBusy) return;

    final repository = ref.read(droneCanNodeRepositoryProvider);
    state = const DroneCanConfigurationState(
      status: DroneCanConfigurationStatus.loading,
    );

    var received = 0;
    try {
      await for (final parameters in repository.watchParameters(nodeId)) {
        if (!ref.mounted) return;
        received = parameters.length;
        state = state.copyWith(parameters: parameters);
      }
      if (!ref.mounted) return;
      state = state.copyWith(status: DroneCanConfigurationStatus.ready);
    } catch (e) {
      debugPrint('DroneCAN parameter scan of node $nodeId failed: $e');
      if (!ref.mounted) return;
      state = state.copyWith(
        // A partial list stays usable even when the scan stopped early.
        status: received == 0
            ? DroneCanConfigurationStatus.failed
            : DroneCanConfigurationStatus.ready,
        error: e,
      );
    }
  }

  /// Sends [value] to the node and updates the table with the value the node
  /// reports back.
  Future<DroneCanResult<void>> setParameterValue(
    DroneCanParameter parameter,
    DroneCanParamValue value,
  ) async {
    if (_isBusy) {
      return const DroneCanFailure(DroneCanOperationFailure.busy);
    }

    state = state.copyWith(busy: true, error: null);
    try {
      final updated = await ref
          .read(droneCanNodeRepositoryProvider)
          .setParameterValue(nodeId, parameter, value);
      if (!ref.mounted) return const DroneCanSuccess(null);
      _replace(updated);
      return const DroneCanSuccess(null);
    } catch (e) {
      debugPrint('DroneCAN parameter set on node $nodeId failed: $e');
      if (ref.mounted) state = state.copyWith(error: e);
      return DroneCanFailure(e);
    } finally {
      if (ref.mounted) state = state.copyWith(busy: false);
    }
  }

  /// Saves the configuration to the non-volatile storage of the node.
  Future<DroneCanResult<void>> storeAll() async {
    if (_isBusy) {
      return const DroneCanFailure(DroneCanOperationFailure.busy);
    }

    state = state.copyWith(busy: true, error: null);
    try {
      final ok = await ref
          .read(droneCanNodeRepositoryProvider)
          .storeParameters(nodeId);
      if (!ok) {
        return const DroneCanFailure(
          DroneCanOperationFailure.parametersNotStored,
        );
      }
      return const DroneCanSuccess(null);
    } catch (e) {
      debugPrint('DroneCAN store of node $nodeId failed: $e');
      if (ref.mounted) state = state.copyWith(error: e);
      return DroneCanFailure(e);
    } finally {
      if (ref.mounted) state = state.copyWith(busy: false);
    }
  }

  /// Erases the configuration of the node and re-reads the parameter list.
  Future<DroneCanResult<void>> eraseAll() async {
    if (_isBusy) {
      return const DroneCanFailure(DroneCanOperationFailure.busy);
    }

    state = state.copyWith(busy: true, error: null);
    try {
      final ok = await ref
          .read(droneCanNodeRepositoryProvider)
          .eraseParameters(nodeId);
      if (!ok) {
        return const DroneCanFailure(
          DroneCanOperationFailure.parametersNotErased,
        );
      }
      if (!ref.mounted) return const DroneCanSuccess(null);

      // The node falls back to its defaults, so the table must be re-read.
      state = state.copyWith(busy: false);
      await refresh();
      return const DroneCanSuccess(null);
    } catch (e) {
      debugPrint('DroneCAN erase of node $nodeId failed: $e');
      if (ref.mounted) state = state.copyWith(error: e);
      return DroneCanFailure(e);
    } finally {
      if (ref.mounted && state.busy) state = state.copyWith(busy: false);
    }
  }

  void _replace(DroneCanParameter updated) {
    final index = state.parameters.indexWhere(
      (parameter) => parameter.name == updated.name,
    );
    if (index < 0) return;

    final parameters = List<DroneCanParameter>.of(state.parameters);
    parameters[index] = updated;
    state = state.copyWith(parameters: UnmodifiableListView(parameters));
  }
}
