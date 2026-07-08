import 'dart:typed_data';
import 'bit_reader.dart';
import 'dronecan_message.dart';

/// Parsed representation of uavcan.equipment.air_data.IndicatedAirspeed (ID 1021).
///
/// DSDL definition:
///   float16 indicated_airspeed           # m/s
///   float16 indicated_airspeed_variance   # (m/s)^2
class IndicatedAirspeed implements DroneCanMessage {
  static const int messageId = 1021;
  static const int messageSignature = 0x0A1892D72AB8945F;
  static const bool messageIsService = false;

  @override
  int get id => messageId;

  @override
  int get signature => messageSignature;

  @override
  bool get isService => messageIsService;

  /// Indicated airspeed in m/s.
  final double indicatedAirspeed;

  /// Variance of the indicated airspeed in (m/s)^2.
  final double indicatedAirspeedVariance;

  const IndicatedAirspeed({
    required this.indicatedAirspeed,
    required this.indicatedAirspeedVariance,
  });

  factory IndicatedAirspeed.fromPayload(Uint8List payload) {
    if (payload.length < 4) {
      throw FormatException(
        'Payload too short for IndicatedAirspeed (got ${payload.length} bytes, expected at least 4)',
      );
    }

    final reader = BitReader(payload);
    final ias = reader.readFloat16();
    final variance = reader.readFloat16();

    return IndicatedAirspeed(
      indicatedAirspeed: ias,
      indicatedAirspeedVariance: variance,
    );
  }

  /// Formats a [value] as a fixed‑point string, falling back to [value.toString]
  /// for non‑finite (NaN, Infinity) values that [toStringAsFixed] cannot handle.
  static String _finitesafe(double value) =>
      value.isFinite ? value.toStringAsFixed(2) : value.toString();

  @override
  String toString() {
    return 'IndicatedAirspeed(${_finitesafe(indicatedAirspeed)} m/s, '
        'variance=${_finitesafe(indicatedAirspeedVariance)})';
  }
}
