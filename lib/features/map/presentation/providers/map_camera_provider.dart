import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:maplibre/maplibre.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/services/location_provider.dart';
import '../../../../core/services/location_service.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../telemetry/domain/models/map_view_state.dart';
import '../../../telemetry/presentation/providers/telemetry_provider.dart';
import '../../utils/geojson_builder.dart';

part 'map_camera_provider.g.dart';
part 'map_camera_interpolation.dart';
part 'map_camera_style.dart';

@riverpod
class MapCamera extends _$MapCamera {
  // Helper to access ref from part-files without protected member warnings
  dynamic get refAccess => ref;

  MapController? _mapController;
  final _controllerCompleter = Completer<MapController>();
  Timer? _followResumeTimer;
  bool _isFollowPaused = false;
  int _programmaticMoveCount = 0;
  bool _isAircraftSymbolInitialized = false;

  Timer? _interpolationTimer;
  Geographic? _currentInterpolatedCenter;
  double? _currentInterpolatedZoom;
  double? _currentInterpolatedPitch;
  double? _currentInterpolatedBearing;
  DateTime? _lastUpdateTimestamp;
  Duration _lastUpdateInterval = const Duration(seconds: 1);

  @override
  void build() {
    // Listen to telemetry updates to move camera
    ref.listen(telemetryProvider, (previous, next) {
      if (_mapController == null) return;

      // Update aircraft symbol if initialized
      if (_isAircraftSymbolInitialized &&
          _mapController?.style != null &&
          _interpolationTimer == null) {
        if (next.latitude != previous?.latitude ||
            next.longitude != previous?.longitude ||
            next.heading != previous?.heading) {
          _mapController!.style!.updateGeoJsonSource(
            id: 'aircraft-source',
            data: GeoJsonBuilder.buildAircraftGeoJson(
              next.latitude,
              next.longitude,
              next.heading,
            ),
          );
        }

        final settings = ref.read(appSettingsProvider).value;
        if (next.latitude != previous?.latitude ||
            next.longitude != previous?.longitude ||
            next.heading != previous?.heading ||
            next.groundSpeed != previous?.groundSpeed ||
            next.indicatedAirSpeed != previous?.indicatedAirSpeed ||
            next.isFlying != previous?.isFlying) {
          _mapController!.style!.updateGeoJsonSource(
            id: 'course-line-source',
            data: GeoJsonBuilder.buildCourseLineGeoJson(next, settings),
          );
        }
      }

      final settings = ref.read(appSettingsProvider).value;
      final center = Geographic(
        lon: next.longitude ?? 0.0,
        lat: next.latitude ?? 0.0,
      );

      // Handle mode transitions and continuous updates
      if (next.mapViewState == MapViewState.follow) {
        if (next.latitude != null &&
            next.longitude != null &&
            next.latitude != 0.0 &&
            next.longitude != 0.0 &&
            !_isFollowPaused) {
          final isContinuousFollow =
              previous?.mapViewState == MapViewState.follow;
          if (isContinuousFollow) {
            final now = DateTime.now();
            if (_lastUpdateTimestamp != null) {
              final interval = now.difference(_lastUpdateTimestamp!);
              if (interval >= const Duration(milliseconds: 100) &&
                  interval <= const Duration(seconds: 5)) {
                _lastUpdateInterval = interval;
              }
            }
            _lastUpdateTimestamp = now;

            _startLinearInterpolation(
              targetCenter: center,
              targetZoom: settings?.mapFollowZoom ?? 12.0,
              targetPitch: 60,
              targetBearing: next.heading ?? 0.0,
              duration: _lastUpdateInterval,
            );
          } else {
            _lastUpdateTimestamp = DateTime.now();
            _lastUpdateInterval = const Duration(seconds: 1);
            unawaited(
              moveCamera(
                center: center,
                zoom: settings?.mapFollowZoom ?? 12.0,
                pitch: 60,
                bearing: next.heading ?? 0.0,
                animate: true,
              ),
            );
          }
        }
      } else {
        _cancelInterpolation();
        if (next.mapViewState == MapViewState.overview) {
          final stateChanged = previous?.mapViewState != next.mapViewState;
          final coordsBecameValid =
              (previous?.latitude == null ||
                  previous?.longitude == null ||
                  previous?.latitude == 0.0 ||
                  previous?.longitude == 0.0) &&
              (next.latitude != null &&
                  next.longitude != null &&
                  next.latitude != 0.0 &&
                  next.longitude != 0.0);

          if (stateChanged || coordsBecameValid) {
            unawaited(
              moveCamera(
                center: center,
                zoom: settings?.mapOverviewZoom ?? 10.0,
                pitch: 0,
                bearing: 0,
                animate: kIsWeb && previous?.mapViewState != MapViewState.follow
                    ? false
                    : !coordsBecameValid,
              ),
            );
          }
        }
      }
    });

    // Listen to settings updates to update course line
    ref.listen(appSettingsProvider, (previous, next) {
      if (_mapController == null ||
          !_isAircraftSymbolInitialized ||
          _mapController?.style == null) {
        return;
      }

      final telemetry = ref.read(telemetryProvider);
      final settings = next.value;

      _mapController!.style!.updateGeoJsonSource(
        id: 'course-line-source',
        data: GeoJsonBuilder.buildCourseLineGeoJson(telemetry, settings),
      );
    });

    // Listen to system location for initial positioning
    ref.listen(currentLocationProvider, (previous, next) {
      next.whenData((location) {
        if (location != null) {
          final telemetry = ref.read(telemetryProvider);
          final settings = ref.read(appSettingsProvider).value;
          if (telemetry.mapViewState == MapViewState.init && settings != null) {
            unawaited(
              moveCamera(
                center: location,
                zoom: settings.mapDefaultZoom,
                animate: false,
              ),
            );
          }
        }
      });
    });

    // Listen to high-frequency GPS stream
    ref.listen(positionStreamProvider, (previous, next) {
      next.whenData((location) {
        final telemetry = ref.read(telemetryProvider);
        if (telemetry.mapViewState != MapViewState.init) {
          // Update position and groundSpeed first to let telemetry update isFlying state
          ref
              .read(telemetryProvider.notifier)
              .updateGPS(
                latitude: location.lat,
                longitude: location.lon,
                groundSpeed: location.groundSpeed,
                gpsSatelliteCount:
                    null, // Phone GPS satellites set to null as per requirement
                gpsHorizontalAccuracy: location.horizontalAccuracy,
                gpsVerticalAccuracy: location.verticalAccuracy,
              );

          // Use GPS heading only if we are flying (according to telemetry logic)
          if (ref.read(telemetryProvider).isFlying) {
            ref
                .read(telemetryProvider.notifier)
                .updateGPS(heading: location.heading);
          }
        }
      });
    });

    // Listen to device compass for low-speed heading
    ref.listen(compassStreamProvider, (previous, next) {
      next.whenData((heading) {
        if (heading == null) return;

        final telemetry = ref.read(telemetryProvider);
        if (telemetry.mapViewState != MapViewState.init &&
            !telemetry.isFlying) {
          ref.read(telemetryProvider.notifier).updateGPS(heading: heading);
        }
      });
    });

    // Clean up timer on dispose
    ref.onDispose(() {
      _followResumeTimer?.cancel();
      _cancelInterpolation();
    });
  }

