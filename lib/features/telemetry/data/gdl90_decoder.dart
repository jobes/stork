import 'package:flutter/foundation.dart';
import '../domain/models/gdl90_target.dart';

/// Decoded GDL90 Message container
abstract class Gdl90Message {
  const Gdl90Message();
}

/// Heartbeat message (ID 0x00)
class Gdl90HeartbeatMessage extends Gdl90Message {
  final bool gpsPositionValid;
  final bool utcTimingValid;
  final int timeStampSeconds;

  const Gdl90HeartbeatMessage({
    required this.gpsPositionValid,
    required this.utcTimingValid,
    required this.timeStampSeconds,
  });
}

/// Traffic report message (ID 0x14 / 20)
class Gdl90TrafficMessage extends Gdl90Message {
  final Gdl90Target target;

  const Gdl90TrafficMessage(this.target);
}

/// Ownship report message (ID 0x0A / 10)
class Gdl90OwnshipMessage extends Gdl90Message {
  final Gdl90Target target;

  const Gdl90OwnshipMessage(this.target);
}

/// GDL90 Protocol Decoder
class Gdl90Decoder {
  static const int flagByte = 0x7E;
  static const int escapeByte = 0x7D;

  final List<int> _frameBuffer = [];
  bool _inFrame = false;
  bool _escaped = false;

  /// Process incoming byte stream and return list of decoded valid GDL90 messages
  List<Gdl90Message> processBytes(Uint8List chunk) {
    final List<Gdl90Message> messages = [];

    for (int i = 0; i < chunk.length; i++) {
      final byte = chunk[i] & 0xFF;

      if (byte == flagByte) {
        if (_inFrame && _frameBuffer.isNotEmpty) {
          final msg = decodeMessage(_frameBuffer);
          if (msg != null) {
            messages.add(msg);
          }
        }
        _frameBuffer.clear();
        _inFrame = true;
        _escaped = false;
        continue;
      }

      if (!_inFrame) {
        continue;
      }

      if (_escaped) {
        _frameBuffer.add(byte ^ 0x20);
        _escaped = false;
      } else if (byte == escapeByte) {
        _escaped = true;
      } else {
        _frameBuffer.add(byte);
      }
    }

    return messages;
  }

  /// Decode an unstuffed payload (including 2 trailing FCS bytes)
  static Gdl90Message? decodeMessage(List<int> payload) {
    if (payload.length < 3) {
      return null; // Min length: ID (1 byte) + FCS (2 bytes)
    }

    // FCS check
    if (!validateFcs(payload)) {
      return null;
    }

    final messageId = payload[0] & 0xFF;

    switch (messageId) {
      case 0x00: // Heartbeat
        return parseHeartbeat(payload);
      case 0x14: // Traffic Report (20)
        return parseTrafficReport(payload, isOwnship: false);
      case 0x0A: // Ownship Report (10)
        return parseTrafficReport(payload, isOwnship: true);
      default:
        // Other message types (e.g. 0x0B Ownship Geo Altitude, 0x20 UAT, etc.) ignored
        return null;
    }
  }

  /// FCS (CRC16-CCITT) Validation
  static bool validateFcs(List<int> payload) {
    final len = payload.length;
    if (len < 3) return false;

    // Received FCS in both byte orders (GDL90 spec is LSB-first, but some
    // implementations send MSB-first)
    final rxLittleEndian =
        (payload[len - 2] & 0xFF) | ((payload[len - 1] & 0xFF) << 8);
    final rxBigEndian =
        ((payload[len - 2] & 0xFF) << 8) | (payload[len - 1] & 0xFF);

    // 1. GDL90 / OGN: non-reflected 0x1021 with byte XOR after lookup
    //    crc = table[(crc >> 8)] ^ (crc << 8) ^ byte
    final calcGdl90 = calculateFcsGdl90(payload, 0, len - 2);
    if (rxLittleEndian == calcGdl90 || rxBigEndian == calcGdl90) return true;

    // 2. SafeSky Non-reflected 0x1021 over (len - 2) bytes
    final calc1021 = calculateFcs1021(payload, 0, len - 2);
    if (rxLittleEndian == calc1021 || rxBigEndian == calc1021) return true;

    // 3. Heartbeat (0x00) fallback: some implementations (SafeSky) append extra
    //    status bytes after the standard 5-byte heartbeat, making FCS validation
    //    over the full payload impossible. Only bypass for structurally valid
    //    heartbeat payloads (standard GDL90 heartbeat is 5 bytes + FCS = 7 min).
    if (payload[0] == 0x00 && len >= 7) {
      // Try FCS over the standard 5-byte heartbeat body (ID + 4 data bytes)
      final calcHeartbeatFcs = calculateFcsGdl90(payload, 0, 5);
      if (rxLittleEndian == calcHeartbeatFcs ||
          rxBigEndian == calcHeartbeatFcs) {
        return true;
      }
      final calcHeartbeat1021 = calculateFcs1021(payload, 0, 5);
      if (rxLittleEndian == calcHeartbeat1021 ||
          rxBigEndian == calcHeartbeat1021) {
        return true;
      }

      // Last resort: validate heartbeat structure (status byte 1 bit 7 is GPS
      // valid flag — must be 0 or 1, and the reserved bits in status bytes
      // should be 0 in compliant implementations)
      final st1 = payload[1] & 0xFF;
      final st2 = payload[2] & 0xFF;
      // Bits 5-0 of st1 should be 0 in standard GDL90; bit 7 is GPS status
      // For SafeSky compatibility we only check that the reserved bits aren't
      // all set (0x3F would mean all reserved bits are 1, which is implausible)
      if ((st1 & 0x3F) == 0x3F) return false;
      // st2 bits 7-2 should typically be 0; bit 1 is maintenance req, bit 0 UTC
      if ((st2 & 0xFC) == 0xFC) return false;
      return true;
    }

    final hexPayload = payload
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join(' ');
    debugPrint(
      '[Gdl90Decoder] FCS MISMATCH! len=$len, payload=[$hexPayload], '
      'rxLE=0x${rxLittleEndian.toRadixString(16).padLeft(4, '0')}, '
      'calcGdl90=0x${calcGdl90.toRadixString(16).padLeft(4, '0')}',
    );
    return false;
  }

