/// Why a firmware update was aborted.
sealed class FirmwareUpdateFailure implements Exception {
  const FirmwareUpdateFailure();
}

/// The node refused the update in `uavcan.protocol.file.BeginFirmwareUpdate`.
final class FirmwareUpdateRejected extends FirmwareUpdateFailure {
  const FirmwareUpdateRejected({required this.code, this.nodeMessage = ''});

  /// Error code reported by the node (0 is success and never reaches here).
  final int code;

  /// Free text the node supplied, may be empty.
  final String nodeMessage;

  @override
  String toString() =>
      'FirmwareUpdateRejected(code: $code, message: "$nodeMessage")';
}

/// The selected image cannot be used at all.
final class FirmwareUpdateInvalidImage extends FirmwareUpdateFailure {
  const FirmwareUpdateInvalidImage(this.reason);

  final String reason;

  @override
  String toString() => 'FirmwareUpdateInvalidImage($reason)';
}

/// The node stopped requesting image data before the image was complete.
final class FirmwareUpdateTimeout extends FirmwareUpdateFailure {
  const FirmwareUpdateTimeout(this.reason);

  final String reason;

  @override
  String toString() => 'FirmwareUpdateTimeout($reason)';
}
