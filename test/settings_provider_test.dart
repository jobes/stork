import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stork/core/services/mdns_service.dart';
import 'package:stork/features/settings/domain/cannelloni_device.dart';
import 'package:stork/features/settings/data/repositories/settings_repository.dart';
import 'package:stork/features/settings/domain/app_settings.dart';
import 'package:stork/features/settings/presentation/providers/settings_provider.dart';

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
          settingsRepositoryProvider.overrideWith((ref) async => mockRepository),
        ],
      );
      addTearDown(container.dispose);

      // Keep the provider alive by listening to it
      final sub = container.listen(appSettingsProvider, (_, __) {});
      addTearDown(sub.close);

      // Wait for provider to build/load
      final initialSettings = await container.read(appSettingsProvider.future);
      expect(initialSettings.mapFontSize, equals(1.0));

      final notifier = container.read(appSettingsProvider.notifier);
      final result = await notifier.updateFontSize(1.5);

      expect(result, isA<SettingsUpdateSuccess>());
      expect(container.read(appSettingsProvider).value?.mapFontSize, equals(1.5));
      expect(mockRepository.currentSettings.mapFontSize, equals(1.5));
    });

    test('Serializes sequential writes to the repository', () async {
      mockRepository.delay = const Duration(milliseconds: 20);
      
      final container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWith((ref) async => mockRepository),
        ],
      );
      addTearDown(container.dispose);

      // Keep the provider alive by listening to it
      final sub = container.listen(appSettingsProvider, (_, __) {});
      addTearDown(sub.close);

      await container.read(appSettingsProvider.future);
      final notifier = container.read(appSettingsProvider.notifier);

      // Trigger two updates concurrently
      final firstFuture = notifier.updateFontSize(1.5);
      final secondFuture = notifier.updateFontSize(2.0);

      // Immediately, state should be updated to the latest optimistic value (2.0)
      expect(container.read(appSettingsProvider).value?.mapFontSize, equals(2.0));

      await Future.wait([firstFuture, secondFuture]);

      // Assert that repository calls were strictly serialized
      expect(
        mockRepository.logs,
        equals([
          'start_1.5',
          'success_1.5',
          'start_2.0',
          'success_2.0',
        ]),
      );
    });

    test('Handles failure by rolling back to repository settings on a single update', () async {
      final container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWith((ref) async => mockRepository),
        ],
      );
      addTearDown(container.dispose);

      // Keep the provider alive by listening to it
      final sub = container.listen(appSettingsProvider, (_, __) {});
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
    });

    test('Reconciles state on concurrent updates to prevent silent overwriting of newer updates', () async {
      mockRepository.delay = const Duration(milliseconds: 20);

      final container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWith((ref) async => mockRepository),
        ],
      );
      addTearDown(container.dispose);

      // Keep the provider alive by listening to it
      final sub = container.listen(appSettingsProvider, (_, __) {});
      addTearDown(sub.close);

      await container.read(appSettingsProvider.future);
      final notifier = container.read(appSettingsProvider.notifier);

      // Configure mock to only fail for 1.5 update, but succeed for 2.0
      mockRepository.shouldThrowFor = (s) => s.mapFontSize == 1.5;

      final firstFuture = notifier.updateFontSize(1.5);
      final secondFuture = notifier.updateFontSize(2.0);

      // Optimistic state is 2.0
      expect(container.read(appSettingsProvider).value?.mapFontSize, equals(2.0));

      final firstResult = await firstFuture;
      final secondResult = await secondFuture;

      expect(firstResult, isA<SettingsUpdateFailure>());
      expect(secondResult, isA<SettingsUpdateSuccess>());

      // Final state should be successfully set to 2.0 (not silently overwritten with 1.0)
      final state = container.read(appSettingsProvider);
      expect(state, isA<AsyncData<AppSettings>>());
      expect(state.value?.mapFontSize, equals(2.0));
      expect(mockRepository.currentSettings.mapFontSize, equals(2.0));
    });

    test('updateAutoSelectDevice triggers auto-selection and handles failures', () async {
      const device = CannelloniDevice(
        name: 'device1',
        hostname: 'host1',
        ip: '127.0.0.1',
        port: 1234,
      );

      final container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWith((ref) async => mockRepository),
          discoveredDevicesProvider.overrideWith((ref) => Stream.value([device])),
        ],
      );
      addTearDown(container.dispose);

      final sub = container.listen(appSettingsProvider, (_, __) {});
      addTearDown(sub.close);

      await container.read(appSettingsProvider.future);
      final notifier = container.read(appSettingsProvider.notifier);

      // Trigger updateAutoSelectDevice(true).
      // Since autoSelectDevice is turned on, it should immediately auto-select the discovered device.
      final result = await notifier.updateAutoSelectDevice(true);

      expect(result, isA<SettingsUpdateSuccess>());
      expect(container.read(appSettingsProvider).value?.autoSelectDevice, isTrue);
      expect(container.read(appSettingsProvider).value?.selectedDevice, equals(device));
    });

    test('updateAutoSelectDevice propagates inner failures from _tryAutoSelectDevice', () async {
      const device = CannelloniDevice(
        name: 'device1',
        hostname: 'host1',
        ip: '127.0.0.1',
        port: 1234,
      );

      final container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWith((ref) async => mockRepository),
          discoveredDevicesProvider.overrideWith((ref) => Stream.value([device])),
        ],
      );
      addTearDown(container.dispose);

      final sub = container.listen(appSettingsProvider, (_, __) {});
      addTearDown(sub.close);

      await container.read(appSettingsProvider.future);
      final notifier = container.read(appSettingsProvider.notifier);

      // Configure repository to fail when updating the selected device
      // (which happens in the second repository save call during auto-selection)
      mockRepository.shouldThrowFor = (settings) => settings.selectedDevice != null;

      final result = await notifier.updateAutoSelectDevice(true);

      // It should return SettingsUpdateFailure because of the failed auto-selection update
      expect(result, isA<SettingsUpdateFailure>());
    });
  });
}
