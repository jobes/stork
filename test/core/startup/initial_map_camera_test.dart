import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre/maplibre.dart';
import 'package:stork/core/startup/initial_map_camera.dart';
import 'package:stork/features/settings/domain/models/app_settings.dart';
import 'package:stork/features/telemetry/domain/models/map_view_state.dart';
import 'package:stork/features/telemetry/domain/models/telemetry_state.dart';

void main() {
  for (final invalid in [
    Geographic(lat: double.nan, lon: 17),
    const Geographic(lat: 0, lon: 0),
  ]) {
    test('invalid last-known position falls back: $invalid', () {
      final camera = InitialMapCamera.fromTelemetry(
        const TelemetryState(),
        const AppSettings(),
        lastKnownPosition: invalid,
      );
      expect(camera.hasLocation, isFalse);
      expect(camera.center, const Geographic(lat: 48.15, lon: 17.11));
    });
  }

  test('current telemetry wins over the startup fallback on map reentry', () {
    final camera = InitialMapCamera.fromTelemetry(
      const TelemetryState(
        latitude: 49,
        longitude: 18,
        heading: 120,
        mapViewState: MapViewState.follow,
      ),
      const AppSettings(mapFollowZoom: 13, mapFollowPitch: 25),
      lastKnownPosition: const Geographic(lat: 48, lon: 17),
    );
    expect(camera.center, const Geographic(lat: 49, lon: 18));
    expect((camera.zoom, camera.pitch, camera.bearing), (13, 25, 120));
  });

  test('a coordinate on the equator is valid for the initial camera', () {
    final camera = InitialMapCamera.fromTelemetry(
      const TelemetryState(latitude: 0, longitude: 17),
      const AppSettings(),
    );
    expect(camera.center, const Geographic(lat: 0, lon: 17));
    expect(camera.hasLocation, isTrue);
  });

  test('missing telemetry uses the local position without a world view', () {
    final camera = InitialMapCamera.fromTelemetry(
      const TelemetryState(),
      const AppSettings(mapDefaultZoom: 7),
      lastKnownPosition: const Geographic(lat: 48, lon: 17),
    );
    expect(camera.center, const Geographic(lat: 48, lon: 17));
    expect(camera.zoom, 7);
    final fallback = InitialMapCamera.fromTelemetry(
      const TelemetryState(),
      const AppSettings(),
    );
    expect(fallback.hasLocation, isFalse);
    expect(fallback.center, const Geographic(lat: 48.15, lon: 17.11));
  });
}
