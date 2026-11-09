part of 'map_camera_provider.dart';

extension MapCameraInterpolation on MapCamera {
  void _startLinearInterpolation({
    required Geographic targetCenter,
    required double targetZoom,
    required double targetPitch,
    required double targetBearing,
    required Duration duration,
  }) {
    _stopInterpolation();

    final startCamera = _mapController?.camera;
    if (startCamera == null) return;

    final startCenter = _currentInterpolatedCenter ?? startCamera.center;
    final startZoom = _currentInterpolatedZoom ?? startCamera.zoom;
    final startPitch = _currentInterpolatedPitch ?? startCamera.pitch;
    final startBearing = _currentInterpolatedBearing ?? startCamera.bearing;

    _currentInterpolatedCenter = startCenter;
    _currentInterpolatedZoom = startZoom;
    _currentInterpolatedPitch = startPitch;
    _currentInterpolatedBearing = startBearing;

    final totalMs = duration.inMilliseconds <= 0 ? 1 : duration.inMilliseconds;

    // At flight zooms the overlays move little between display frames, but
    // every GeoJSON update queues work for the Android map renderer.
    final overlayInterval =
        !kIsWeb &&
            defaultTargetPlatform == TargetPlatform.android &&
            startZoom <= 13 &&
            targetZoom <= 13
        ? const Duration(milliseconds: 30)
        : Duration.zero;
    Duration? lastOverlayUpdate;
    var courseAtTarget = false;

    // Keep the camera synchronized with the display even when skipping an
    // overlay update.
    _interpolationTicker = Ticker((elapsed) {
      if (!refAccess.mounted || _mapController == null) {
        _stopInterpolation();
        return;
      }

      // Progress in [0, 1].
      final t = elapsed.inMilliseconds / totalMs;
      final progress = t >= 1.0 ? 1.0 : t;

      // Linear interpolation for camera
      final lat = _interpolateLinear(
        startCenter.lat,
        targetCenter.lat,
        progress,
      );
      final lon = _interpolateLinear(
        startCenter.lon,
        targetCenter.lon,
        progress,
      );
      final zoom = _interpolateLinear(startZoom, targetZoom, progress);
      final pitch = _interpolateLinear(startPitch, targetPitch, progress);
      final bearing = _interpolateAngle(startBearing, targetBearing, progress);

      final currentCenter = Geographic(lat: lat, lon: lon);
      _currentInterpolatedCenter = currentCenter;
      _currentInterpolatedZoom = zoom;
      _currentInterpolatedPitch = pitch;
      _currentInterpolatedBearing = bearing;

      _mapController!.moveCamera(
        center: currentCenter,
        zoom: zoom,
        pitch: pitch,
        bearing: bearing,
      );
      _lastProgrammaticMoveTime = DateTime.now();

      final previousOverlayUpdate = lastOverlayUpdate;
      final courseReachedTarget = progress >= 0.5 && !courseAtTarget;
      if (previousOverlayUpdate == null ||
          elapsed - previousOverlayUpdate >= overlayInterval ||
          courseReachedTarget ||
          t >= 1.0) {
        lastOverlayUpdate = elapsed;
        courseAtTarget = progress >= 0.5;

        // Interpolate the course line 2x faster for snappier tracking.
        final courseProgress = math.min(progress * 2, 1.0);
        _updateAircraftAndCourseLine(
          aircraftLat: lat,
          aircraftLon: lon,
          aircraftBearing: bearing,
          courseLat: _interpolateLinear(
            startCenter.lat,
            targetCenter.lat,
            courseProgress,
          ),
          courseLon: _interpolateLinear(
            startCenter.lon,
            targetCenter.lon,
            courseProgress,
          ),
          courseBearing: _interpolateAngle(
            startBearing,
            targetBearing,
            courseProgress,
          ),
        );
      }

      if (t >= 1.0) {
        _stopInterpolation();
      }
    });
    _interpolationTicker!.start();
  }

  void _updateAircraftAndCourseLine({
    required double aircraftLat,
    required double aircraftLon,
    required double aircraftBearing,
    required double courseLat,
    required double courseLon,
    required double courseBearing,
  }) {
    if (!_isAircraftSymbolInitialized || _mapController?.style == null) return;

    _mapController!.style!.updateGeoJsonSource(
      id: 'aircraft-source',
      data: GeoJsonBuilder.buildAircraftGeoJson(
        aircraftLat,
        aircraftLon,
        aircraftBearing,
      ),
    );

    final telemetry = refAccess.read(telemetryProvider);
    final settings = refAccess.read(appSettingsProvider).value;
    final interpolatedTelemetry = telemetry.copyWith(
      latitude: TelemetryValue(courseLat),
      longitude: TelemetryValue(courseLon),
      heading: TelemetryValue(courseBearing),
    );

    unawaited(
      _updateCourseLineOnMap(
        GeoJsonBuilder.buildCourseLineGeoJson(interpolatedTelemetry, settings),
      ),
    );
  }

  double _interpolateLinear(double start, double end, double t) {
    return start + (end - start) * t;
  }

  double _interpolateAngle(double start, double end, double t) {
    double diff = (end - start) % 360;
    if (diff > 180) diff -= 360;
    if (diff < -180) diff += 360;
    return (start + diff * t) % 360;
  }

  void _stopInterpolation() {
    _interpolationTicker?.stop();
    _interpolationTicker?.dispose();
    _interpolationTicker = null;
  }

  void _cancelInterpolation() {
    _stopInterpolation();
    _currentInterpolatedCenter = null;
    _currentInterpolatedZoom = null;
    _currentInterpolatedPitch = null;
    _currentInterpolatedBearing = null;
    _lastUpdateTimestamp = null;
    _lastUpdateInterval = const Duration(seconds: 1);
    _lastProgrammaticMoveTime = DateTime.now();
  }
}
