import 'dart:convert';
import 'dart:typed_data';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:stork/core/utils/time_utils.dart';
import 'node_status.dart';
import 'dronecan_message.dart';
import 'tail_array.dart';

class GetNodeInfoResponse implements DroneCanRequestResponseMessage {
  static const int messageId = 1;
  static const int messageSignature = 0xEE468A8121C46A9E;
  static const bool messageIsService = true;

  @override
  int get id => messageId;

  @override
  int get signature => messageSignature;

  @override
  bool get isService => messageIsService;

  final NodeStatus status;
  final int swMajor;
  final int swMinor;
  final int optionalFieldFlags;
  final int vcsCommit;
  final BigInt imageCrc;
  final int hwMajor;
  final int hwMinor;
  final Uint8List uniqueId;
  final Uint8List name;
  final Uint8List certificateOfAuthenticity;

  GetNodeInfoResponse({
    required this.status,
    required this.swMajor,
    required this.swMinor,
    required this.uniqueId,
    required this.name,
    this.optionalFieldFlags = 0,
    this.vcsCommit = 0,
    BigInt? imageCrc,
    this.hwMajor = 0,
    this.hwMinor = 0,
    Uint8List? certificateOfAuthenticity,
  }) : imageCrc = imageCrc ?? BigInt.zero,
       certificateOfAuthenticity = certificateOfAuthenticity ?? Uint8List(0) {
    if (uniqueId.length != 16) {
      throw ArgumentError(
        'uniqueId must be exactly 16 bytes long, but was ${uniqueId.length} bytes.',
      );
    }
    if (name.length > 80) {
      throw ArgumentError(
        'name must be at most 80 bytes long (standard DroneCAN limit), but was ${name.length} bytes.',
      );
    }
    if (this.certificateOfAuthenticity.length > 255) {
      throw ArgumentError(
        'certificateOfAuthenticity must be at most 255 bytes long, '
        'but was ${this.certificateOfAuthenticity.length} bytes.',
      );
    }
  }

  /// Decodes a `uavcan.protocol.GetNodeInfo` response payload.
  ///
  /// Layout: `status` (7 B), `software_version` (15 B), `hardware_version`
  /// (19 B + optional certificate of authenticity) followed by `name`
  /// (`uint8[<=80]`).
  ///
  /// The trailing dynamic array may use the DroneCAN tail-array optimization
  /// (no length prefix), which is the default for classic CAN, or a 7-bit
  /// length prefix followed by bit-packed name bytes.
  factory GetNodeInfoResponse.fromPayload(Uint8List payload) {
    const statusLength = 7;
    const softwareVersionLength = 15;
    const hardwareVersionFixedLength = 19; // without certificate bytes
    const fixedHeaderLength =
        statusLength + softwareVersionLength + hardwareVersionFixedLength;
    const maxNameLength = 80;
    const maxCertificateLength = 255;

    if (payload.length < fixedHeaderLength) {
      throw FormatException(
        'Payload too short for GetNodeInfoResponse: '
        '${payload.length} < $fixedHeaderLength bytes',
      );
    }

    final data = ByteData.sublistView(payload);
    final status = NodeStatus.fromPayload(
      Uint8List.sublistView(payload, 0, statusLength),
    );

    final softwareOffset = statusLength;
    final swMajor = payload[softwareOffset];
    final swMinor = payload[softwareOffset + 1];
    final optionalFieldFlags = payload[softwareOffset + 2];
    final vcsCommit = data.getUint32(softwareOffset + 3, Endian.little);
    final imageCrc =
        (BigInt.from(data.getUint32(softwareOffset + 11, Endian.little)) <<
            32) |
        BigInt.from(data.getUint32(softwareOffset + 7, Endian.little));

    final hardwareOffset = softwareOffset + softwareVersionLength;
    final hwMajor = payload[hardwareOffset];
    final hwMinor = payload[hardwareOffset + 1];
    final uniqueId = Uint8List.fromList(
      payload.sublist(hardwareOffset + 2, hardwareOffset + 18),
    );

    final certificateLengthOffset = hardwareOffset + 18;
    final certificateLength = payload[certificateLengthOffset];
    if (certificateLength > maxCertificateLength) {
      throw FormatException(
        'GetNodeInfoResponse certificate is too long: '
        '$certificateLength > $maxCertificateLength bytes',
      );
    }
    final certificateStart = certificateLengthOffset + 1;
    if (payload.length < certificateStart + certificateLength) {
      throw FormatException(
        'Payload too short for GetNodeInfoResponse certificate: '
        '${payload.length} < ${certificateStart + certificateLength} bytes',
      );
    }
    final certificate = Uint8List.fromList(
      payload.sublist(certificateStart, certificateStart + certificateLength),
    );

    final nameOffset = certificateStart + certificateLength;
    final name = _decodeName(payload, nameOffset, maxNameLength);

    return GetNodeInfoResponse(
      status: status,
      swMajor: swMajor,
      swMinor: swMinor,
      optionalFieldFlags: optionalFieldFlags,
      vcsCommit: vcsCommit,
      imageCrc: imageCrc,
      hwMajor: hwMajor,
      hwMinor: hwMinor,
      uniqueId: uniqueId,
      name: name,
      certificateOfAuthenticity: certificate,
    );
  }

