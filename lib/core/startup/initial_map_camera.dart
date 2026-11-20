import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre/maplibre.dart';

import '../utils/geo_utils.dart';
import '../../features/settings/domain/models/app_settings.dart';
import '../../features/telemetry/domain/models/map_view_state.dart';
import '../../features/telemetry/domain/models/telemetry_state.dart';

class InitialMapCamera {
  const InitialMapCamera({
    required this.center,
    required this.zoom,
    this.pitch = 0,
    this.bearing = 0,
    this.hasLocation = false,
  });

  factory InitialMapCamera.fromTelemetry(
    TelemetryState telemetry,
    AppSettings settings, {
    Geographic? lastKnownPosition,
  }) {
    final live = GeoUtils.validatedPosition(
      telemetry.latitude,
      telemetry.longitude,
    );
    final known = GeoUtils.validatedPosition(
      lastKnownPosition?.lat,
      lastKnownPosition?.lon,
    );
    final valid = live != null;
    final following = valid && telemetry.mapViewState == MapViewState.follow;
    return InitialMapCamera(
      center: valid ? live : known ?? const Geographic(lat: 48.15, lon: 17.11),
      zoom: following
          ? settings.mapFollowZoom
          : valid && telemetry.mapViewState == MapViewState.overview
          ? settings.mapOverviewZoom
          : settings.mapDefaultZoom,
      pitch: following ? settings.mapFollowPitch : 0,
      bearing: following ? telemetry.heading ?? 0 : 0,
      hasLocation: valid || known != null,
    );
  }

  final Geographic center;
  final double zoom;
  final double pitch;
  final double bearing;
  final bool hasLocation;
}

final initialMapCameraProvider =
    NotifierProvider<InitialMapCameraController, InitialMapCamera?>(
      InitialMapCameraController.new,
    );

class InitialMapCameraController extends Notifier<InitialMapCamera?> {
  @override
  InitialMapCamera? build() => null;

  void prepare(InitialMapCamera camera) => state = camera;
}
