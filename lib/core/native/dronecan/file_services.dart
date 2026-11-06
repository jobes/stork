import 'dart:typed_data';

import 'bit_reader.dart';
import 'bit_writer.dart';
import 'dronecan_message.dart';
import 'tail_array.dart';

/// Maximum length of a file system path (`uint8[<=200]`).
const int filePathMaxLength = 200;

/// Maximum amount of data returned by one `uavcan.protocol.file.Read`.
const int fileReadChunkSize = 256;

/// `uavcan.protocol.file.BeginFirmwareUpdate` request (data type ID 40).
///
/// The node that receives the request pulls the firmware image from
/// [sourceNodeId] with `uavcan.protocol.file.Read` and then reboots into it.
class BeginFirmwareUpdateRequest implements DroneCanRequestResponseMessage {
  static const int messageId = 40;
  static const int messageSignature = 0xB7D725DF72724126;
  static const bool messageIsService = true;

  const BeginFirmwareUpdateRequest({
    this.sourceNodeId = 0,
    required this.imageFileRemotePath,
  });

  /// Node that serves the image; `0` means "the sender of the request".
  final int sourceNodeId;

  /// Path the node will ask for through `file.Read`; it is an opaque name and
  /// does not have to exist on any file system.
  final String imageFileRemotePath;

  @override
  int get id => messageId;

  @override
  int get signature => messageSignature;

  @override
  bool get isService => messageIsService;

  @override
  Uint8List toPayload() {
    final writer = BitWriter(Uint8List(8 + filePathMaxLength));
    writer.writeUint(sourceNodeId & 0xFF, 8);
    writeTailString(
      writer,
      imageFileRemotePath,
      maxLength: filePathMaxLength,
      fieldName: 'firmware file name',
    );
    return writer.toPayload();
  }
}

/// `uavcan.protocol.file.BeginFirmwareUpdate` response.
class BeginFirmwareUpdateResponse implements DroneCanMessage {
  static const int messageId = BeginFirmwareUpdateRequest.messageId;
  static const int messageSignature =
      BeginFirmwareUpdateRequest.messageSignature;
  static const bool messageIsService = true;

  /// The node accepted the request and starts fetching the image.
  static const int errorOk = 0;

  /// The node cannot update in its current mode.
  static const int errorInvalidMode = 1;

  /// Another update is already in progress.
  static const int errorInProgress = 2;

  static const int errorUnknown = 255;

  const BeginFirmwareUpdateResponse({
    required this.error,
    this.optionalErrorMessage = '',
  });

  final int error;

  final String optionalErrorMessage;

  bool get isOk => error == errorOk;

  @override
  int get id => messageId;

  @override
  int get signature => messageSignature;

  @override
  bool get isService => messageIsService;

  factory BeginFirmwareUpdateResponse.fromPayload(Uint8List payload) {
    if (payload.isEmpty) {
      throw FormatException(
        'Payload too short for BeginFirmwareUpdateResponse',
      );
    }
    return BeginFirmwareUpdateResponse(
      error: payload[0],
      optionalErrorMessage: decodeTailString(payload, 8, maxLength: 127),
    );
  }
}

/// `uavcan.protocol.file.Read` request (data type ID 48).
///
/// The node under update sends these requests to fetch its firmware image.
class FileReadRequest implements DroneCanMessage {
  static const int messageId = 48;
  static const int messageSignature = 0x8DCDCA939F33F678;
  static const bool messageIsService = true;

  const FileReadRequest({required this.offset, required this.path});

  /// Byte offset within the file (`uint40`).
  final int offset;

  final String path;

  @override
  int get id => messageId;

  @override
  int get signature => messageSignature;

  @override
  bool get isService => messageIsService;

  factory FileReadRequest.fromPayload(Uint8List payload) {
    if (payload.length < 5) {
      throw FormatException(
        'Payload too short for FileReadRequest: ${payload.length} bytes',
      );
    }
    final reader = BitReader(payload);
    final offset = reader.readUint(40);
    return FileReadRequest(
      offset: offset,
      path: decodeTailString(
        payload,
        reader.bitOffset,
        maxLength: filePathMaxLength,
      ),
    );
  }

  /// Encoded form, used by tests and by nodes that read a file from a peer.
  Uint8List toPayload() {
    final writer = BitWriter(Uint8List(5 + filePathMaxLength));
    writer.writeUint(offset & 0xFFFFFFFFFF, 40);
    writeTailString(
      writer,
      path,
      maxLength: filePathMaxLength,
      fieldName: 'file path',
    );
    return writer.toPayload();
  }
}

/// `uavcan.protocol.file.Read` response, sent by this app for its image.
///
/// A response shorter than [fileReadChunkSize] marks the end of the file.
class FileReadResponse implements DroneCanRequestResponseMessage {
  static const int messageId = FileReadRequest.messageId;
  static const int messageSignature = FileReadRequest.messageSignature;
  static const bool messageIsService = true;

  static const int errorOk = 0;
  static const int errorNotFound = 2;
  static const int errorIoError = 5;

  const FileReadResponse({this.error = errorOk, this.data = const []});

  final int error;

  /// At most [fileReadChunkSize] bytes.
  final List<int> data;

  @override
  int get id => messageId;

  @override
  int get signature => messageSignature;

  @override
  bool get isService => messageIsService;

  @override
  Uint8List toPayload() {
    if (data.length > fileReadChunkSize) {
      throw ArgumentError(
        'A file read response can carry at most $fileReadChunkSize bytes, '
        'but got ${data.length}',
      );
    }

    // `data` is the last field, so it is written without its length prefix and
    // the payload is not padded — the sender would read the padding as data.
    final writer = BitWriter(Uint8List(2 + fileReadChunkSize));
    writer.writeInt(error, 16);
    for (final byte in data) {
      writer.writeUint(byte & 0xFF, 8);
    }
    return writer.toPayload();
  }

  /// Decoded form, used by tests and by a node reading a file from a peer.
  factory FileReadResponse.fromPayload(Uint8List payload) {
    if (payload.length < 2) {
      throw FormatException(
        'Payload too short for FileReadResponse: ${payload.length} bytes',
      );
    }
    final reader = BitReader(payload);
    final error = reader.readInt(16);
    final remainingBits = payload.length * 8 - reader.bitOffset;
    final length = remainingBits ~/ 8;
    if (length > fileReadChunkSize) {
      throw FormatException(
        'File read response carries too much data: $length bytes',
      );
    }
    final data = List<int>.generate(
      length,
      (_) => reader.readUint(8),
      growable: false,
    );
    return FileReadResponse(error: error, data: data);
  }
}
