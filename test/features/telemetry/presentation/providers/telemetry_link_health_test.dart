import 'package:clock/clock.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stork/core/services/cannelloni_service.dart';
import 'package:stork/features/settings/domain/models/app_settings.dart';
import 'package:stork/features/settings/domain/models/cannelloni_device.dart';
import 'package:stork/features/settings/presentation/providers/settings_provider.dart';
import 'package:stork/features/telemetry/presentation/providers/telemetry_link_health_provider.dart';
import 'package:stork/features/telemetry/presentation/providers/telemetry_provider.dart';

class _Settings extends AppSettingsNotifier {
  @override
  AppSettings build() => const AppSettings(
    selectedDevice: CannelloniDevice(
      name: 'Test gateway',
      hostname: 'test.local',
      ip: '192.0.2.1',
      port: 2000,
    ),
  );
}

class _Gateway extends CannelloniService {
  @override
  DateTime? lastTelemetryActivityAt;

  @override
  bool build() {
    lastTelemetryActivityAt = clock.now();
    return true;
  }
}

class _Telemetry extends TelemetryNotifier {
  @override
  TelemetryState build() => const TelemetryState();
}

void main() {
  test('phone telemetry does not refresh the DroneCAN link', () {
    fakeAsync((async) {
      final container = ProviderContainer.test(
        overrides: [
          appSettingsProvider.overrideWith(_Settings.new),
          cannelloniServiceProvider.overrideWith(_Gateway.new),
          telemetryProvider.overrideWith(_Telemetry.new),
        ],
      );
      container.listen(telemetryLinkHealthProvider, (_, _) {});
      final health = container.read(telemetryLinkHealthProvider.notifier);

      async.elapse(TelemetryLinkHealth.staleAfter);
      container.read(telemetryProvider.notifier).updateGPS(heading: 90.0);
      health.refresh();
      expect(container.read(telemetryLinkHealthProvider).stale, isTrue);

      final gateway =
          container.read(cannelloniServiceProvider.notifier) as _Gateway;
      gateway.lastTelemetryActivityAt = clock.now();
      health.refresh();
      expect(container.read(telemetryLinkHealthProvider).stale, isFalse);
    });
  });

  group('shouldReportTelemetryLinkLost', () {
    test('does not report a link that was never established', () {
      expect(
        shouldReportTelemetryLinkLost(
          hasEverConnected: false,
          isConnected: false,
        ),
        isFalse,
      );
    });

    test('reports a link that was established and is now lost', () {
      expect(
        shouldReportTelemetryLinkLost(
          hasEverConnected: true,
          isConnected: false,
        ),
        isTrue,
      );
    });

    test('does not report a healthy link', () {
      expect(
        shouldReportTelemetryLinkLost(
          hasEverConnected: true,
          isConnected: true,
        ),
        isFalse,
      );
    });
  });

  group('isTelemetryStale', () {
    final now = DateTime.utc(2026, 11, 11, 12);

    test('is false while data is fresh', () {
      expect(
        isTelemetryStale(
          now: now,
          isConnected: true,
          lastDataAt: now.subtract(const Duration(seconds: 5)),
        ),
        isFalse,
      );
    });

    test('is true when the link is up but data stops arriving', () {
      expect(
        isTelemetryStale(
          now: now,
          isConnected: true,
          lastDataAt: now.subtract(TelemetryLinkHealth.staleAfter),
        ),
        isTrue,
      );
    });

    test(
      'is false when the link is down, which a lost link reports instead',
      () {
        expect(
          isTelemetryStale(
            now: now,
            isConnected: false,
            lastDataAt: now.subtract(const Duration(minutes: 5)),
          ),
          isFalse,
        );
      },
    );

    test('is false when no data was ever received', () {
      expect(
        isTelemetryStale(now: now, isConnected: true, lastDataAt: null),
        isFalse,
      );
    });
  });
}
