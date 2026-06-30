import 'dart:typed_data';
import 'bit_reader.dart';
import 'dronecan_message.dart';

/// Per-cylinder status, matching uavcan.equipment.ice.reciprocating.CylinderStatus.
///
/// DSDL bit layout (little-endian, LSB first per UAVCAN v0 encoding):
///   float16 ignition_timing_deg
///   float16 injection_time_ms
///   float16 cylinder_head_temperature   (Kelvin)
///   float16 exhaust_gas_temperature     (Kelvin)
///   float16 lambda_coefficient
class CylinderStatus {
  /// Cylinder ignition timing in angular degrees of the crankshaft.
  final double? ignitionTimingDeg;

  /// Fuel injection time in milliseconds.
  final double? injectionTimeMs;

  /// Cylinder head temperature (CHT) in Kelvin. NaN → unknown.
  final double? cylinderHeadTemperature;

  /// Exhaust gas temperature (EGT) in Kelvin.
  /// NaN means this cylinder has no EGT sensor.
  /// If a shared sensor is used, all cylinders report the same value.
  final double? exhaustGasTemperature;

  /// Lambda coefficient (NaN = unknown).
  final double? lambdaCoefficient;

  const CylinderStatus({
    this.ignitionTimingDeg,
    this.injectionTimeMs,
    this.cylinderHeadTemperature,
    this.exhaustGasTemperature,
    this.lambdaCoefficient,
  });

  @override
  String toString() =>
      'CylinderStatus('
      'cht: ${cylinderHeadTemperature?.toStringAsFixed(1)} K, '
      'egt: ${exhaustGasTemperature?.toStringAsFixed(1)} K, '
      'ign: ${ignitionTimingDeg?.toStringAsFixed(1)}°, '
      'inj: ${injectionTimeMs?.toStringAsFixed(2)} ms)';
}

/// Parsed representation of uavcan.equipment.ice.reciprocating.Status (ID 1120).
///
/// DSDL bit layout (little-endian, LSB first per UAVCAN v0 encoding):
///   uint2   state
///   uint30  flags
///   void16  (reserved)
///   uint7   engine_load_percent
///   uint17  engine_speed_rpm
///   float16 spark_dwell_time_ms
///   float16 atmospheric_pressure_kpa
///   float16 intake_manifold_pressure_kpa
///   float16 intake_manifold_temperature       (Kelvin)
///   float16 coolant_temperature               (Kelvin)
///   float16 oil_pressure                      (kPa)
///   float16 oil_temperature                   (Kelvin)
///   float16 fuel_pressure                     (kPa)
///   float32 fuel_consumption_rate_cm3pm       (cm³/min)
///   float32 estimated_consumed_fuel_volume_cm3 (cm³)
///   uint7   throttle_position_percent
///   uint6   ecu_index
///   uint3   spark_plug_usage
///   uint5   cylinder_count                    (UAVCAN v0 dynamic-array length prefix, ≤16)
///   CylinderStatus[cylinder_count]            (80 bits each: 5×float16)
///
/// All integer fields are required.
/// All floating point fields use NaN to indicate unknown/inapplicable.
/// CHT and EGT are per-cylinder fields inside [cylinders], not flat scalars.
class IceStatus implements DroneCanMessage {
  static const int messageId = 1120;
  static const int messageSignature = 0xd38aa3ee75537ec6;
  static const bool messageIsService = false;

  /// Maximum number of cylinders supported by the DSDL definition.
  static const int maxCylinders = 16;

  // Engine state constants
  static const int stateStopped = 0;
  static const int stateStarting = 1;
  static const int stateRunning = 2;
  static const int stateFault = 3;

  // Flag bitmask constants
  static const int flagGeneralError = 1;
  static const int flagCrankshaftSensorErrorSupported = 2;
  static const int flagCrankshaftSensorError = 4;
  static const int flagTemperatureSupported = 8;
  static const int flagTemperatureBelowNominal = 16;
  static const int flagTemperatureAboveNominal = 32;
  static const int flagTemperatureOverheating = 64;
  static const int flagTemperatureEgtAboveNominal = 128;
  static const int flagFuelPressureSupported = 256;
  static const int flagFuelPressureBelowNominal = 512;
  static const int flagFuelPressureAboveNominal = 1024;
  static const int flagDetonationSupported = 2048;
  static const int flagDetonationObserved = 4096;
  static const int flagMisfireSupported = 8192;
  static const int flagMisfireObserved = 16384;
  static const int flagOilPressureSupported = 32768;
  static const int flagOilPressureBelowNominal = 65536;
  static const int flagOilPressureAboveNominal = 131072;
  static const int flagDebrisSupported = 262144;
  static const int flagDebrisDetected = 524288;

  // Spark plug usage constants
  static const int sparkPlugSingle = 0;
  static const int sparkPlugFirstActive = 1;
  static const int sparkPlugSecondActive = 2;
  static const int sparkPlugBothActive = 3;

  @override
  int get id => messageId;