  void attachController(MapController controller) {
    _mapController = controller;
    if (!_controllerCompleter.isCompleted) {
      _controllerCompleter.complete(controller);
    }

    // Initial move if telemetry is already valid
    final telemetry = ref.read(telemetryProvider);
    final settings = ref.read(appSettingsProvider).value;
    if (telemetry.latitude != null &&
        telemetry.longitude != null &&
        telemetry.latitude != 0.0 &&
        telemetry.longitude != 0.0 &&
        settings != null) {
      final double zoom;
      if (telemetry.mapViewState == MapViewState.overview) {
        zoom = settings.mapOverviewZoom;
      } else if (telemetry.mapViewState == MapViewState.follow) {
        zoom = settings.mapFollowZoom;
      } else {
        zoom = settings.mapDefaultZoom;
      }

      unawaited(
        moveCamera(
          center: Geographic(
            lon: telemetry.longitude!,
            lat: telemetry.latitude!,
          ),
          zoom: zoom,
          animate: false,
        ),
      );
    }
  }

  Future<void> moveCamera({
    required Geographic center,
    required double zoom,
    double pitch = 0,
    double bearing = 0,
    bool animate = true,
    Duration? duration,
  }) async {
    _cancelInterpolation();
    if (_mapController != null && center.lat != 0 && center.lon != 0) {
      _programmaticMoveCount++;
      try {
        if (animate) {
          await _mapController!.animateCamera(
            center: center,
            zoom: zoom,
            pitch: pitch,
            bearing: bearing,
            nativeDuration: duration ?? const Duration(seconds: 2),
            webMaxDuration: duration,
          );
        } else {
          _mapController!.moveCamera(
            center: center,
            zoom: zoom,
            pitch: pitch,
            bearing: bearing,
          );
        }
      } finally {
        await Future.delayed(const Duration(milliseconds: 200));
        _programmaticMoveCount--;
      }
    }
  }

