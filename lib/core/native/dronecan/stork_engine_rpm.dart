import 'dart:typed_data';
import 'bit_reader.dart';
import 'dronecan_message.dart';

/// Parsed representation of stork.equipment.ice.EngineRPM (ID 20120).
///
/// DSDL bit layout (little-endian, LSB first per UAVCAN v0 encoding):
///   uint2 state
///   uint6 ecu_index
///   uint7 engine_load_percent
///   uint17 engine_speed_rpm
///   uint7 throttle_position_percent
class StorkEngineRpm implements DroneCanMessage {
  static const int messageId = 20120;
  static const int messageSignature = 0xD8CD8D1076CA4884;
  static const bool messageIsService = false;

  @override
  int get id => messageId;

  @override
  int get signature => messageSignature;

  @override
  bool get isService => messageIsService;

  final int state;
  final int ecuIndex;
  final int engineLoadPercent;
  final int engineSpeedRpm;
  final int throttlePositionPercent;

  const StorkEngineRpm({
    required this.state,
    required this.ecuIndex,
    required this.engineLoadPercent,
    required this.engineSpeedRpm,
    required this.throttlePositionPercent,
  });

  factory StorkEngineRpm.fromPayload(Uint8List payload) {
    // Total bits = 2 + 6 + 7 + 17 + 7 = 39 bits -> at least 5 bytes
    if (payload.length < 5) {
      throw FormatException(
        'Payload too short for StorkEngineRpm message (got ${payload.length} bytes, expected at least 5)',
      );
    }

    final reader = BitReader(payload);

    final state = reader.readUint(2);
    final ecuIndex = reader.readUint(6);
    final engineLoadPercent = reader.readUint(7);
    final engineSpeedRpm = reader.readUint(17);
    final throttlePositionPercent = reader.readUint(7);

    return StorkEngineRpm(
      state: state,
      ecuIndex: ecuIndex,
      engineLoadPercent: engineLoadPercent,
      engineSpeedRpm: engineSpeedRpm,
      throttlePositionPercent: throttlePositionPercent,
    );
  }

  @override
  String toString() {
    return 'StorkEngineRpm(state: $state, ecuIndex: $ecuIndex, load: $engineLoadPercent%, rpm: $engineSpeedRpm, throttle: $throttlePositionPercent%)';
  }
}