  /// Calculate CRC16-CCITT FCS for GDL90/OGN (poly 0x1021, byte XOR after table lookup)
  /// This is the algorithm used by SoftRF, OGN, and the GDL90 ICD:
  ///   crc = table[(crc >> 8)] ^ (crc << 8) ^ byte
  static int calculateFcsGdl90(List<int> bytes, [int start = 0, int? end]) {
    int crc = 0x0000;
    final stop = end ?? bytes.length;

    for (int i = start; i < stop; i++) {
      final byte = bytes[i] & 0xFF;
      crc = (crcTable1021[(crc >> 8)] ^ (crc << 8) ^ byte) & 0xFFFF;
    }

    return crc;
  }

  /// Calculate CRC16-CCITT Non-reflected (poly 0x1021, used by SafeSky)
  static int calculateFcs1021(List<int> bytes, [int start = 0, int? end]) {
    int crc = 0x0000;
    final stop = end ?? bytes.length;

    for (int i = start; i < stop; i++) {
      final byte = bytes[i] & 0xFF;
      crc = (crcTable1021[((crc >> 8) ^ byte) & 0xFF] ^ (crc << 8)) & 0xFFFF;
    }

    return crc;
  }

  /// Parse Heartbeat (0x00)
  static Gdl90HeartbeatMessage? parseHeartbeat(List<int> payload) {
    if (payload.length < 5) return null; // 5 bytes min data payload

    final st1 = payload[1] & 0xFF;
    final st2 = payload[2] & 0xFF;

    final gpsValid = (st1 & 0x80) != 0;
    final utcValid = (st2 & 0x01) != 0;

    final tsMsb = (payload[3] & 0x80) != 0 ? 1 : 0;
    final tsB1 = payload[3] & 0x7F;
    final tsB2 = payload[4] & 0xFF;
    final timeStampSeconds = (tsMsb << 15) | (tsB1 << 8) | tsB2;

    return Gdl90HeartbeatMessage(
      gpsPositionValid: gpsValid,
      utcTimingValid: utcValid,
      timeStampSeconds: timeStampSeconds,
    );
  }

