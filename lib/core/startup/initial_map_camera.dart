import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre/maplibre.dart';
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
    final lat = telemetry.latitude;
    final lon = telemetry.longitude;
    final valid =
        lat != null &&
        lon != null &&
        lat.isFinite &&
        lon.isFinite &&
        lat.abs() <= 90 &&
        lon.abs() <= 180 &&
        (lat != 0 || lon != 0);
    final following = valid && telemetry.mapViewState == MapViewState.follow;
    return InitialMapCamera(
      center: valid
          ? Geographic(lat: lat, lon: lon)
          : lastKnownPosition ?? const Geographic(lat: 48.15, lon: 17.11),
      zoom: following
          ? settings.mapFollowZoom
          : valid && telemetry.mapViewState == MapViewState.overview
          ? settings.mapOverviewZoom
          : settings.mapDefaultZoom,
      pitch: following ? settings.mapFollowPitch : 0,
      bearing: following ? telemetry.heading ?? 0 : 0,
      hasLocation: valid || lastKnownPosition != null,
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