  @override
  int get signature => messageSignature;

  @override
  bool get isService => messageIsService;

  final int state;
  final int flags;
  final int engineLoadPercent;
  final int engineSpeedRpm;
  final double? sparkDwellTimeMs;
  final double? atmosphericPressureKpa;
  final double? intakeManifoldPressureKpa;
  final double? intakeManifoldTemperature;
  final double? coolantTemperature;
  final double? oilPressure;
  final double? oilTemperature;
  final double? fuelPressure;
  /// Fuel consumption rate in cm³/min.
  final double? fuelConsumptionRateCm3pm;
  /// Estimated consumed fuel volume since engine start, in cm³.
  final double? estimatedConsumedFuelVolumeCm3;
  final int throttlePositionPercent;
  final int ecuIndex;
  final int sparkPlugUsage;

  /// Per-cylinder statuses (0–16 entries).
  /// Use [cylinderHeadTemperatures] / [exhaustGasTemperatures] for per-cylinder
  /// CHT and EGT values.
  final List<CylinderStatus> cylinders;

  const IceStatus({
    required this.state,
    required this.flags,
    required this.engineLoadPercent,
    required this.engineSpeedRpm,
    this.sparkDwellTimeMs,
    this.atmosphericPressureKpa,
    this.intakeManifoldPressureKpa,
    this.intakeManifoldTemperature,
    this.coolantTemperature,
    this.oilPressure,
    this.oilTemperature,
    this.fuelPressure,
    this.fuelConsumptionRateCm3pm,
    this.estimatedConsumedFuelVolumeCm3,
    required this.throttlePositionPercent,
    required this.ecuIndex,
    required this.sparkPlugUsage,
    this.cylinders = const [],
  });

  // ---------------------------------------------------------------------------
  // Cylinder-level accessors
  // ---------------------------------------------------------------------------

  /// CHT (Kelvin) for each cylinder, in order.
  /// A null entry means that cylinder reported no valid sensor reading.
  List<double?> get cylinderHeadTemperatures =>
      cylinders.map((c) => c.cylinderHeadTemperature).toList(growable: false);

  /// EGT (Kelvin) for each cylinder, in order.
  /// A null entry means that cylinder has no EGT sensor.
  List<double?> get exhaustGasTemperatures =>
      cylinders.map((c) => c.exhaustGasTemperature).toList(growable: false);


  /// Returns true when any error-related flag bit is set or state is FAULT.
  bool get hasError =>
      (flags & flagGeneralError) != 0 ||
      (flags & flagCrankshaftSensorError) != 0 ||
      (flags & flagTemperatureOverheating) != 0 ||
      (flags & flagFuelPressureBelowNominal) != 0 ||
      (flags & flagFuelPressureAboveNominal) != 0 ||
      (flags & flagOilPressureBelowNominal) != 0 ||
      (flags & flagOilPressureAboveNominal) != 0 ||
      (flags & flagDetonationObserved) != 0 ||
      (flags & flagMisfireObserved) != 0 ||
      (flags & flagDebrisDetected) != 0 ||
      state == stateFault;

  /// Human-readable description of the active error flags.
  String get errorDescription {
    final parts = <String>[];
    if (state == stateFault) parts.add('STATE_FAULT');
    if ((flags & flagGeneralError) != 0) parts.add('GENERAL_ERROR');
    if ((flags & flagCrankshaftSensorError) != 0) {
      parts.add('CRANKSHAFT_SENSOR_ERROR');
    }
    if ((flags & flagTemperatureOverheating) != 0) parts.add('OVERHEATING');
    if ((flags & flagTemperatureEgtAboveNominal) != 0) {
      parts.add('EGT_ABOVE_NOMINAL');
    }
    if ((flags & flagFuelPressureBelowNominal) != 0) {
      parts.add('FUEL_PRESSURE_LOW');
    }
    if ((flags & flagFuelPressureAboveNominal) != 0) {
      parts.add('FUEL_PRESSURE_HIGH');
    }
    if ((flags & flagOilPressureBelowNominal) != 0) {
      parts.add('OIL_PRESSURE_LOW');
    }
    if ((flags & flagOilPressureAboveNominal) != 0) {
      parts.add('OIL_PRESSURE_HIGH');
    }
    if ((flags & flagDetonationObserved) != 0) parts.add('DETONATION');
    if ((flags & flagMisfireObserved) != 0) parts.add('MISFIRE');
    if ((flags & flagDebrisDetected) != 0) parts.add('DEBRIS');
    return parts.join(', ');
  }

