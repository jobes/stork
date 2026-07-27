import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stork/features/settings/domain/models/app_settings.dart';
import 'package:stork/features/settings/presentation/providers/settings_provider.dart';
import 'package:stork/features/telemetry/data/ogn_aprs_service.dart';
import 'package:stork/features/telemetry/presentation/providers/ogn_traffic_provider.dart';
import 'package:stork/features/telemetry/presentation/providers/telemetry_provider.dart';

void main() {
  group('filteredOgnTrafficProvider Tests', () {
    final now = DateTime.now();
    const myPosLat = 48.1486;
    const myPosLon = 17.1077;
    const myAltMeters = 500.0;

    // Aircraft 1: Close (1 km away, alt 600m => 100m vertical diff)
    final nearAircraft = OgnTrafficAircraft(
      id: 'NEAR01',
      callsign: 'NEAR1',
      latitude: 48.1576,
      longitude: 17.1077,
      altitude: 600,
      track: 90,
      groundSpeed: 20,
      verticalSpeed: 0,
      aircraftType: 1,
      lastSeen: now,
    );

    // Aircraft 2: Far horizontally (100 km away)
    final farHorizontalAircraft = OgnTrafficAircraft(
      id: 'FARHORIZ',
      callsign: 'FAR1',
      latitude: 49.0486,
      longitude: 17.1077,
      altitude: 500,
      track: 90,
      groundSpeed: 20,
      verticalSpeed: 0,
      aircraftType: 1,
      lastSeen: now,
    );

    // Aircraft 3: Far vertically (altitude 3000m => 2500m diff)
    final farVerticalAircraft = OgnTrafficAircraft(
      id: 'FARVERT0',
      callsign: 'FAR2',
      latitude: 48.1486,
      longitude: 17.1077,
      altitude: 3000,
      track: 90,
      groundSpeed: 20,
      verticalSpeed: 0,
      aircraftType: 1,
      lastSeen: now,
    );

    test('returns all traffic if filters disabled', () {
      final container = ProviderContainer(
        overrides: [
          ognTrafficProvider.overrideWith(
            () => _MockOgnTraffic([
              nearAircraft,
              farHorizontalAircraft,
              farVerticalAircraft,
            ]),
          ),
          appSettingsProvider.overrideWith(
            () => _MockAppSettingsNotifier(
              const AppSettings(
                trafficFilterMaxHorizontalDistanceEnabled: false,
                trafficFilterMaxVerticalDistanceEnabled: false,
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final filtered = container.read(filteredOgnTrafficProvider);
      expect(filtered.length, equals(3));
    });

    test(
      'filters out aircraft exceeding max horizontal or vertical distance',
      () {
        final container = ProviderContainer(
          overrides: [
            ognTrafficProvider.overrideWith(
              () => _MockOgnTraffic([
                nearAircraft,
                farHorizontalAircraft,
                farVerticalAircraft,
              ]),
            ),
            appSettingsProvider.overrideWith(
              () => _MockAppSettingsNotifier(
                const AppSettings(
                  trafficFilterMaxHorizontalDistanceEnabled: true,
                  trafficMaxHorizontalDistance: 50000.0, // 50 km
                  trafficFilterMaxVerticalDistanceEnabled: true,
                  trafficMaxVerticalDistance: 1500.0, // 1.5 km
                ),
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        // Set user location and altitude
        container
            .read(telemetryProvider.notifier)
            .updateGPS(
              latitude: myPosLat,
              longitude: myPosLon,
              gpsAltitude: myAltMeters,
            );

        final filtered = container.read(filteredOgnTrafficProvider);
        expect(filtered.length, equals(1));
        expect(filtered.first.id, equals('NEAR01'));
      },
    );
  });
}

class _MockOgnTraffic extends OgnTraffic {
  final List<OgnTrafficAircraft> initialTraffic;
  _MockOgnTraffic(this.initialTraffic);

  @override
  List<OgnTrafficAircraft> build() {
    return initialTraffic;
  }
}

class _MockAppSettingsNotifier extends AppSettingsNotifier {
  final AppSettings initialSettings;
  _MockAppSettingsNotifier(this.initialSettings);

  @override
  AppSettings build() {
    return initialSettings;
  }
}