  void handleUserInteraction({bool isExplicitInteraction = true}) {
    // Only proceed if it's not a programmatical movement
    if (!isExplicitInteraction &&
        (_programmaticMoveCount > 0 || _interpolationTimer != null)) {
      return;
    }

    final telemetry = ref.read(telemetryProvider);
    if (telemetry.mapViewState != MapViewState.follow) return;

    _followResumeTimer?.cancel();
    if (!_isFollowPaused) {
      _isFollowPaused = true;
      _cancelInterpolation();
    }

    _followResumeTimer = Timer(const Duration(seconds: 5), () {
      if (!ref.mounted) return;

      _isFollowPaused = false;

      // Immediate snap back if still in follow mode
      final currentTelemetry = ref.read(telemetryProvider);
      if (currentTelemetry.mapViewState == MapViewState.follow) {
        snapBackToAircraft();
      }
    });
  }

  void snapBackToAircraft() {
    if (_mapController == null) return;

    final telemetry = ref.read(telemetryProvider);
    final settings = ref.read(appSettingsProvider).value;
    if (telemetry.longitude != null && telemetry.latitude != null) {
      unawaited(
        moveCamera(
          center: Geographic(
            lon: telemetry.longitude!,
            lat: telemetry.latitude!,
          ),
          zoom: settings?.mapFollowZoom ?? 12.0,
          pitch: 60,
          bearing: telemetry.heading ?? 0.0,
          animate: true,
        ),
      );
    }
  }

  Future<void> handleGpsToggle() async {
    final telemetry = ref.read(telemetryProvider);
    final mapViewState = telemetry.mapViewState;

    if (mapViewState == MapViewState.init ||
        mapViewState == MapViewState.waitingForGps) {
      ref
          .read(telemetryProvider.notifier)
          .setMapViewState(MapViewState.waitingForGps);

      final location = await LocationService.getGpsLocationOnly(
        requestPermission: true,
      );

      if (location != null) {
        ref
            .read(telemetryProvider.notifier)
            .updateGPS(latitude: location.lat, longitude: location.lon);
      } else {
        // If GPS is denied or failed, return to init state
        final hasPermission = await LocationService.hasPermission();
        if (!hasPermission) {
          ref
              .read(telemetryProvider.notifier)
              .setMapViewState(MapViewState.init);
        }
      }
    } else {
      final nextState = mapViewState == MapViewState.follow
          ? MapViewState.overview
          : MapViewState.follow;

      ref.read(telemetryProvider.notifier).setMapViewState(nextState);
    }
  }

  Future<void> autoStartGps() async {
    final telemetry = ref.read(telemetryProvider);
    if (telemetry.mapViewState == MapViewState.init) {
      final settings = ref.read(appSettingsProvider).value;

      final initialLocation = await LocationService.getCurrentLocation(
        requestPermission: false,
      );
      if (!ref.mounted) return;

      // Wait for controller to be ready
      if (_mapController == null) {
        await _controllerCompleter.future;
        if (!ref.mounted) return;
      }

      if (initialLocation != null && _mapController != null) {
        unawaited(
          moveCamera(
            center: initialLocation,
            zoom: settings?.mapDefaultZoom ?? 6.0,
            animate: false,
          ),
        );
      }

      final hasPermission = await LocationService.hasPermission();
      if (!ref.mounted) return;

      if (hasPermission) {
        ref
            .read(telemetryProvider.notifier)
            .setMapViewState(MapViewState.waitingForGps);

        final realLocation = await LocationService.getGpsLocationOnly(
          requestPermission: false,
        );
        if (!ref.mounted) return;

        if (realLocation != null) {
          ref
              .read(telemetryProvider.notifier)
              .updateGPS(
                latitude: realLocation.lat,
                longitude: realLocation.lon,
              );
        }
      }
    }
  }

  bool get isAircraftSymbolInitialized => _isAircraftSymbolInitialized;
  MapController? get mapController => _mapController;

  void handleMapEvent(MapEvent event) {
    if (event is MapEventMoveCamera) {
      handleUserInteraction(isExplicitInteraction: false);
    }
    if (event is MapEventClick) {
      debugPrint('Map clicked at ${event.point}');
    }
  }

  bool get isMovingProgrammatically =>
      _programmaticMoveCount > 0 || _interpolationTimer != null;
}
