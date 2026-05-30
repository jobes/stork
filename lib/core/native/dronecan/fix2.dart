import 'dart:math' as math;
import 'dart:typed_data';
import 'bit_reader.dart';
import 'dronecan_message.dart';

class Fix2 implements DroneCanMessage {
  static const int messageId = 1063;
  static const int messageSignature = 0xCA41E7000F37435F;
  static const bool messageIsService = false;

  @override
  int get id => messageId;

  @override
  int get signature => messageSignature;

  @override
  bool get isService => messageIsService;

  final int timestamp;
  final int gnssTimestamp;
  final int gnssTimeStandard;
  final int numLeapSeconds;
  final double latitude;
  final double longitude;
  final double altitude;
  final double? groundSpeed;
  final double? heading;
  final int satellites;
  final int status;
  final double pdop;
  final int mode;
  final int subMode;
  final List<double> positionCovariance;
  final List<double> velocityCovariance;

  final double? horizontalAccuracy;
  final double? verticalAccuracy;

  Fix2({
    required this.timestamp,
    required this.gnssTimestamp,
    required this.gnssTimeStandard,
    required this.numLeapSeconds,
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.groundSpeed,
    required this.heading,
    required this.satellites,
    required this.status,
    required this.pdop,
    required this.mode,
    required this.subMode,
    required this.positionCovariance,
    required this.velocityCovariance,
    required this.horizontalAccuracy,
    required this.verticalAccuracy,
  });

  factory Fix2.fromPayload(Uint8List payload) {
    if (payload.length < 50) {
      throw FormatException(
        'Payload too short for Fix2 GNSS message (got ${payload.length} bytes, expected at least 50)',
      );
    }

    final reader = BitReader(payload);

    final timestampVal = reader.readUint(56);
    final gnssTimestampVal = reader.readUint(56);
    final gnssTimeStandardVal = reader.readUint(3);
    reader.readUint(13); // padding
    final numLeapSecondsVal = reader.readUint(8);

    final lonRaw = reader.readInt(37);
    final latRaw = reader.readInt(37);

    final lat = latRaw / 1e8;
    final lon = lonRaw / 1e8;

    // Altitudes are in mm (int27)
    reader.readInt(27); // heightEllipsoidMm (unused but required to advance reader)
    final heightMslMm = reader.readInt(27);
    final alt = heightMslMm / 1000.0;

    // NED Velocity: float32[3] (m/s)
    final velN = reader.readFloat32();
    final velE = reader.readFloat32();
    reader.readFloat32(); // velD (unused but required to advance reader)

    // Derive ground speed and heading from North/East components
    final gSpeed = math.sqrt(velN * velN + velE * velE);
    double? hdg;
    if (gSpeed > 0.2) {
      final rad = math.atan2(velE, velN);
      hdg = (rad * 180.0 / math.pi) % 360.0;
      if (hdg < 0) {
        hdg += 360.0;
      }
    }

    final satsUsed = reader.readUint(6);
    final statusVal = reader.readUint(2);

    final modeVal = reader.readUint(4);
    final subModeVal = reader.readUint(6);

    // covariance: float16[<=36]
    final covLen = reader.readUint(6);
    final cov = <double>[];
    for (var i = 0; i < covLen; i++) {
      cov.add(reader.readFloat16());
    }

    final pdopVal = reader.readFloat16();

    // Split covariance into position and velocity portions
    final posCov = cov.sublist(0, math.min(9, cov.length));
    final velCov = cov.length > 9
        ? cov.sublist(9, math.min(18, cov.length))
        : <double>[];

    // Calculate horizontal accuracy (EPH) and vertical accuracy (EPV)
    double? horAcc;
    double? vertAcc;

    if (posCov.isNotEmpty) {
      if (posCov.length == 1) {
        final variance = posCov[0];
        horAcc = math.sqrt(variance * 2.0);
        vertAcc = math.sqrt(variance);
      } else if (posCov.length == 3) {
        final varN = posCov[0];
        final varE = posCov[1];
        final varD = posCov[2];
        horAcc = math.sqrt(varN + varE);
        vertAcc = math.sqrt(varD);
      } else if (posCov.length == 6) {
        final varN = posCov[0];
        final varE = posCov[3];
        final varD = posCov[5];
        horAcc = math.sqrt(varN + varE);
        vertAcc = math.sqrt(varD);
      } else if (posCov.length >= 9) {
        final varN = posCov[0];
        final varE = posCov[4];
        final varD = posCov[8];
        horAcc = math.sqrt(varN + varE);
        vertAcc = math.sqrt(varD);
      }
    }

    return Fix2(
      timestamp: timestampVal,
      gnssTimestamp: gnssTimestampVal,
      gnssTimeStandard: gnssTimeStandardVal,
      numLeapSeconds: numLeapSecondsVal,
      latitude: lat,
      longitude: lon,
      altitude: alt,
      groundSpeed: gSpeed,
      heading: hdg,
      satellites: satsUsed,
      status: statusVal,
      pdop: pdopVal,
      mode: modeVal,
      subMode: subModeVal,
      positionCovariance: posCov,
      velocityCovariance: velCov,
      horizontalAccuracy: horAcc,
      verticalAccuracy: vertAcc,
    );
  }

  @override
  String toString() {
    return 'Fix2(lat: ${latitude.toStringAsFixed(6)}, lon: ${longitude.toStringAsFixed(6)}, alt: ${altitude.toStringAsFixed(2)}m, sats: $satellites, gSpeed: ${groundSpeed?.toStringAsFixed(1)} m/s, heading: ${heading?.toStringAsFixed(0)}°, hAcc: ${horizontalAccuracy?.toStringAsFixed(2)}m, vAcc: ${verticalAccuracy?.toStringAsFixed(2)}m, mode: $mode, subMode: $subMode)';
  }
}
