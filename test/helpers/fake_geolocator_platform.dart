import 'dart:async';

import 'package:geolocator/geolocator.dart';

/// A fake [GeolocatorPlatform] that hands out a controllable broadcast stream,
/// counts how often the native position stream is (re)created and records the
/// location settings used for each (re)start.
class FakeGeolocatorPlatform extends GeolocatorPlatform {
  FakeGeolocatorPlatform(this.controller);

  final StreamController<Position> controller;
  final List<LocationSettings?> settingsLog = [];
  int getPositionStreamCallCount = 0;

  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) {
    getPositionStreamCallCount++;
    settingsLog.add(locationSettings);
    return controller.stream;
  }
}

/// A standard test [Position] with sensible defaults.
Position makePosition({
  double lat = 48.0,
  double lon = 17.0,
  double accuracy = 5.0,
  double speed = 12.0,
  double heading = 45.0,
}) {
  return Position(
    longitude: lon,
    latitude: lat,
    timestamp: DateTime.now(),
    accuracy: accuracy,
    altitude: 300.0,
    altitudeAccuracy: 6.0,
    heading: heading,
    headingAccuracy: 3.0,
    speed: speed,
    speedAccuracy: 0.5,
  );
}
