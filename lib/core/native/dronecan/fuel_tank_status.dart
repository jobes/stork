import 'dart:typed_data';
import 'bit_reader.dart';
import 'dronecan_message.dart';

/// Parsed representation of uavcan.equipment.ice.FuelTankStatus (ID 1129).
///
/// DSDL bit layout (little-endian, LSB first per UAVCAN v0 encoding):
///   void9                                 (reserved for future use)
///   uint7   available_fuel_volume_percent (0% to 100%)
///   float32 available_fuel_volume_cm3     (centimeter³)
///   float32 fuel_consumption_rate_cm3pm   (cm³/minute)
///   float16 fuel_temperature              (Kelvin)
///   uint8   fuel_tank_id
class FuelTankStatus implements DroneCanMessage {
  static const int messageId = 1129;
  static const int messageSignature = 0x286b4a387ba84bc4;
  static const bool messageIsService = false;

  @override
  int get id => messageId;

  @override
  int get signature => messageSignature;

  @override
  bool get isService => messageIsService;

  final int availableFuelVolumePercent;
  final double? availableFuelVolumeCm3;
  final double? fuelConsumptionRateCm3pm;
  final double? fuelTemperature;
  final int fuelTankId;

  const FuelTankStatus({
    required this.availableFuelVolumePercent,
    this.availableFuelVolumeCm3,
    this.fuelConsumptionRateCm3pm,
    this.fuelTemperature,
    required this.fuelTankId,
  });

  factory FuelTankStatus.fromPayload(Uint8List payload) {
    if (payload.length < 13) {
      throw FormatException(
        'Payload too short for FuelTankStatus message (got ${payload.length} bytes, expected at least 13)',
      );
    }

    final reader = BitReader(payload);

    // Read void9 (reserved)
    reader.readUint(9);

    // Read uint7 available_fuel_volume_percent
    final percent = reader.readUint(7);

    // Read float32 available_fuel_volume_cm3
    final rawVolume = reader.readFloat32();
    final availableFuelVolumeCm3 = rawVolume.isNaN ? null : rawVolume;

    // Read float32 fuel_consumption_rate_cm3pm
    final rawRate = reader.readFloat32();
    final fuelConsumptionRateCm3pm = rawRate.isNaN ? null : rawRate;

    // Read float16 fuel_temperature
    final rawTemp = reader.readFloat16();
    final fuelTemperature = rawTemp.isNaN ? null : rawTemp;

    // Read uint8 fuel_tank_id
    final fuelTankId = reader.readUint(8);

    return FuelTankStatus(
      availableFuelVolumePercent: percent,
      availableFuelVolumeCm3: availableFuelVolumeCm3,
      fuelConsumptionRateCm3pm: fuelConsumptionRateCm3pm,
      fuelTemperature: fuelTemperature,
      fuelTankId: fuelTankId,
    );
  }

  @override
  String toString() {
    return 'FuelTankStatus(id: $fuelTankId, percent: $availableFuelVolumePercent%, '
        'volume: ${availableFuelVolumeCm3?.toStringAsFixed(1)} cm³, '
        'rate: ${fuelConsumptionRateCm3pm?.toStringAsFixed(1)} cm³/min, '
        'temp: ${fuelTemperature?.toStringAsFixed(1)} K)';
  }
}
