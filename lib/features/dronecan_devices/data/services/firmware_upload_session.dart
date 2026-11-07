import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:stork/core/services/dronecan_node_transport.dart';

import '../../domain/models/firmware_update_failure.dart';
import '../../domain/models/firmware_update_progress.dart';

/// Serves one firmware image to a DroneCAN node that pulls it with
/// `uavcan.protocol.file.Read`.
///
/// The node drives the transfer: it requests chunks at increasing offsets, so
/// the session answers every request until the image is served and then keeps
/// answering for a short grace period in case the last chunk is requested
/// again. A response shorter than the chunk size marks the end of the image,
/// which makes the node verify and boot the new firmware.
class FirmwareUploadSession {
  FirmwareUploadSession({
    required this.transport,
    required this.nodeId,
    required this.fileName,
    required this.firmware,
    this.firstRequestTimeout = const Duration(seconds: 20),
    this.stallTimeout = const Duration(seconds: 10),
    this.gracePeriod = const Duration(seconds: 3),
    this.eofProbeTimeout = const Duration(seconds: 15),
    this.onImageServed,
    this.onFinished,
  }) {
    if (firmware.isEmpty) {
      throw ArgumentError.value(
        firmware,
        'firmware',
        'The firmware image is empty',
      );
    }
  }

  final DroneCanNodeTransport transport;
  final int nodeId;
  final String fileName;
  final Uint8List firmware;

  /// How long the node may take to ask for the first chunk.
  final Duration firstRequestTimeout;

  /// How long the node may stay silent while image data is still missing.
  final Duration stallTimeout;

  /// How long the image is still served after the last (short) chunk was
  /// handed over, so a retry is not answered with "file not found".
  final Duration gracePeriod;

  /// How long the image is served while the node is expected to probe for the
  /// end of the file.
  ///
  /// When the image size is an exact multiple of the chunk size the last chunk
  /// is full-sized, which means "there is more data". The node then has to ask
  /// for the next offset to receive the empty chunk that ends the file, and it
  /// may do so after writing the last chunk to flash.
  final Duration eofProbeTimeout;

  /// Called once the whole image has been served.
  final VoidCallback? onImageServed;

  /// Called once the session stopped serving, for any reason.
  final VoidCallback? onFinished;

  final StreamController<FirmwareUpdateProgress> _controller =
      StreamController<FirmwareUpdateProgress>();

  Timer? _timer;
  int _servedBytes = 0;
  bool _completed = false;
  bool _finished = false;

  /// Starts the upload and returns the progress stream.
  Stream<FirmwareUpdateProgress> start() {
    _controller.onCancel = cancel;
    transport.fileReadHandler = _handleRead;
    _emit(FirmwareUpdatePhase.preparing);
    _startTimer(firstRequestTimeout);
    unawaited(_requestBegin());
    return _controller.stream;
  }

  /// Stops serving the image, e.g. when the user leaves the dialog.
  void cancel() {
    _finish();
  }

  Future<void> _requestBegin() async {
    try {
      final response = await transport.beginFirmwareUpdate(nodeId, fileName);
      if (!response.isOk) {
        _fail(
          FirmwareUpdateRejected(
            code: response.error,
            nodeMessage: response.optionalErrorMessage,
          ),
        );
      }
    } catch (e) {
      debugPrint('DroneCAN firmware update of node $nodeId failed: $e');
      _fail(e);
    }
  }

  List<int>? _handleRead(
    int sourceNodeId,
    String path,
    int offset,
    int maxLength,
  ) {
    // Requests may still arrive while the session is shutting down.
    if (_finished || sourceNodeId != nodeId || path != fileName) return null;

    if (offset >= firmware.length) {
      // The node asked past the end of the image: an empty chunk is the
      // protocol's end-of-file marker.
      if (_completed) {
        // The probe arrived, so the image is no longer needed in a moment.
        _timer?.cancel();
        _timer = Timer(gracePeriod, _finish);
      }
      return const <int>[];
    }

    final end = math.min(offset + maxLength, firmware.length);
    final chunk = List<int>.of(firmware.sublist(offset, end));

    if (_completed) return chunk;

    if (end > _servedBytes) {
      _servedBytes = end;
      _emit(FirmwareUpdatePhase.uploading);
    }

    if (_servedBytes >= firmware.length) {
      // A full-sized final chunk does not tell the node that the image ended,
      // so it still has to probe for the end of the file.
      _complete(awaitingEofProbe: chunk.length == maxLength);
    } else {
      // The node is still reading, so it is not stuck.
      _startTimer(stallTimeout);
    }
    return chunk;
  }

  void _complete({required bool awaitingEofProbe}) {
    _completed = true;
    _emit(FirmwareUpdatePhase.completed);
    onImageServed?.call();
    _timer?.cancel();
    _timer = Timer(awaitingEofProbe ? eofProbeTimeout : gracePeriod, _finish);
  }

  void _fail(Object error) {
    if (_finished) return;
    if (!_controller.isClosed) {
      _controller.add(
        FirmwareUpdateProgress(
          phase: FirmwareUpdatePhase.failed,
          bytesServed: _servedBytes,
          totalBytes: firmware.length,
          error: error,
        ),
      );
    }
    _finish();
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    _timer?.cancel();
    _timer = null;
    transport.fileReadHandler = null;
    if (!_controller.isClosed) {
      unawaited(_controller.close());
    }
    onFinished?.call();
  }

  void _startTimer(Duration duration) {
    _timer?.cancel();
    _timer = Timer(duration, () {
      _fail(
        FirmwareUpdateTimeout(
          _servedBytes == 0
              ? 'The node did not request the firmware image.'
              : 'The node stopped requesting firmware data.',
        ),
      );
    });
  }

  void _emit(FirmwareUpdatePhase phase) {
    if (_controller.isClosed) return;
    _controller.add(
      FirmwareUpdateProgress(
        phase: phase,
        bytesServed: _servedBytes,
        totalBytes: firmware.length,
      ),
    );
  }
}
