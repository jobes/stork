import 'dart:typed_data';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:stork/core/utils/time_utils.dart';
import 'node_status.dart';
import 'dronecan_message.dart';

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
  final Uint8List uniqueId;
  final String name;

  GetNodeInfoResponse({
    required this.status,
    required this.swMajor,
    required this.swMinor,
    required this.uniqueId,
    required this.name,
  });

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
      name: 'com.inskycore.dronecan_node.stork_map',
    );
  }

  @override
  Uint8List toPayload() {
    // 1. status: 7 bytes
    final statusBytes = status.toPayload();

    // 2. software_version: 15 bytes
    final swBytes = Uint8List(15);
    final swData = ByteData.sublistView(swBytes);
    swData.setUint8(0, swMajor);
    swData.setUint8(1, swMinor);
    swData.setUint8(2, 0); // optional_field_flags
    swData.setUint32(3, 0, Endian.little); // vcs_commit
    swData.setUint64(7, 0, Endian.little); // image_crc

    // 3. hardware_version: 19 bytes
    final hwBytes = Uint8List(19);
    final hwData = ByteData.sublistView(hwBytes);
    hwData.setUint8(0, 0); // major
    hwData.setUint8(1, 0); // minor
    hwBytes.setRange(2, 18, uniqueId); // unique_id
    hwBytes[18] = 0; // certificate_of_authenticity length = 0

    // 4. name: variable length
    int nameLen = name.length;
    if (nameLen > 63) {
      nameLen = 63;
    }
    final namePackedBytes = Uint8List.fromList(
      name.substring(0, nameLen).codeUnits,
    );

    // Combine all sections into a single payload
    final totalLen =
        statusBytes.length +
        swBytes.length +
        hwBytes.length +
        1 +
        namePackedBytes.length;
    final payload = Uint8List(totalLen);

    int offset = 0;
    payload.setRange(offset, offset + statusBytes.length, statusBytes);
    offset += statusBytes.length;

    payload.setRange(offset, offset + swBytes.length, swBytes);
    offset += swBytes.length;

    payload.setRange(offset, offset + hwBytes.length, hwBytes);
    offset += hwBytes.length;
    payload[offset] = nameLen;
    offset += 1;
    payload.setRange(offset, offset + namePackedBytes.length, namePackedBytes);

    return payload;
  }
}
