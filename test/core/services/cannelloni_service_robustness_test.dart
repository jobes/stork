import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stork/core/services/cannelloni_service_io.dart';
import 'package:stork/features/settings/domain/models/cannelloni_device.dart';
import 'package:stork/features/settings/presentation/providers/settings_provider.dart';
import 'package:stork/features/settings/data/repositories/settings_repository.dart';
import 'package:stork/core/services/mdns_service.dart';
import 'package:stork/features/settings/domain/models/app_settings.dart';

class MockSettingsRepository implements SettingsRepository {
  AppSettings currentSettings;
  MockSettingsRepository(this.currentSettings);

  @override
  Future<AppSettings> getSettings() async => currentSettings;

  @override
  Future<void> saveSettings(AppSettings settings) async {
    currentSettings = settings;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TestCannelloniService extends CannelloniService {
  @override
  bool build() {
    state = false;
    return false;
  }
}

void main() {
  group('CannelloniService Robustness Tests', () {
    late MockSettingsRepository mockRepo;
    late CannelloniDevice testDevice;

    setUp(() {
      testDevice = const CannelloniDevice(
        name: 'Test Device',
        hostname: 'TestDevice',
        ip: '127.0.0.1',
        port: 1234,
      );
      mockRepo = MockSettingsRepository(
        AppSettings(selectedDevice: testDevice),
      );
    });

    test(
      'Selected device not in discovered list remains connected if receiving data',
      () async {
        final container = ProviderContainer(
          overrides: [
            settingsRepositoryProvider.overrideWith((ref) => mockRepo),
            cannelloniServiceProvider.overrideWith(
              () => TestCannelloniService(),
            ),
            discoveredDevicesProvider.overrideWith(
              (ref) => Stream.value(<CannelloniDevice>[]),
            ),
          ],
        );
        addTearDown(container.dispose);

        // Wait for providers to be loaded
        await container.read(appSettingsProvider.future);
        await container.read(discoveredDevicesProvider.future);

        final service =
            container.read(cannelloniServiceProvider.notifier)
                as TestCannelloniService;

        final socket = await RawDatagramSocket.bind(
          InternetAddress.loopbackIPv4,
          0,
        );
        service.socketForTesting = socket;
        service.state = true;
        service.lastDataReceivedTimeForTesting = DateTime.now();

        service.updateConnectionForTesting();

        // The connection should NOT disconnect because lastDataReceivedTime is recent.
        expect(service.state, isTrue);
        expect(service.disconnectTimerForTesting, isNotNull);

        socket.close();
      },
    );

    test(
      'Selected device not in discovered list disconnects if no data received recently',
      () async {
        final container = ProviderContainer(
          overrides: [
            settingsRepositoryProvider.overrideWith((ref) => mockRepo),
            cannelloniServiceProvider.overrideWith(
              () => TestCannelloniService(),
            ),
            discoveredDevicesProvider.overrideWith(
              (ref) => Stream.value(<CannelloniDevice>[]),
            ),
          ],
        );
        addTearDown(container.dispose);

        // Wait for providers to be loaded
        await container.read(appSettingsProvider.future);
        await container.read(discoveredDevicesProvider.future);

        final service =
            container.read(cannelloniServiceProvider.notifier)
                as TestCannelloniService;

        final socket = await RawDatagramSocket.bind(
          InternetAddress.loopbackIPv4,
          0,
        );
        service.socketForTesting = socket;
        service.state = true;
        // Set last data received time to more than 3000ms ago
        service.lastDataReceivedTimeForTesting = DateTime.now().subtract(
          const Duration(seconds: 4),
        );

        service.updateConnectionForTesting();

        // The connection should disconnect immediately
        expect(service.state, isFalse);
        expect(service.socketForTesting, isNull);
        expect(service.disconnectTimerForTesting, isNull);

        socket.close();
      },
    );
  });
}
