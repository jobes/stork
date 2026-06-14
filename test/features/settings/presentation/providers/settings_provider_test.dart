import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stork/core/services/mdns_service.dart';
import 'package:stork/features/settings/domain/models/cannelloni_device.dart';
import 'package:stork/features/settings/data/repositories/settings_repository.dart';
import 'package:stork/features/settings/domain/models/app_settings.dart';
import 'package:stork/features/settings/domain/models/range_thresholds.dart';
import 'package:stork/features/settings/domain/models/speed_unit.dart';
import 'package:stork/features/settings/domain/models/widget_position.dart';
import 'package:stork/features/settings/presentation/providers/settings_provider.dart';
import 'package:stork/core/utils/aviation_math.dart';

class MockSettingsRepository implements SettingsRepository {
  AppSettings currentSettings = const AppSettings();
  bool shouldThrow = false;
  bool Function(AppSettings)? shouldThrowFor;
  Duration? delay;
  final List<String> logs = [];

  MockSettingsRepository({
    this.currentSettings = const AppSettings(),
    this.shouldThrow = false,
    this.delay,
  });

  @override
  Future<AppSettings> getSettings() async => currentSettings;

  @override
  Future<void> saveSettings(AppSettings settings) async {
    logs.add('start_${settings.mapFontSize}');
    if (delay != null) {
      await Future.delayed(delay!);
    }
    if (shouldThrow || (shouldThrowFor != null && shouldThrowFor!(settings))) {
      logs.add('error_${settings.mapFontSize}');
      throw StateError('Simulated save failure');
    }
    currentSettings = settings;
    logs.add('success_${settings.mapFontSize}');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('AppSettingsNotifier Tests', () {
    late MockSettingsRepository mockRepository;

    setUp(() {
      mockRepository = MockSettingsRepository(
        currentSettings: const AppSettings(
          mapFontSize: 1.0,
          mapDefaultZoom: 6.0,
          autoSelectDevice: false,
        ),
      );
    });

    test('Saves settings successfully and updates state', () async {
      final container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWith(
            (ref) async => mockRepository,
          ),
        ],
      );
      addTearDown(container.dispose);

      // Keep the provider alive by listening to it
      final sub = container.listen(appSettingsProvider, (_, _) {});
      addTearDown(sub.close);

      // Wait for provider to build/load
      final initialSettings = await container.read(appSettingsProvider.future);
      expect(initialSettings.mapFontSize, equals(1.0));

      final notifier = container.read(appSettingsProvider.notifier);
      final result = await notifier.updateFontSize(1.5);

      expect(result, isA<SettingsUpdateSuccess>());
      expect(
        container.read(appSettingsProvider).value?.mapFontSize,
        equals(1.5),
      );
      expect(mockRepository.currentSettings.mapFontSize, equals(1.5));
    });

    test('Serializes sequential writes to the repository', () async {
      mockRepository.delay = const Duration(milliseconds: 20);

      final container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWith(
            (ref) async => mockRepository,
          ),
        ],
      );
      addTearDown(container.dispose);

      // Keep the provider alive by listening to it
      final sub = container.listen(appSettingsProvider, (_, _) {});
      addTearDown(sub.close);

      await container.read(appSettingsProvider.future);
      final notifier = container.read(appSettingsProvider.notifier);

      // Trigger two updates concurrently
      final firstFuture = notifier.updateFontSize(1.5);
      final secondFuture = notifier.updateFontSize(2.0);

      // Immediately, state should be updated to the latest optimistic value (2.0)
      expect(
        container.read(appSettingsProvider).value?.mapFontSize,
        equals(2.0),
      );

      await Future.wait([firstFuture, secondFuture]);

      // Assert that repository calls were strictly serialized
      expect(
        mockRepository.logs,
        equals(['start_1.5', 'success_1.5', 'start_2.0', 'success_2.0']),
      );
    });

    test(
      'Handles failure by rolling back to repository settings on a single update',
      () async {
        final container = ProviderContainer(
          overrides: [
            settingsRepositoryProvider.overrideWith(
              (ref) async => mockRepository,
            ),
          ],
        );
        addTearDown(container.dispose);

        // Keep the provider alive by listening to it
        final sub = container.listen(appSettingsProvider, (_, _) {});
        addTearDown(sub.close);

        await container.read(appSettingsProvider.future);
        final notifier = container.read(appSettingsProvider.notifier);

        // Set repository to fail
        mockRepository.shouldThrow = true;

        final result = await notifier.updateFontSize(1.5);

        expect(result, isA<SettingsUpdateFailure>());

        // State should be AsyncError containing the last known repoSettings (1.0)
        final state = container.read(appSettingsProvider);
        expect(state, isA<AsyncError<AppSettings>>());
        expect(state.value?.mapFontSize, equals(1.0));
        expect(mockRepository.currentSettings.mapFontSize, equals(1.0));
      },
    );

    test(
      'Reconciles state on concurrent updates to prevent silent overwriting of newer updates',
      () async {
        mockRepository.delay = const Duration(milliseconds: 20);

        final container = ProviderContainer(
          overrides: [
            settingsRepositoryProvider.overrideWith(
              (ref) async => mockRepository,
            ),
          ],
        );
        addTearDown(container.dispose);

        // Keep the provider alive by listening to it
        final sub = container.listen(appSettingsProvider, (_, _) {});
        addTearDown(sub.close);

        await container.read(appSettingsProvider.future);
        final notifier = container.read(appSettingsProvider.notifier);

        // Configure mock to only fail for 1.5 update, but succeed for 2.0
        mockRepository.shouldThrowFor = (s) => s.mapFontSize == 1.5;

        final firstFuture = notifier.updateFontSize(1.5);
        final secondFuture = notifier.updateFontSize(2.0);

        // Optimistic state is 2.0
        expect(
          container.read(appSettingsProvider).value?.mapFontSize,
          equals(2.0),
        );

        final firstResult = await firstFuture;
        final secondResult = await secondFuture;

        expect(firstResult, isA<SettingsUpdateFailure>());
        expect(secondResult, isA<SettingsUpdateSuccess>());

        // Final state should be successfully set to 2.0 (not silently overwritten with 1.0)
        final state = container.read(appSettingsProvider);
        expect(state, isA<AsyncData<AppSettings>>());
        expect(state.value?.mapFontSize, equals(2.0));
        expect(mockRepository.currentSettings.mapFontSize, equals(2.0));
      },
    );

    test(
      'updateAutoSelectDevice triggers auto-selection and handles failures',
      () async {
        const device = CannelloniDevice(
          name: 'device1',
          hostname: 'host1',
          ip: '127.0.0.1',
          port: 1234,
        );

        final container = ProviderContainer(
          overrides: [
            settingsRepositoryProvider.overrideWith(
              (ref) async => mockRepository,
            ),
            discoveredDevicesProvider.overrideWith(
              (ref) => Stream.value([device]),
            ),
          ],
        );
        addTearDown(container.dispose);

        final sub = container.listen(appSettingsProvider, (_, _) {});
        addTearDown(sub.close);

        await container.read(appSettingsProvider.future);
        final notifier = container.read(appSettingsProvider.notifier);

        // Trigger updateAutoSelectDevice(true).
        // Since autoSelectDevice is turned on, it should immediately auto-select the discovered device.
        final result = await notifier.updateAutoSelectDevice(true);

        expect(result, isA<SettingsUpdateSuccess>());
        expect(
          container.read(appSettingsProvider).value?.autoSelectDevice,
          isTrue,
        );
        expect(
          container.read(appSettingsProvider).value?.selectedDevice,
          equals(device),
        );
      },
    );

    test(
      'updateAutoSelectDevice propagates inner failures from _tryAutoSelectDevice',
      () async {
        const device = CannelloniDevice(
          name: 'device1',
          hostname: 'host1',
          ip: '127.0.0.1',
          port: 1234,
        );

        final container = ProviderContainer(
          overrides: [
            settingsRepositoryProvider.overrideWith(
              (ref) async => mockRepository,
            ),
            discoveredDevicesProvider.overrideWith(
              (ref) => Stream.value([device]),
            ),
          ],
        );
        addTearDown(container.dispose);

        final sub = container.listen(appSettingsProvider, (_, _) {});
        addTearDown(sub.close);

        await container.read(appSettingsProvider.future);
        final notifier = container.read(appSettingsProvider.notifier);

        // Configure repository to fail when updating the selected device
        // (which happens in the second repository save call during auto-selection)
        mockRepository.shouldThrowFor = (settings) =>
            settings.selectedDevice != null;

        final result = await notifier.updateAutoSelectDevice(true);

        // It should return SettingsUpdateFailure because of the failed auto-selection update
        expect(result, isA<SettingsUpdateFailure>());
      },
    );

    test(
      'updateFlightSpeedMaxRange updates max range and clamps thresholds if necessary',
      () async {
        mockRepository.currentSettings = const AppSettings(
          flightSpeedMaxRange: 200.0,
          speedUnit: SpeedUnit.ms,
          flightSpeedThresholds: RangeThresholds.raw(
            inactiveMax: 10.0,
            minError: 60.0,
            minWarning: 75.0,
            maxWarning: 110.0,
            maxError: 125.0,
          ),
        );

        final container = ProviderContainer(
          overrides: [
            settingsRepositoryProvider.overrideWith(
              (ref) async => mockRepository,
            ),
          ],
        );
        addTearDown(container.dispose);

        final sub = container.listen(appSettingsProvider, (_, _) {});
        addTearDown(sub.close);

        await container.read(appSettingsProvider.future);
        final notifier = container.read(appSettingsProvider.notifier);

        // 1. Update to 150.0 (no clamping needed as all are <= 150)
        final result1 = await notifier.updateFlightSpeedMaxRange(150.0);
        expect(result1, isA<SettingsUpdateSuccess>());
        expect(
          container.read(appSettingsProvider).value?.flightSpeedMaxRange,
          equals(150.0),
        );
        expect(
          container
              .read(appSettingsProvider)
              .value
              ?.flightSpeedThresholds
              .maxError,
          equals(125.0),
        );

        // 2. Update to 100.0 (requires clamping maxError and maxWarning to 100.0)
        final result2 = await notifier.updateFlightSpeedMaxRange(100.0);
        expect(result2, isA<SettingsUpdateSuccess>());

        final currentSettings = container.read(appSettingsProvider).value!;
        expect(currentSettings.flightSpeedMaxRange, equals(100.0));
        expect(currentSettings.flightSpeedThresholds.maxError, equals(100.0));
        expect(currentSettings.flightSpeedThresholds.maxWarning, equals(100.0));
        expect(currentSettings.flightSpeedThresholds.minWarning, equals(75.0));
        expect(currentSettings.flightSpeedThresholds.minError, equals(60.0));
        expect(currentSettings.flightSpeedThresholds.inactiveMax, equals(10.0));

        // 3. Update to 50.0 (clamps everything except inactiveMax to 50.0)
        final result3 = await notifier.updateFlightSpeedMaxRange(50.0);
        expect(result3, isA<SettingsUpdateSuccess>());

        final finalSettings = container.read(appSettingsProvider).value!;
        expect(finalSettings.flightSpeedMaxRange, equals(50.0));
        expect(finalSettings.flightSpeedThresholds.maxError, equals(50.0));
        expect(finalSettings.flightSpeedThresholds.maxWarning, equals(50.0));
        expect(finalSettings.flightSpeedThresholds.minWarning, equals(50.0));
        expect(finalSettings.flightSpeedThresholds.minError, equals(50.0));
        expect(finalSettings.flightSpeedThresholds.inactiveMax, equals(10.0));
      },
    );

    test(
      'updateFlightSpeedMaxRange defensive validation for invalid/NaN/infinite/negative values',
      () async {
        mockRepository.currentSettings = const AppSettings(
          flightSpeedMaxRange: 200.0,
          speedUnit: SpeedUnit.ms,
          flightSpeedThresholds: RangeThresholds.raw(
            inactiveMax: 10.0,
            minError: 60.0,
            minWarning: 75.0,
            maxWarning: 110.0,
            maxError: 125.0,
          ),
        );

        final container = ProviderContainer(
          overrides: [
            settingsRepositoryProvider.overrideWith(
              (ref) async => mockRepository,
            ),
          ],
        );
        addTearDown(container.dispose);

        final sub = container.listen(appSettingsProvider, (_, _) {});
        addTearDown(sub.close);

        await container.read(appSettingsProvider.future);
        final notifier = container.read(appSettingsProvider.notifier);

        // NaN should fallback to default (38.89)
        final resNaN = await notifier.updateFlightSpeedMaxRange(double.nan);
        expect(resNaN, isA<SettingsUpdateSuccess>());
        expect(
          container.read(appSettingsProvider).value?.flightSpeedMaxRange,
          equals(38.89),
        );

        // Infinite should fallback to default (38.89)
        final resInf = await notifier.updateFlightSpeedMaxRange(
          double.infinity,
        );
        expect(resInf, isA<SettingsUpdateSuccess>());
        expect(
          container.read(appSettingsProvider).value?.flightSpeedMaxRange,
          equals(38.89),
        );

        // Zero should fallback to default (38.89)
        final resZero = await notifier.updateFlightSpeedMaxRange(0.0);
        expect(resZero, isA<SettingsUpdateSuccess>());
        expect(
          container.read(appSettingsProvider).value?.flightSpeedMaxRange,
          equals(38.89),
        );

        // Negative should fallback to default (38.89)
        final resNeg = await notifier.updateFlightSpeedMaxRange(-50.0);
        expect(resNeg, isA<SettingsUpdateSuccess>());
        expect(
          container.read(appSettingsProvider).value?.flightSpeedMaxRange,
          equals(38.89),
        );

        // Values below 10.0 should clamp to 10.0
        final resTooSmall = await notifier.updateFlightSpeedMaxRange(5.0);
        expect(resTooSmall, isA<SettingsUpdateSuccess>());
        expect(
          container.read(appSettingsProvider).value?.flightSpeedMaxRange,
          equals(10.0),
        );

        // Values above 1000.0 should clamp to 1000.0
        final resTooLarge = await notifier.updateFlightSpeedMaxRange(1500.0);
        expect(resTooLarge, isA<SettingsUpdateSuccess>());
        expect(
          container.read(appSettingsProvider).value?.flightSpeedMaxRange,
          equals(1000.0),
        );
      },
    );

    test('resetWidgetPositions clears all saved widget positions', () async {
      mockRepository.currentSettings = const AppSettings(
        widgetPositions: {
          'speed_widget': WidgetPosition(top: 100.0, left: 200.0),
        },
      );

      final container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWith(
            (ref) async => mockRepository,
          ),
        ],
      );
      addTearDown(container.dispose);

      final sub = container.listen(appSettingsProvider, (_, _) {});
      addTearDown(sub.close);

      await container.read(appSettingsProvider.future);
      final notifier = container.read(appSettingsProvider.notifier);

      expect(
        container.read(appSettingsProvider).value?.widgetPositions,
        isNotEmpty,
      );

      final result = await notifier.resetWidgetPositions();
      expect(result, isA<SettingsUpdateSuccess>());
      expect(
        container.read(appSettingsProvider).value?.widgetPositions,
        isEmpty,
      );
      expect(mockRepository.currentSettings.widgetPositions, isEmpty);
    });

    test(
      'updateAutoQnh modifies the autoQnh setting and persists it',
      () async {
        final container = ProviderContainer(
          overrides: [
            settingsRepositoryProvider.overrideWith(
              (ref) async => mockRepository,
            ),
          ],
        );
        addTearDown(container.dispose);

        final sub = container.listen(appSettingsProvider, (_, _) {});
        addTearDown(sub.close);

        await container.read(appSettingsProvider.future);
        final notifier = container.read(appSettingsProvider.notifier);

        expect(container.read(appSettingsProvider).value?.autoQnh, isTrue);

        final result = await notifier.updateAutoQnh(false);
        expect(result, isA<SettingsUpdateSuccess>());
        expect(container.read(appSettingsProvider).value?.autoQnh, isFalse);
        expect(mockRepository.currentSettings.autoQnh, isFalse);
      },
    );

    test('updateQnh modifies the qnh setting and persists it', () async {
      final container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWith(
            (ref) async => mockRepository,
          ),
        ],
      );
      addTearDown(container.dispose);

      final sub = container.listen(appSettingsProvider, (_, _) {});
      addTearDown(sub.close);

      await container.read(appSettingsProvider.future);
      final notifier = container.read(appSettingsProvider.notifier);

      expect(container.read(appSettingsProvider).value?.qnh, equals(1013.25));

      final result = await notifier.updateQnh(1020.5);
      expect(result, isA<SettingsUpdateSuccess>());
      expect(container.read(appSettingsProvider).value?.qnh, equals(1020.5));
      expect(mockRepository.currentSettings.qnh, equals(1020.5));
    });

    test(
      'updateQnh defensive validation for invalid/NaN/infinite/negative/out-of-range values',
      () async {
        final container = ProviderContainer(
          overrides: [
            settingsRepositoryProvider.overrideWith(
              (ref) async => mockRepository,
            ),
          ],
        );
        addTearDown(container.dispose);

        final sub = container.listen(appSettingsProvider, (_, _) {});
        addTearDown(sub.close);

        await container.read(appSettingsProvider.future);
        final notifier = container.read(appSettingsProvider.notifier);

        // NaN should fallback to default (AviationMath.standardPressureHpa)
        final resNaN = await notifier.updateQnh(double.nan);
        expect(resNaN, isA<SettingsUpdateSuccess>());
        expect(
          container.read(appSettingsProvider).value?.qnh,
          equals(AviationMath.standardPressureHpa),
        );
        expect(mockRepository.currentSettings.qnh, equals(AviationMath.standardPressureHpa));

        // Infinite should fallback to default (AviationMath.standardPressureHpa)
        final resInf = await notifier.updateQnh(double.infinity);
        expect(resInf, isA<SettingsUpdateSuccess>());
        expect(
          container.read(appSettingsProvider).value?.qnh,
          equals(AviationMath.standardPressureHpa),
        );
        expect(mockRepository.currentSettings.qnh, equals(AviationMath.standardPressureHpa));

        // Negative infinity should fallback to default (AviationMath.standardPressureHpa)
        final resNegInf = await notifier.updateQnh(double.negativeInfinity);
        expect(resNegInf, isA<SettingsUpdateSuccess>());
        expect(
          container.read(appSettingsProvider).value?.qnh,
          equals(AviationMath.standardPressureHpa),
        );
        expect(mockRepository.currentSettings.qnh, equals(AviationMath.standardPressureHpa));

        // Zero should fallback to default (AviationMath.standardPressureHpa)
        final resZero = await notifier.updateQnh(0.0);
        expect(resZero, isA<SettingsUpdateSuccess>());
        expect(
          container.read(appSettingsProvider).value?.qnh,
          equals(AviationMath.standardPressureHpa),
        );
        expect(mockRepository.currentSettings.qnh, equals(AviationMath.standardPressureHpa));

        // Negative should fallback to default (AviationMath.standardPressureHpa)
        final resNeg = await notifier.updateQnh(-50.0);
        expect(resNeg, isA<SettingsUpdateSuccess>());
        expect(
          container.read(appSettingsProvider).value?.qnh,
          equals(AviationMath.standardPressureHpa),
        );
        expect(mockRepository.currentSettings.qnh, equals(AviationMath.standardPressureHpa));

        // Out-of-range low value should clamp to AviationMath.minQnhHpa
        final resTooSmall = await notifier.updateQnh(AviationMath.minQnhHpa - 0.1);
        expect(resTooSmall, isA<SettingsUpdateSuccess>());
        expect(
          container.read(appSettingsProvider).value?.qnh,
          equals(AviationMath.minQnhHpa),
        );
        expect(mockRepository.currentSettings.qnh, equals(AviationMath.minQnhHpa));

        // Out-of-range high value should clamp to AviationMath.maxQnhHpa
        final resTooLarge = await notifier.updateQnh(AviationMath.maxQnhHpa + 0.1);
        expect(resTooLarge, isA<SettingsUpdateSuccess>());
        expect(
          container.read(appSettingsProvider).value?.qnh,
          equals(AviationMath.maxQnhHpa),
        );
        expect(mockRepository.currentSettings.qnh, equals(AviationMath.maxQnhHpa));
      },
    );

    test('updateAverageSpeed modifies the averageSpeed setting and persists it', () async {
      mockRepository.currentSettings = mockRepository.currentSettings.copyWith(
        speedUnit: SpeedUnit.kmh,
      );

      final container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWith(
            (ref) async => mockRepository,
          ),
        ],
      );
      addTearDown(container.dispose);

      final sub = container.listen(appSettingsProvider, (_, _) {});
      addTearDown(sub.close);

      await container.read(appSettingsProvider.future);
      final notifier = container.read(appSettingsProvider.notifier);

      final speedUnit = container.read(appSettingsProvider).value!.speedUnit;
      final expectedSpeedMs = speedUnit.convertToMs(36.0);

      final result = await notifier.updateAverageSpeed(36.0);
      expect(result, isA<SettingsUpdateSuccess>());
      expect(container.read(appSettingsProvider).value?.averageSpeed, equals(expectedSpeedMs));
      expect(mockRepository.currentSettings.averageSpeed, equals(expectedSpeedMs));
    });

    test(
      'updateAverageSpeed defensive validation for invalid/NaN/infinite/negative/zero values',
      () async {
        mockRepository.currentSettings = mockRepository.currentSettings.copyWith(
          speedUnit: SpeedUnit.kmh,
        );

        final container = ProviderContainer(
          overrides: [
            settingsRepositoryProvider.overrideWith(
              (ref) async => mockRepository,
            ),
          ],
        );
        addTearDown(container.dispose);

        final sub = container.listen(appSettingsProvider, (_, _) {});
        addTearDown(sub.close);

        await container.read(appSettingsProvider.future);
        final notifier = container.read(appSettingsProvider.notifier);

        final speedUnit = container.read(appSettingsProvider).value!.speedUnit;
        final expectedMinMs = speedUnit.convertToMs(0.001);

        final resNaN = await notifier.updateAverageSpeed(double.nan);
        expect(resNaN, isA<SettingsUpdateSuccess>());
        expect(
          container.read(appSettingsProvider).value?.averageSpeed,
          closeTo(expectedMinMs, 1e-9),
        );
        expect(mockRepository.currentSettings.averageSpeed, closeTo(expectedMinMs, 1e-9));

        final resInf = await notifier.updateAverageSpeed(double.infinity);
        expect(resInf, isA<SettingsUpdateSuccess>());
        expect(
          container.read(appSettingsProvider).value?.averageSpeed,
          closeTo(expectedMinMs, 1e-9),
        );

        final resZero = await notifier.updateAverageSpeed(0.0);
        expect(resZero, isA<SettingsUpdateSuccess>());
        expect(
          container.read(appSettingsProvider).value?.averageSpeed,
          closeTo(expectedMinMs, 1e-9),
        );

        final resNeg = await notifier.updateAverageSpeed(-10.0);
        expect(resNeg, isA<SettingsUpdateSuccess>());
        expect(
          container.read(appSettingsProvider).value?.averageSpeed,
          closeTo(expectedMinMs, 1e-9),
        );

        final resValidSmall = await notifier.updateAverageSpeed(0.005);
        expect(resValidSmall, isA<SettingsUpdateSuccess>());
        expect(
          container.read(appSettingsProvider).value?.averageSpeed,
          closeTo(speedUnit.convertToMs(0.005), 1e-9),
        );
      },
    );
  });
}