  /// Parse Traffic Report (0x14) or Ownship Report (0x0A)
  static Gdl90Message? parseTrafficReport(
    List<int> payload, {
    required bool isOwnship,
  }) {
    if (payload.length < 30) {
      return null; // 28 bytes data (ID + 27) + 2 bytes FCS
    }

    // Byte 1: Alert status (bits 7-4) & Address type (bits 3-0)

    // Bytes 2, 3, 4: Participant address (24-bit ICAO address MSB first)
    final addrInt =
        ((payload[2] & 0xFF) << 16) |
        ((payload[3] & 0xFF) << 8) |
        (payload[4] & 0xFF);
    final hexAddr = addrInt.toRadixString(16).padLeft(6, '0').toUpperCase();

    // Bytes 5, 6, 7: Latitude (24-bit signed 2's complement)
    int rawLat =
        ((payload[5] & 0xFF) << 16) |
        ((payload[6] & 0xFF) << 8) |
        (payload[7] & 0xFF);
    if ((rawLat & 0x800000) != 0) {
      rawLat -= 0x1000000; // Sign extend negative
    }
    final latitude = (rawLat * 180.0 / 8388608.0).clamp(-90.0, 90.0);

    // Bytes 8, 9, 10: Longitude (24-bit signed 2's complement)
    int rawLon =
        ((payload[8] & 0xFF) << 16) |
        ((payload[9] & 0xFF) << 8) |
        (payload[10] & 0xFF);
    if ((rawLon & 0x800000) != 0) {
      rawLon -= 0x1000000; // Sign extend negative
    }
    final longitude = (rawLon * 180.0 / 8388608.0).clamp(-180.0, 180.0);

    // Bytes 11, 12: Altitude (12-bit unsigned, 25ft resolution, -1000ft offset)
    final rawAlt = ((payload[11] & 0xFF) << 4) | ((payload[12] & 0xF0) >> 4);
    final double altitudeFeet;
    final bool altitudeValid;
    if (rawAlt == 0xFFF) {
      altitudeFeet = 0.0; // Invalid / unavailable
      altitudeValid = false;
    } else {
      altitudeFeet = (rawAlt * 25.0) - 1000.0;
      altitudeValid = true;
    }

    // Bytes 14, 15: Ground speed (12-bit unsigned in knots)
    final rawSpeed = ((payload[14] & 0xFF) << 4) | ((payload[15] & 0xF0) >> 4);
    final double speedKnots;
    final bool speedValid;
    if (rawSpeed == 0xFFF) {
      speedKnots = 0.0;
      speedValid = false;
    } else {
      speedKnots = rawSpeed.toDouble();
      speedValid = true;
    }

    // Bytes 15 (LS nibble), 16: Vertical speed (12-bit signed, 64 ft/min resolution)
    final vsHi = payload[15] & 0x0F; // Upper 4 bits (from byte 15 LS nibble)
    final vsLo = payload[16] & 0xFF; // Lower 8 bits
    int rawVs = (vsHi << 8) | vsLo;

    // Byte 17: Track (8-bit resolution 360 / 256 degrees)
    final trackDegrees = (payload[17] & 0xFF) * (360.0 / 256.0);
    if ((rawVs & 0x800) != 0) {
      rawVs -= 0x1000; // Sign extend 12-bit
    }
    final double verticalSpeedFpm;
    final bool verticalSpeedValid;
    if (rawVs == 0x7FF || rawVs == -0x800) {
      verticalSpeedFpm = 0.0;
      verticalSpeedValid = false;
    } else {
      verticalSpeedFpm = rawVs * 64.0;
      verticalSpeedValid = true;
    }

    debugPrint(
      '[Gdl90Decoder] TrafficReport vs raw: payload[15]=0x${payload[15].toRadixString(16).padLeft(2, '0')} payload[16]=0x${payload[16].toRadixString(16).padLeft(2, '0')} → vsHi=$vsHi vsLo=$vsLo → rawVs=$rawVs → vsFpm=${verticalSpeedFpm.toStringAsFixed(0)} (valid=$verticalSpeedValid)',
    );

    // Byte 18: Emitter Category (GDL90 ICD — Light/Medium/Heavy/Helicopter/etc.)
    final emitterCategory = payload[18] & 0xFF;

    // Bytes 19..26: Call-sign (8 ASCII characters, space-padded, GDL90 ICD)
    final callsignBytes = payload.sublist(19, 27);
    final rawCallsign = String.fromCharCodes(
      callsignBytes,
    ).replaceAll('\x00', '').trim();
    final callsign = rawCallsign.isNotEmpty ? rawCallsign : null;

    final target = Gdl90Target(
      id: hexAddr,
      callsign: callsign,
      latitude: latitude,
      longitude: longitude,
      altitudeFeet: altitudeFeet,
      altitudeValid: altitudeValid,
      trackDegrees: trackDegrees,
      speedKnots: speedKnots,
      speedValid: speedValid,
      verticalSpeedFpm: verticalSpeedFpm,
      verticalSpeedValid: verticalSpeedValid,
      lastUpdated: DateTime.now(),
      emitterCategory: emitterCategory,
    );

    if (isOwnship) {
      return Gdl90OwnshipMessage(target);
    } else {
      return Gdl90TrafficMessage(target);
    }
  }

