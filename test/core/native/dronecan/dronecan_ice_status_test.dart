import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:stork/core/native/dronecan/ice_status.dart';

class BitWriter {
  final List<int> _bits = [];

  void writeBits(int value, int bitCount) {
    final lastByteIdx = bitCount ~/ 8;
    final rem = bitCount % 8;

    for (int i = 0; i < bitCount; i++) {
      final fByteIdx = i ~/ 8;
      final fBitInByteIdx = i % 8;
      final fBitsInThisByte = (fByteIdx == lastByteIdx) && (rem != 0) ? rem : 8;
      final destBitPos = 8 * fByteIdx + (fBitsInThisByte - 1 - fBitInByteIdx);

      final bitVal = (value >> destBitPos) & 1;
      _bits.add(bitVal);
    }
  }

  void writeUint(int value, int bitCount) => writeBits(value, bitCount);
  void writeInt(int value, int bitCount) => writeBits(value, bitCount);

  void writeFloat32(double value) {
    final buffer = Uint8List(4);
    final byteData = ByteData.sublistView(buffer);
    byteData.setFloat32(0, value, Endian.little);
    final bits = byteData.getUint32(0, Endian.little);
    writeUint(bits, 32);
  }

  void writeFloat16(double value) {
    int bits = 0;
    if (value == 0.0) {
      bits = 0;
    } else if (value.isInfinite) {
      bits = 0x7C00 | (value.isNegative ? 0x8000 : 0);
    } else if (value.isNaN) {
      bits = 0x7C00 | 0x0200;
    } else {
      final sign = value.isNegative ? 0x8000 : 0;
      final absVal = value.abs();
      int exponent = (math.log(absVal) / math.ln2).floor() + 15;
      if (exponent >= 31) {
        bits = sign | 0x7C00;
      } else if (exponent <= 0) {
        final fraction = (absVal / math.pow(2, -14) * 1024.0).round();
        bits = sign | fraction;
      } else {
        final fraction = ((absVal / math.pow(2, exponent - 15) - 1.0) * 1024.0)
            .round();
        bits = sign | ((exponent & 0x1F) << 10) | (fraction & 0x03FF);
      }
    }
    writeUint(bits, 16);
  }

  Uint8List toBytes() {
    final numBytes = (_bits.length + 7) ~/ 8;
    final bytes = Uint8List(numBytes);
    for (int i = 0; i < _bits.length; i++) {
      final byteIndex = i ~/ 8;
      final bitInByte = 7 - (i % 8);
      bytes[byteIndex] |= (_bits[i] << bitInByte);
    }
    return bytes;
  }
}

