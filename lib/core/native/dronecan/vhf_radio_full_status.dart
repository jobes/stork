import 'dart:typed_data';
import 'bit_reader.dart';
import 'dronecan_message.dart';

/// Parsed representation of stork.equipment.vhf_radio.FullStatus (ID 20123).
///
/// DSDL bit layout (little-endian, LSB first per UAVCAN v0 encoding):
///   uint2 radio_instance              # 0 = COM1, 1 = COM2...
///   uint18 active_frequency_khz       # Active frequency in kHz (e.g., 118000 to 136975)
///   uint18 standby_frequency_khz      # Standby frequency in kHz (e.g., 118000 to 136975)
///   uint8 flags                       # Bitmask of active flags
///   uint7 volume                      # Volume level in percent (0 to 100)
///   uint7 squelch                     # Squelch level in percent (0 to 100)
///   uint7 vox                         # VOX threshold level in percent (0 to 100)
///   uint7 intercom                    # Intercom volume level in percent (0 to 100)
///   uint7[<=8] mic_gain               # Microphone gain levels in percent (0 to 100) for up to 8 microphones
///   uint8[<=20] active_station_name   # Name of the active station (ASCII, max 20 characters)
///   uint8[<=20] standby_station_name  # Name of the standby station (ASCII, max 20 characters) - Tail Array Optimization (TAO)
class VhfRadioFullStatus implements DroneCanMessage {
  static const int messageId = 20123;
  static const int messageSignature = 0x77FF345C05600F4F;
  static const bool messageIsService = false;

  @override
  int get id => messageId;

  @override
  int get signature => messageSignature;

  @override
  bool get isService => messageIsService;

  // Flag constants
  static const int flagTx = 1;
  static const int flagRx = 2;
  static const int flagDualActive = 4;
  static const int flagGeneralError = 8;

  final int radioInstance;
  final int activeFrequencyKhz;
  final int standbyFrequencyKhz;
  final int flags;
  final int volume;
  final int squelch;
  final int vox;
  final int intercom;
  final List<int> micGain;
  final String activeStationName;
  final String standbyStationName;

  const VhfRadioFullStatus({
    required this.radioInstance,
    required this.activeFrequencyKhz,
    required this.standbyFrequencyKhz,
    required this.flags,
    required this.volume,
    required this.squelch,
    required this.vox,
    required this.intercom,
    required this.micGain,
    required this.activeStationName,
    required this.standbyStationName,
  });

  bool get isTxActive => (flags & flagTx) != 0;
  bool get isRxActive => (flags & flagRx) != 0;
  bool get isDualActive => (flags & flagDualActive) != 0;
  bool get hasGeneralError => (flags & flagGeneralError) != 0;

  factory VhfRadioFullStatus.fromPayload(Uint8List payload) {
    if (payload.length < 10) {
      throw FormatException(
        'Payload too short for VhfRadioFullStatus message (got ${payload.length} bytes, expected at least 10)',
      );
    }

    final reader = BitReader(payload);

    final radioInstance = reader.readUint(2);
    final activeFrequencyKhz = reader.readUint(18);
    final standbyFrequencyKhz = reader.readUint(18);
    final flags = reader.readUint(8);
    final volume = reader.readUint(7);
    final squelch = reader.readUint(7);
    final vox = reader.readUint(7);
    final intercom = reader.readUint(7);

    // mic_gain: uint7[<=8]
    // Max size is 8. The length prefix size is ceil(log2(8 + 1)) = 4 bits.
    final micGainLen = reader.readUint(4);
    final micGain = <int>[];
    for (int i = 0; i < micGainLen; i++) {
      micGain.add(reader.readUint(7));
    }

    // active_station_name: uint8[<=20]
    // Max size is 20. The length prefix size is ceil(log2(20 + 1)) = 5 bits.
    final activeStationNameLen = reader.readUint(5);
    final activeStationNameBytes = <int>[];
    for (int i = 0; i < activeStationNameLen; i++) {
      activeStationNameBytes.add(reader.readUint(8));
    }
    final activeStationName = String.fromCharCodes(
      activeStationNameBytes,
    ).trim();

    // standby_station_name: uint8[<=20]
    // Tail Array Optimization (TAO) applies (no length prefix, parsed from remaining bytes).
    final standbyStationNameBytes = <int>[];
    final remainingBits = (payload.length * 8) - reader.bitOffset;
    final standbyStationNameLen = remainingBits ~/ 8;
    for (int i = 0; i < standbyStationNameLen; i++) {
      standbyStationNameBytes.add(reader.readUint(8));
    }
    final standbyStationName = String.fromCharCodes(
      standbyStationNameBytes,
    ).trim();

    return VhfRadioFullStatus(
      radioInstance: radioInstance,
      activeFrequencyKhz: activeFrequencyKhz,
      standbyFrequencyKhz: standbyFrequencyKhz,
      flags: flags,
      volume: volume,
      squelch: squelch,
      vox: vox,
      intercom: intercom,
      micGain: micGain,
      activeStationName: activeStationName,
      standbyStationName: standbyStationName,
    );
  }

  @override
  String toString() {
    return 'VhfRadioFullStatus(instance: $radioInstance, active: ${activeFrequencyKhz}kHz ($activeStationName), standby: ${standbyFrequencyKhz}kHz ($standbyStationName), flags: $flags)';
  }
}
