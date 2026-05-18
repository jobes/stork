import 'dart:typed_data';
import 'dronecan_message.dart';

class StaticPressure implements DroneCanMessage {
  static const int messageId = 1028;
  static const int messageSignature = 0x44DC4133A6B487BA;
  static const bool messageIsService = false;

  @override
  int get id => messageId;

  @override
  int get signature => messageSignature;

  @override
  bool get isService => messageIsService;

  final double staticPressure;

  StaticPressure({required this.staticPressure});

  factory StaticPressure.fromPayload(Uint8List payload) {
    if (payload.length < 4) {
      throw FormatException('Payload too short for StaticPressure');
    }

    final byteData = ByteData.sublistView(payload);
    final pressure = byteData.getFloat32(0, Endian.little);

    return StaticPressure(staticPressure: pressure);
  }

  @override
  String toString() {
    return 'StaticPressure(${staticPressure.toStringAsFixed(2)} Pa)';
  }
}
