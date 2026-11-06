import 'package:freezed_annotation/freezed_annotation.dart';

part 'firmware_update_progress.freezed.dart';

/// Progress of a `uavcan.protocol.file.BeginFirmwareUpdate` upload.
///
/// The node pulls the image with `uavcan.protocol.file.Read`, so the transfer
/// is driven by the node and the progress reflects how much of the file has
/// already been served to it.
@freezed
abstract class FirmwareUpdateProgress with _$FirmwareUpdateProgress {
  const FirmwareUpdateProgress._();

  const factory FirmwareUpdateProgress({
    required FirmwareUpdatePhase phase,
    @Default(0) int bytesServed,
    @Default(0) int totalBytes,
    Object? error,
  }) = _FirmwareUpdateProgress;

  /// No upload is in progress.
  static const FirmwareUpdateProgress idle = FirmwareUpdateProgress(
    phase: FirmwareUpdatePhase.idle,
  );

  /// Completion ratio in the range 0..1.
  double get fraction {
    if (totalBytes <= 0) return 0;
    return (bytesServed / totalBytes).clamp(0.0, 1.0);
  }

  bool get isRunning =>
      phase == FirmwareUpdatePhase.preparing ||
      phase == FirmwareUpdatePhase.uploading;

  bool get isCompleted => phase == FirmwareUpdatePhase.completed;

  bool get isFailed => phase == FirmwareUpdatePhase.failed;
}

/// Phase of a firmware upload.
enum FirmwareUpdatePhase {
  /// No upload is in progress.
  idle,

  /// `BeginFirmwareUpdate` was sent; the node has not requested data yet.
  preparing,

  /// The node is reading the image from this app.
  uploading,

  /// The whole image was served; the node verifies it and reboots.
  completed,

  /// The upload was aborted.
  failed,
}