  factory IceStatus.fromPayload(Uint8List payload) {
    // Minimum bits: 2+30+16+7+17 + 8×16 + 2×32 + 7+6+3 = 280 bits → 35 bytes
    if (payload.length < 35) {
      throw FormatException(
        'Payload too short for IceStatus message (got ${payload.length} bytes, expected at least 35)',
      );
    }

    final reader = BitReader(payload);

    // --- Required integer fields ---
    final stateVal = reader.readUint(2);        // uint2   state
    final flagsVal = reader.readUint(30);       // uint30  flags
    reader.readUint(16);                        // void16  (reserved)
    final engineLoad = reader.readUint(7);      // uint7   engine_load_percent
    final rpmVal = reader.readUint(17);         // uint17  engine_speed_rpm

    // --- Float fields (NaN → null) ---
    double? readFloat16OrNull() {
      final v = reader.readFloat16();
      return v.isNaN ? null : v;
    }

    double? readFloat32OrNull() {
      final v = reader.readFloat32();
      return v.isNaN ? null : v;
    }

    final sparkDwellTimeMs = readFloat16OrNull();            // float16
    final atmosphericPressureKpa = readFloat16OrNull();      // float16
    final intakeManifoldPressureKpa = readFloat16OrNull();   // float16
    final intakeManifoldTemperature = readFloat16OrNull();   // float16
    final coolantTemperature = readFloat16OrNull();          // float16
    final oilPressure = readFloat16OrNull();                 // float16
    final oilTemperature = readFloat16OrNull();              // float16
    final fuelPressure = readFloat16OrNull();                // float16
    final fuelConsumptionRateCm3pm = readFloat32OrNull();    // float32
    final estimatedConsumedFuelVolumeCm3 = readFloat32OrNull(); // float32

    // --- Remaining integer fields ---
    final throttlePositionPercent = reader.readUint(7);      // uint7
    final ecuIndex = reader.readUint(6);                     // uint6
    final sparkPlugUsage = reader.readUint(3);               // uint3

    // --- Dynamic array of CylinderStatus ---
    // Since cylinders is the last field of uavcan.equipment.ice.reciprocating.Status,
    // and its element size is >= 8 bits (80 bits = 10 bytes), UAVCAN v0 / DroneCAN tail array optimization (TAO)
    // applies. The length prefix is omitted, and the array length is inferred from the remaining payload bytes.
    final cylinders = <CylinderStatus>[];
    const cylinderBitsPerEntry = 80; // 5×16

    final remainingBits = (payload.length * 8) - reader.bitOffset;
    final cylinderCount = (remainingBits / cylinderBitsPerEntry).floor().clamp(0, maxCylinders);

    for (int i = 0; i < cylinderCount; i++) {
      if (reader.bitOffset + cylinderBitsPerEntry > payload.length * 8) break;

      double? readCylFloat16() {
        final v = reader.readFloat16();
        return v.isNaN ? null : v;
      }

      final ignitionTimingDeg = readCylFloat16();
      final injectionTimeMs = readCylFloat16();
      final cylinderHeadTemperature = readCylFloat16();
      final exhaustGasTemperature = readCylFloat16();
      final lambdaCoefficient = readCylFloat16();

      cylinders.add(
        CylinderStatus(
          ignitionTimingDeg: ignitionTimingDeg,
          injectionTimeMs: injectionTimeMs,
          cylinderHeadTemperature: cylinderHeadTemperature,
          exhaustGasTemperature: exhaustGasTemperature,
          lambdaCoefficient: lambdaCoefficient,
        ),
      );
    }

    return IceStatus(
      state: stateVal,
      flags: flagsVal,
      engineLoadPercent: engineLoad,
      engineSpeedRpm: rpmVal,
      sparkDwellTimeMs: sparkDwellTimeMs,
      atmosphericPressureKpa: atmosphericPressureKpa,
      intakeManifoldPressureKpa: intakeManifoldPressureKpa,
      intakeManifoldTemperature: intakeManifoldTemperature,
      coolantTemperature: coolantTemperature,
      oilPressure: oilPressure,
      oilTemperature: oilTemperature,
      fuelPressure: fuelPressure,
      fuelConsumptionRateCm3pm: fuelConsumptionRateCm3pm,
      estimatedConsumedFuelVolumeCm3: estimatedConsumedFuelVolumeCm3,
      throttlePositionPercent: throttlePositionPercent,
      ecuIndex: ecuIndex,
      sparkPlugUsage: sparkPlugUsage,
      cylinders: cylinders,
    );
  }

  @override
  String toString() {
    return 'IceStatus(state: $state, flags: 0x${flags.toRadixString(16)}, '
        'load: $engineLoadPercent%, rpm: $engineSpeedRpm, '
        'coolant: ${coolantTemperature?.toStringAsFixed(1)} K, '
        'oilP: ${oilPressure?.toStringAsFixed(1)} kPa, '
        'oilT: ${oilTemperature?.toStringAsFixed(1)} K, '
        'fuelRate: ${fuelConsumptionRateCm3pm?.toStringAsFixed(1)} cm³/min, '
        'throttle: $throttlePositionPercent%, ecu: $ecuIndex, '
        'spark: $sparkPlugUsage, '
        'cylinders: ${cylinders.length}, '
        'chts: $cylinderHeadTemperatures, '
        'egts: $exhaustGasTemperatures)';
  }
}
