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

    // Vsync-aligned Ticker instead of Timer.periodic: exactly one tick per
    // rendered frame, so no camera/GeoJSON updates are wasted on frames that
    // are never drawn, and ticking pauses automatically when the app stops
    // producing frames (e.g. backgrounded).
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

      // Interpolate the course line symbol 2x faster for snappier tracking
      double t2 = progress * 2;
      if (t2 > 1.0) t2 = 1.0;

      final lat2 = _interpolateLinear(startCenter.lat, targetCenter.lat, t2);
      final lon2 = _interpolateLinear(startCenter.lon, targetCenter.lon, t2);
      final bearing2 = _interpolateAngle(startBearing, targetBearing, t2);

      _updateAircraftAndCourseLine(
        aircraftLat: lat,
        aircraftLon: lon,
        aircraftBearing: bearing,
        courseLat: lat2,
        courseLon: lon2,
        courseBearing: bearing2,
      );

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

    _mapController!.style!.updateGeoJsonSource(
      id: 'course-line-source',
      data: GeoJsonBuilder.buildCourseLineGeoJson(
        interpolatedTelemetry,
        settings,
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