void main() {
  group('DroneCAN IceStatus Parser Tests', () {
    Uint8List generateIceStatusPayload({
      required int state,
      required int flags,
      required int engineLoadPercent,
      required int engineSpeedRpm,
      required double sparkDwellTimeMs,
      required double atmosphericPressureKpa,
      required double intakeManifoldPressureKpa,
      required double intakeManifoldTemperature,
      required double coolantTemperature,
      required double oilPressure,
      required double oilTemperature,
      required double fuelPressure,
      required double fuelConsumptionRateCm3pm,
      required double estimatedConsumedFuelVolumeCm3,
      required int throttlePositionPercent,
      required int ecuIndex,
      required int sparkPlugUsage,
      List<CylinderStatus> cylinders = const [],
    }) {
      final writer = BitWriter();
      writer.writeUint(state, 2);
      writer.writeUint(flags, 30);
      writer.writeUint(0, 16); // void16
      writer.writeUint(engineLoadPercent, 7);
      writer.writeUint(engineSpeedRpm, 17);

      writer.writeFloat16(sparkDwellTimeMs);
      writer.writeFloat16(atmosphericPressureKpa);
      writer.writeFloat16(intakeManifoldPressureKpa);
      writer.writeFloat16(intakeManifoldTemperature);
      writer.writeFloat16(coolantTemperature);
      writer.writeFloat16(oilPressure);
      writer.writeFloat16(oilTemperature);
      writer.writeFloat16(fuelPressure);

      writer.writeFloat32(fuelConsumptionRateCm3pm);
      writer.writeFloat32(estimatedConsumedFuelVolumeCm3);

      writer.writeUint(throttlePositionPercent, 7);
      writer.writeUint(ecuIndex, 6);
      writer.writeUint(sparkPlugUsage, 3);

      // Under TAO, the dynamic array has no length prefix, so we write cylinder status blocks immediately
      for (final cylinder in cylinders) {
        writer.writeFloat16(cylinder.ignitionTimingDeg ?? double.nan);
        writer.writeFloat16(cylinder.injectionTimeMs ?? double.nan);
        writer.writeFloat16(cylinder.cylinderHeadTemperature ?? double.nan);
        writer.writeFloat16(cylinder.exhaustGasTemperature ?? double.nan);
        writer.writeFloat16(cylinder.lambdaCoefficient ?? double.nan);
      }

      return writer.toBytes();
    }

    test('IceStatus parses correctly with 0 cylinders (35 bytes)', () {
      final payload = generateIceStatusPayload(
        state: IceStatus.stateRunning,
        flags: IceStatus.flagTemperatureSupported,
        engineLoadPercent: 85,
        engineSpeedRpm: 5500,
        sparkDwellTimeMs: 2.5,
        atmosphericPressureKpa: 101.3,
        intakeManifoldPressureKpa: 98.4,
        intakeManifoldTemperature: 298.15,
        coolantTemperature: 355.0,
        oilPressure: 300.0,
        oilTemperature: 365.0,
        fuelPressure: 400.0,
        fuelConsumptionRateCm3pm: 120.5,
        estimatedConsumedFuelVolumeCm3: 5000.0,
        throttlePositionPercent: 80,
        ecuIndex: 1,
        sparkPlugUsage: IceStatus.sparkPlugBothActive,
        cylinders: [],
      );

      expect(payload.length, equals(35));

      final status = IceStatus.fromPayload(payload);

      expect(status.state, equals(IceStatus.stateRunning));
      expect(status.flags, equals(IceStatus.flagTemperatureSupported));
      expect(status.engineLoadPercent, equals(85));
      expect(status.engineSpeedRpm, equals(5500));
      expect(status.coolantTemperature, closeTo(355.0, 0.1));
      expect(status.oilTemperature, closeTo(365.0, 0.1));
      expect(status.cylinders, isEmpty);
    });

    test('IceStatus parses correctly with 2 cylinders (55 bytes)', () {
      final cylindersInput = [
        const CylinderStatus(
          ignitionTimingDeg: 15.0,
          injectionTimeMs: 4.5,
          cylinderHeadTemperature: 380.0,
          exhaustGasTemperature: 850.0,
          lambdaCoefficient: 0.98,
        ),
        const CylinderStatus(
          ignitionTimingDeg: 16.0,
          injectionTimeMs: 4.6,
          cylinderHeadTemperature: 385.0,
          exhaustGasTemperature: 860.0,
          lambdaCoefficient: 0.99,
        ),
      ];

      final payload = generateIceStatusPayload(
        state: IceStatus.stateRunning,
        flags: IceStatus.flagTemperatureSupported,
        engineLoadPercent: 85,
        engineSpeedRpm: 5500,
        sparkDwellTimeMs: 2.5,
        atmosphericPressureKpa: 101.3,
        intakeManifoldPressureKpa: 98.4,
        intakeManifoldTemperature: 298.15,
        coolantTemperature: 355.0,
        oilPressure: 300.0,
        oilTemperature: 365.0,
        fuelPressure: 400.0,
        fuelConsumptionRateCm3pm: 120.5,
        estimatedConsumedFuelVolumeCm3: 5000.0,
        throttlePositionPercent: 80,
        ecuIndex: 1,
        sparkPlugUsage: IceStatus.sparkPlugBothActive,
        cylinders: cylindersInput,
      );

      // 35 bytes + 2 * 10 bytes per cylinder = 55 bytes
      expect(payload.length, equals(55));

      final status = IceStatus.fromPayload(payload);

      expect(status.cylinders.length, equals(2));

      expect(status.cylinders[0].ignitionTimingDeg, closeTo(15.0, 0.1));
      expect(status.cylinders[0].cylinderHeadTemperature, closeTo(380.0, 0.1));
      expect(status.cylinders[0].exhaustGasTemperature, closeTo(850.0, 0.1));

      expect(status.cylinders[1].ignitionTimingDeg, closeTo(16.0, 0.1));
      expect(status.cylinders[1].cylinderHeadTemperature, closeTo(385.0, 0.1));
      expect(status.cylinders[1].exhaustGasTemperature, closeTo(860.0, 0.1));

      expect(
        status.cylinderHeadTemperatures,
        equals([closeTo(380.0, 0.1), closeTo(385.0, 0.1)]),
      );
      expect(
        status.exhaustGasTemperatures,
        equals([closeTo(850.0, 0.1), closeTo(860.0, 0.1)]),
      );
    });

    test(
      'IceStatus hasError returns true when flagTemperatureEgtAboveNominal is set',
      () {
        final payload = generateIceStatusPayload(
          state: IceStatus.stateRunning,
          flags: IceStatus.flagTemperatureEgtAboveNominal,
          engineLoadPercent: 85,
          engineSpeedRpm: 5500,
          sparkDwellTimeMs: 2.5,
          atmosphericPressureKpa: 101.3,
          intakeManifoldPressureKpa: 98.4,
          intakeManifoldTemperature: 298.15,
          coolantTemperature: 355.0,
          oilPressure: 300.0,
          oilTemperature: 365.0,
          fuelPressure: 400.0,
          fuelConsumptionRateCm3pm: 120.5,
          estimatedConsumedFuelVolumeCm3: 5000.0,
          throttlePositionPercent: 80,
          ecuIndex: 1,
          sparkPlugUsage: IceStatus.sparkPlugBothActive,
          cylinders: [],
        );

        final status = IceStatus.fromPayload(payload);
        expect(status.hasError, isTrue);
        expect(status.errorDescription, contains('EGT_ABOVE_NOMINAL'));
      },
    );
  });
}
