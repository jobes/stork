import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:maplibre/maplibre.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/services/location_provider.dart';
import '../../../../core/services/location_service.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../telemetry/domain/models/map_view_state.dart';
import '../../../telemetry/presentation/providers/telemetry_provider.dart';

part 'map_camera_provider.g.dart';

@riverpod
class MapCamera extends _$MapCamera {
  MapController? _mapController;
  final _controllerCompleter = Completer<MapController>();
  Timer? _followResumeTimer;
  bool _isFollowPaused = false;
  bool _isMovingProgrammatically = false;
  bool _isAircraftSymbolInitialized = false;

  @override
  void build() {
    // Listen to telemetry updates to move camera
    ref.listen(telemetryProvider, (previous, next) {
      if (_mapController == null) return;

      // Update aircraft symbol if initialized
      if (_isAircraftSymbolInitialized && _mapController?.style != null) {
        if (next.latitude != previous?.latitude ||
            next.longitude != previous?.longitude ||
            next.heading != previous?.heading) {
          _mapController!.style!.updateGeoJsonSource(
            id: 'aircraft-source',
            data: _getAircraftGeoJson(
              next.latitude,
              next.longitude,
              next.heading,
            ),
          );
        }
      }

      final settings = ref.read(appSettingsProvider).value;
      final center = Geographic(lon: next.longitude, lat: next.latitude);

      // Handle mode transitions and continuous updates
      if (next.mapViewState == MapViewState.follow) {
        if (next.latitude != 0 && next.longitude != 0 && !_isFollowPaused) {
          unawaited(moveCamera(
            center: center,
            zoom: settings?.mapFollowZoom ?? 12.0,
            pitch: 60,
            bearing: next.heading,
            animate: true,
          ));
        }
      } else if (next.mapViewState == MapViewState.overview) {
        final stateChanged = previous?.mapViewState != next.mapViewState;
        final coordsBecameValid =
            (previous?.latitude == 0 || previous?.longitude == 0) &&
            (next.latitude != 0 && next.longitude != 0);

        if (stateChanged || coordsBecameValid) {
          unawaited(moveCamera(
            center: center,
            zoom: settings?.mapOverviewZoom ?? 10.0,
            pitch: 0,
            bearing: 0,
            animate: kIsWeb && previous?.mapViewState != MapViewState.follow
                ? false
                : !coordsBecameValid,
          ));
        }
      }
    });

    // Listen to system location for initial positioning
    ref.listen(currentLocationProvider, (previous, next) {
      next.whenData((location) {
        if (location != null) {
          final telemetry = ref.read(telemetryProvider);
          final settings = ref.read(appSettingsProvider).value;
          if (telemetry.mapViewState == MapViewState.init && settings != null) {
            unawaited(moveCamera(
              center: location,
              zoom: settings.mapDefaultZoom,
              animate: false,
            ));
          }
        }
      });
    });

    // Listen to high-frequency GPS stream
    ref.listen(positionStreamProvider, (previous, next) {
      next.whenData((location) {
        final telemetry = ref.read(telemetryProvider);
        if (telemetry.mapViewState != MapViewState.init) {
          ref
              .read(telemetryProvider.notifier)
              .updateGPS(latitude: location.lat, longitude: location.lon);
        }
      });
    });

    // Clean up timer on dispose
    ref.onDispose(() {
      _followResumeTimer?.cancel();
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
    if (telemetry.latitude != 0 &&
        telemetry.longitude != 0 &&
        settings != null) {
      final double zoom;
      if (telemetry.mapViewState == MapViewState.overview) {
        zoom = settings.mapOverviewZoom;
      } else if (telemetry.mapViewState == MapViewState.follow) {
        zoom = settings.mapFollowZoom;
      } else {
        zoom = settings.mapDefaultZoom;
      }

      unawaited(moveCamera(
        center: Geographic(lon: telemetry.longitude, lat: telemetry.latitude),
        zoom: zoom,
        animate: false,
      ));
    }
  }

  Future<void> moveCamera({
    required Geographic center,
    required double zoom,
    double pitch = 0,
    double bearing = 0,
    bool animate = true,
  }) async {
    if (_mapController != null && center.lat != 0 && center.lon != 0) {
      _isMovingProgrammatically = true;
      try {
        if (animate) {
          await _mapController!.animateCamera(
            center: center,
            zoom: zoom,
            pitch: pitch,
            bearing: bearing,
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
        await Future.delayed(const Duration(milliseconds: 100));
        _isMovingProgrammatically = false;
      }
    }
  }

  void handleUserInteraction({bool isExplicitInteraction = true}) {
    // Only proceed if it's not a programmatical movement
    if (!isExplicitInteraction && _isMovingProgrammatically) return;

    final telemetry = ref.read(telemetryProvider);
    if (telemetry.mapViewState != MapViewState.follow) return;

    _followResumeTimer?.cancel();
    if (!_isFollowPaused) {
      _isFollowPaused = true;
    }

    _followResumeTimer = Timer(const Duration(seconds: 5), () {
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
    unawaited(moveCamera(
      center: Geographic(lon: telemetry.longitude, lat: telemetry.latitude),
      zoom: settings?.mapFollowZoom ?? 12.0,
      pitch: 60,
      bearing: telemetry.heading,
      animate: true,
    ));
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
        unawaited(moveCamera(
          center: initialLocation,
          zoom: settings?.mapDefaultZoom ?? 6.0,
          animate: false,
        ));
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

  Future<void> handleStyleLoaded(StyleController style) async {
    try {
      await style.addImageFromAssets(
        id: 'aircraft-icon',
        asset: 'assets/images/aircraft.png',
      );

      final telemetry = ref.read(telemetryProvider);
      await style.addSource(
        GeoJsonSource(
          id: 'aircraft-source',
          data: _getAircraftGeoJson(
            telemetry.latitude,
            telemetry.longitude,
            telemetry.heading,
          ),
        ),
      );

      await style.addLayer(
        SymbolStyleLayer(
          id: 'aircraft-layer',
          sourceId: 'aircraft-source',
          layout: {
            'icon-image': 'aircraft-icon',
            'icon-rotate': ['get', 'heading'],
            'icon-rotation-alignment': 'map',
            'icon-pitch-alignment': 'viewport',
            'icon-allow-overlap': true,
            'icon-ignore-placement': true,
            'icon-size': 1 / 4,
          },
        ),
      );

      _isAircraftSymbolInitialized = true;
      debugPrint('Aircraft symbol initialized 😎');
    } catch (e) {
      debugPrint('Error initializing native aircraft symbol: $e');
    }
  }

  String _getAircraftGeoJson(double lat, double lon, double heading) {
    if (lat == 0 && lon == 0) {
      return jsonEncode({'type': 'FeatureCollection', 'features': []});
    }
    return jsonEncode({
      'type': 'FeatureCollection',
      'features': [
        {
          'type': 'Feature',
          'geometry': {
            'type': 'Point',
            'coordinates': [lon, lat],
          },
          'properties': {'heading': heading},
        },
      ],
    });
  }

  bool get isMovingProgrammatically => _isMovingProgrammatically;
}
