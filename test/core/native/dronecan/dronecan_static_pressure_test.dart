import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stork/core/native/dronecan/static_pressure.dart';
import 'package:stork/features/telemetry/presentation/providers/telemetry_provider.dart';
import 'package:stork/core/services/cannelloni_service.dart';

class MockCannelloniService extends Mock implements CannelloniService {}

void main() {
  group('DroneCAN StaticPressure', () {
    test('StaticPressure parsing from payload works correctly', () {
      // 101325.0 Pa in Float32 (little-endian) is [0x80, 0xe6, 0xc5, 0x47]
      final payload = Uint8List.fromList([0x80, 0xe6, 0xc5, 0x47]);
      final pressureMsg = StaticPressure.fromPayload(payload);

      expect(pressureMsg.staticPressure, closeTo(101325.0, 0.01));
      expect(pressureMsg.id, equals(1028));
      expect(pressureMsg.signature, equals(0x44DC4133A6B487BA));
      expect(pressureMsg.isService, isFalse);
    });

    test('TelemetryNotifier updatePressure updates state correctly', () {
      final mockCannelloniService = MockCannelloniService();
      when(() => mockCannelloniService.build()).thenReturn(false);

      final container = ProviderContainer(
        overrides: [
          cannelloniServiceProvider.overrideWith(() => mockCannelloniService),
        ],
      );
      addTearDown(container.dispose);

      // Verify default state pressure
      var state = container.read(telemetryProvider);
      expect(state.airPressure, isNull);

      // Update pressure
      container.read(telemetryProvider.notifier).updatePressure(101325.0);

      // Verify updated state pressure
      state = container.read(telemetryProvider);
      expect(state.airPressure, equals(101325.0));
    });
  });
}