  static Uint8List _decodeName(
    Uint8List payload,
    int nameOffset,
    int maxNameLength,
  ) {
    // A TAO payload can accidentally satisfy the length-prefix check, but the
    // resulting bytes are bit-shifted garbage rather than a valid name.
    return decodeTailBytes(
      payload,
      nameOffset * 8,
      maxLength: maxNameLength,
      isPlausible: _isPlausibleName,
    );
  }

  /// DroneCAN node names are UTF-8 text; control characters or invalid UTF-8
  /// indicate a misinterpreted length prefix.
  static bool _isPlausibleName(Uint8List name) {
    for (final byte in name) {
      if (byte < 0x20 || byte == 0x7F) return false;
    }
    try {
      utf8.decode(name);
      return true;
    } on FormatException {
      return false;
    }
  }

  /// Pre-encoded default node name to avoid runtime UTF-8 encoding.
  /// Must be at most 80 characters (standard DroneCAN limit).
  static final Uint8List defaultName = Uint8List.fromList(
    utf8.encode('com.inskycore.dronecan_node.stork_map'),
  );

  /// Factory method to asynchronously construct the Response with all platform details loaded.
  static Future<GetNodeInfoResponse> create(Uint8List uniqueId) async {
    int swMajor = 0;
    int swMinor = 1;
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final parts = packageInfo.version.split('.');
      if (parts.length >= 2) {
        swMajor = int.tryParse(parts[0]) ?? 0;
        swMinor = int.tryParse(parts[1]) ?? 1;
      }
    } catch (e) {
      // Fallback to default version if reading platform fails
    }

    return GetNodeInfoResponse(
      status: NodeStatus(
        uptimeSec: appStopwatch.elapsed.inSeconds,
        health: NodeHealth.ok,
        mode: NodeMode.operational,
      ),
      swMajor: swMajor,
      swMinor: swMinor,
      uniqueId: uniqueId,
      name: defaultName,
    );
  }

  @override
  Uint8List toPayload() {
    if (uniqueId.length != 16) {
      throw ArgumentError(
        'uniqueId must be exactly 16 bytes long, but was ${uniqueId.length} bytes.',
      );
    }

    // 1. status: 7 bytes
    final statusBytes = status.toPayload();

    // 2. software_version: 15 bytes
    final swBytes = Uint8List(15);
    final swData = ByteData.sublistView(swBytes);
    swData.setUint8(0, swMajor);
    swData.setUint8(1, swMinor);
    swData.setUint8(2, optionalFieldFlags);
    swData.setUint32(3, vcsCommit, Endian.little);
    const uint32Mask = 0xFFFFFFFF;
    swData.setUint32(
      7,
      (imageCrc & BigInt.from(uint32Mask)).toInt(),
      Endian.little,
    );
    swData.setUint32(
      11,
      ((imageCrc >> 32) & BigInt.from(uint32Mask)).toInt(),
      Endian.little,
    );

    // 3. hardware_version: 19 bytes + certificate of authenticity
    final certificate = certificateOfAuthenticity;
    final hwBytes = Uint8List(19 + certificate.length);
    final hwData = ByteData.sublistView(hwBytes);
    hwData.setUint8(0, hwMajor);
    hwData.setUint8(1, hwMinor);
    hwBytes.setRange(2, 18, uniqueId); // unique_id
    hwBytes[18] = certificate.length; // certificate length prefix
    hwBytes.setRange(19, 19 + certificate.length, certificate);

    // 4. name: variable length, serialized with tail-array optimization
    // (classic CAN transfers omit the length prefix; it is inferred from the
    // transfer payload length).
    final nameLen = name.length;

    // Combine all sections into a single payload
    final totalLen =
        statusBytes.length + swBytes.length + hwBytes.length + nameLen;
    final payload = Uint8List(totalLen);

    int offset = 0;
    payload.setRange(offset, offset + statusBytes.length, statusBytes);
    offset += statusBytes.length;

    payload.setRange(offset, offset + swBytes.length, swBytes);
    offset += swBytes.length;

    payload.setRange(offset, offset + hwBytes.length, hwBytes);
    offset += hwBytes.length;
    payload.setRange(offset, offset + nameLen, name);

    return payload;
  }
}
