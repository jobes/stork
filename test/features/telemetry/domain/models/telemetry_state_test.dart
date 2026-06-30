import 'package:flutter_test/flutter_test.dart';
import 'package:stork/features/telemetry/domain/models/telemetry_state.dart';

void main() {
  group('TelemetryField Deserialization Tests', () {
    test('Deserializing double/REAL fields with whole numbers/ints', () {
      final fields = [
        TelemetryField.latitude,
        TelemetryField.longitude,
        TelemetryField.heading,
        TelemetryField.groundSpeed,
        TelemetryField.indicatedAirSpeed,
        TelemetryField.airPressure,
        TelemetryField.gpsAltitude,
        TelemetryField.gpsHorizontalAccuracy,
        TelemetryField.gpsVerticalAccuracy,
      ];

      for (final field in fields) {
        // Deserializing an int
        final deserialized = field.deserialize(42);
        expect(deserialized, isA<double>());
        expect(deserialized, equals(42.0));

        // Deserializing a double
        final deserializedDouble = field.deserialize(42.5);
        expect(deserializedDouble, isA<double>());
        expect(deserializedDouble, equals(42.5));

        // Deserializing null
        expect(field.deserialize(null), isNull);
      }
    });

    test('Deserializing boolean/INTEGER isGpsDroneCan', () {
      expect(TelemetryField.isGpsDroneCan.deserialize(1), isTrue);
      expect(TelemetryField.isGpsDroneCan.deserialize(0), isFalse);
      expect(TelemetryField.isGpsDroneCan.deserialize(null), isNull);
    });

    test('Deserializing integer gpsSatelliteCount', () {
      expect(TelemetryField.gpsSatelliteCount.deserialize(5), equals(5));
      expect(TelemetryField.gpsSatelliteCount.deserialize(null), isNull);
    });

    test(
      'TelemetryState.copyWithField double cast safety with deserialized values',
      () {
        var state = const TelemetryState();

        final fields = [
          TelemetryField.latitude,
          TelemetryField.longitude,
          TelemetryField.heading,
          TelemetryField.groundSpeed,
          TelemetryField.indicatedAirSpeed,
          TelemetryField.airPressure,
          TelemetryField.gpsAltitude,
          TelemetryField.gpsHorizontalAccuracy,
          TelemetryField.gpsVerticalAccuracy,
        ];

        for (final field in fields) {
          final val = field.deserialize(10); // SQLite returned whole number
          expect(val, isA<double>());
          final updatedState = state.copyWithField(field, val);
          expect(updatedState.getFieldValue(field), equals(10.0));
        }
      },
    );

    test('TelemetryState.copyWithField cylinderHeadTemperature and exhaustGasTemperature supports both List and JSON String', () {
      var state = const TelemetryState();

      // Test List input
      var updatedState = state.copyWithField(TelemetryField.cylinderHeadTemperature, [450.5, 451.0]);
      expect(updatedState.cylinderHeadTemperatures, equals([450.5, 451.0]));

      // Test JSON String input
      updatedState = state.copyWithField(TelemetryField.cylinderHeadTemperature, '[450.5, 451.0]');
      expect(updatedState.cylinderHeadTemperatures, equals([450.5, 451.0]));

      // Test List input for EGT
      updatedState = state.copyWithField(TelemetryField.exhaustGasTemperature, [650.5, 651.0]);
      expect(updatedState.exhaustGasTemperatures, equals([650.5, 651.0]));

      // Test JSON String input for EGT
      updatedState = state.copyWithField(TelemetryField.exhaustGasTemperature, '[650.5, 651.0]');
      expect(updatedState.exhaustGasTemperatures, equals([650.5, 651.0]));
    });
  });
}
