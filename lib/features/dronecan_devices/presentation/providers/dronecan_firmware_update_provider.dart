import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/services/firmware_file_picker.dart';
import '../../domain/models/firmware_update_failure.dart';
import '../../domain/models/firmware_update_progress.dart';
import 'dronecan_nodes_provider.dart';

part 'dronecan_firmware_update_provider.freezed.dart';
part 'dronecan_firmware_update_provider.g.dart';

/// Lets the user choose a firmware image from the local file system.
@riverpod
FirmwareFilePicker firmwareFilePicker(Ref ref) {
  return const FileSelectorFirmwareFilePicker();
}

/// State of the firmware update dialog of one node.
@freezed
abstract class DroneCanFirmwareUpdateState with _$DroneCanFirmwareUpdateState {
  const DroneCanFirmwareUpdateState._();

  const factory DroneCanFirmwareUpdateState({
    /// Image selected by the user, or `null` before a file was chosen.
    PickedFirmwareFile? file,
    @Default(FirmwareUpdateProgress.idle) FirmwareUpdateProgress progress,

    /// `true` while the platform file dialog is open.
    @Default(false) bool isPicking,

    /// `true` once the upload stream closed after serving the whole image.
    ///
    /// The stream stays open after [FirmwareUpdatePhase.completed] because the
    /// node may still retry its last reads (or probe for the end of the file),
    /// so the dialog must not close before this flag is set.
    @Default(false) bool uploadFinished,

    /// Failure of the file dialog or of reading the image.
    Object? pickError,
  }) = _DroneCanFirmwareUpdateState;

  bool get isRunning => progress.isRunning;

  bool get isCompleted => progress.isCompleted;

  bool get isFailed => progress.isFailed;

  /// `true` while the image is still being served, including the grace period
  /// that follows [FirmwareUpdatePhase.completed].
  bool get isBusy => isRunning || (isCompleted && !uploadFinished);

  bool get canStart => file != null && !isBusy && !isPicking;
}

/// Drives the firmware update of a single DroneCAN node.
@riverpod
class DroneCanFirmwareUpdateNotifier extends _$DroneCanFirmwareUpdateNotifier {
  StreamSubscription<FirmwareUpdateProgress>? _subscription;
  Completer<void>? _completer;
  bool _uploading = false;

  /// Identifies the current upload so callbacks of a cancelled one cannot
  /// overwrite the state of a newer upload.
  int _uploadGeneration = 0;

  @override
  DroneCanFirmwareUpdateState build(int nodeId) {
    ref.onDispose(() {
      final completer = _completer;
      _completer = null;
      // Cancelling stops the upload session from serving the image.
      unawaited(_subscription?.cancel());
      _subscription = null;
      if (completer != null && !completer.isCompleted) completer.complete();
    });
    return const DroneCanFirmwareUpdateState();
  }

  /// Opens the file dialog and remembers the chosen image.
  Future<void> selectFirmware() async {
    if (state.isBusy || state.isPicking) return;

    state = state.copyWith(isPicking: true, pickError: null);
    try {
      final picked = await ref.read(firmwareFilePickerProvider).pick();
      if (!ref.mounted) return;
      // Cancelling the file dialog keeps the image that was selected before.
      if (picked != null) {
        state = state.copyWith(isPicking: false, file: picked);
      } else {
        state = state.copyWith(isPicking: false);
      }
    } catch (e) {
      debugPrint('DroneCAN firmware selection failed: $e');
      if (!ref.mounted) return;
      state = state.copyWith(isPicking: false, pickError: e);
    }
  }

  /// Forgets the selected image.
  void clearFirmware() {
    if (state.isBusy) return;
    state = const DroneCanFirmwareUpdateState();
  }

  /// Uploads the selected image to the node.
  ///
  /// Completes when the transfer ended, either way.
  Future<void> upload() async {
    final file = state.file;
    if (file == null || _uploading || state.isBusy) return;

    if (file.size == 0) {
      state = state.copyWith(
        progress: _failed(
          const FirmwareUpdateInvalidImage('The image is empty'),
          totalBytes: 0,
        ),
      );
      return;
    }

    _uploading = true;
    final generation = ++_uploadGeneration;
    state = state.copyWith(
      progress: FirmwareUpdateProgress(
        phase: FirmwareUpdatePhase.preparing,
        totalBytes: file.size,
      ),
      uploadFinished: false,
      pickError: null,
    );

    final completer = Completer<void>();
    _completer = completer;
    try {
      final stream = ref
          .read(droneCanNodeRepositoryProvider)
          .updateFirmware(nodeId, file.name, file.bytes);

      await _subscription?.cancel();
      _subscription = stream.listen(
        (progress) {
          if (!ref.mounted || generation != _uploadGeneration) return;
          state = state.copyWith(progress: progress);
        },
        onError: (Object error) {
          debugPrint('DroneCAN firmware update of node $nodeId failed: $error');
          if (ref.mounted && generation == _uploadGeneration) {
            state = state.copyWith(
              progress: _failed(error, totalBytes: file.size),
            );
          }
          if (!completer.isCompleted) completer.complete();
        },
        onDone: () {
          // The session only closes once it stopped answering the node, so the
          // dialog may close now as well.
          if (ref.mounted &&
              generation == _uploadGeneration &&
              state.isCompleted) {
            state = state.copyWith(uploadFinished: true);
          }
          if (!completer.isCompleted) completer.complete();
        },
      );
      await completer.future;
    } catch (e) {
      debugPrint('DroneCAN firmware update of node $nodeId failed: $e');
      if (ref.mounted && generation == _uploadGeneration) {
        state = state.copyWith(progress: _failed(e, totalBytes: file.size));
      }
    } finally {
      // A cancelled upload must not clear the bookkeeping of a newer one.
      if (generation == _uploadGeneration) {
        _uploading = false;
        _subscription = null;
        _completer = null;
      }
    }
  }

  /// Aborts a running upload.
  void cancel() {
    _uploadGeneration++;
    final subscription = _subscription;
    final completer = _completer;
    _subscription = null;
    _completer = null;
    _uploading = false;
    // Cancelling the subscription makes the upload session stop serving.
    unawaited(subscription?.cancel());
    if (completer != null && !completer.isCompleted) completer.complete();
    if (!ref.mounted) return;
    state = state.copyWith(
      progress: FirmwareUpdateProgress.idle,
      uploadFinished: false,
    );
  }

  FirmwareUpdateProgress _failed(Object error, {required int totalBytes}) {
    return FirmwareUpdateProgress(
      phase: FirmwareUpdatePhase.failed,
      totalBytes: totalBytes,
      error: error,
    );
  }
}