  /// Non-reflected CRC16-CCITT Lookup Table (Poly 0x1021, used by GDL90 and SafeSky)
  static const List<int> crcTable1021 = [
    0x0000,
    0x1021,
    0x2042,
    0x3063,
    0x4084,
    0x50a5,
    0x60c6,
    0x70e7,
    0x8108,
    0x9129,
    0xa14a,
    0xb16b,
    0xc18c,
    0xd1ad,
    0xe1ce,
    0xf1ef,
    0x1231,
    0x0210,
    0x3273,
    0x2252,
    0x52b5,
    0x4294,
    0x72f7,
    0x62d6,
    0x9339,
    0x8318,
    0xb37b,
    0xa35a,
    0xd3bd,
    0xc39c,
    0xf3ff,
    0xe3de,
    0x2462,
    0x3443,
    0x0420,
    0x1401,
    0x64e6,
    0x74c7,
    0x44a4,
    0x5485,
    0xa56a,
    0xb54b,
    0x8528,
    0x9509,
    0xe5ee,
    0xf5cf,
    0xc5ac,
    0xd58d,
    0x3653,
    0x2672,
    0x1611,
    0x0630,
    0x76d7,
    0x66f6,
    0x5695,
    0x46b4,
    0xb75b,
    0xa77a,
    0x9719,
    0x8738,
    0xf7df,
    0xe7fe,
    0xd79d,
    0xc7bc,
    0x48c4,
    0x58e5,
    0x6886,
    0x78a7,
    0x0840,
    0x1861,
    0x2802,
    0x3823,
    0xc9cc,
    0xd9ed,
    0xe98e,
    0xf9af,
    0x8948,
    0x9969,
    0xa90a,
    0xb92b,
    0x5af5,
    0x4ad4,
    0x7ab7,
    0x6a96,
    0x1a71,
    0x0a50,
    0x3a33,
    0x2a12,
    0xdbfd,
    0xcbdc,
    0xfbbf,
    0xeb9e,
    0x9b79,
    0x8b58,
    0xbb3b,
    0xab1a,
    0x6ca6,
    0x7c87,
    0x4ce4,
    0x5cc5,
    0x2c22,
    0x3c03,
    0x0c60,
    0x1c41,
    0xedae,
    0xfd8f,
    0xcdec,
    0xddcd,
    0xad2a,
    0xbd0b,
    0x8d68,
    0x9d49,
    0x7e97,
    0x6eb6,
    0x5ed5,
    0x4ef4,
    0x3e13,
    0x2e32,
    0x1e51,
    0x0e70,
    0xff9f,
    0xefbe,
    0xdfdd,
    0xcffc,
    0xbf1b,
    0xaf3a,
    0x9f59,
    0x8f78,
    0x9188,
    0x81a9,
    0xb1ca,
    0xa1eb,
    0xd10c,
    0xc12d,
    0xf14e,
    0xe16f,
    0x1080,
    0x00a1,
    0x30c2,
    0x20e3,
    0x5004,
    0x4025,
    0x7046,
    0x6067,
    0x83b9,
    0x9398,
    0xa3fb,
    0xb3da,
    0xc33d,
    0xd31c,
    0xe37f,
    0xf35e,
    0x02b1,
    0x1290,
    0x22f3,
    0x32d2,
    0x4235,
    0x5214,
    0x6277,
    0x7256,
    0xb5ea,
    0xa5cb,
    0x95a8,
    0x8589,
    0xf56e,
    0xe54f,
    0xd52c,
    0xc50d,
    0x34e2,
    0x24c3,
    0x14a0,
    0x0481,
    0x7466,
    0x6447,
    0x5424,
    0x4405,
    0xa7db,
    0xb7fa,
    0x8799,
    0x97b8,
    0xe75f,
    0xf77e,
    0xc71d,
    0xd73c,
    0x26d3,
    0x36f2,
    0x0691,
    0x16b0,
    0x6657,
    0x7676,
    0x4615,
    0x5634,
    0xd94c,
    0xc96d,
    0xf90e,
    0xe92f,
    0x99c8,
    0x89e9,
    0xb98a,
    0xa9ab,
    0x5844,
    0x4865,
    0x7806,
    0x6827,
    0x18c0,
    0x08e1,
    0x3882,
    0x28a3,
    0xcb7d,
    0xdb5c,
    0xeb3f,
    0xfb1e,
    0x8bf9,
    0x9bd8,
    0xabbb,
    0xbb9a,
    0x4a75,
    0x5a54,
    0x6a37,
    0x7a16,
    0x0af1,
    0x1ad0,
    0x2ab3,
    0x3a92,
    0xfd2e,
    0xed0f,
    0xdd6c,
    0xcd4d,
    0xbdaa,
    0xad8b,
    0x9de8,
    0x8dc9,
    0x7c26,
    0x6c07,
    0x5c64,
    0x4c45,
    0x3ca2,
    0x2c83,
    0x1ce0,
    0x0cc1,
    0xef1f,
    0xff3e,
    0xcf5d,
    0xdf7c,
    0xaf9b,
    0xbfba,
    0x8fd9,
    0x9ff8,
    0x6e17,
    0x7e36,
    0x4e55,
    0x5e74,
    0x2e93,
    0x3eb2,
    0x0ed1,
    0x1ef0,
  ];
}
