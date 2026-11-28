import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart'
    show WidgetsBinding, WidgetsBindingObserver;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre/maplibre.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/services/location_provider.dart';
import '../../../../core/startup/initial_map_camera.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/utils/geo_utils.dart';
import '../../../settings/presentation/providers/display_preferences_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../weather/presentation/providers/flight_weather_provider.dart';
import '../../../weather/presentation/providers/route_waypoint_weather_provider.dart';
import '../../../telemetry/domain/models/map_view_state.dart';
import '../../../telemetry/presentation/providers/telemetry_provider.dart';
import '../../../telemetry/presentation/providers/traffic_provider.dart';
import '../../../navigation/presentation/providers/navigation_provider.dart';
import '../../../favorites/presentation/providers/favorites_provider.dart';
import 'notams_provider.dart';
import 'airspace_activity_provider.dart';
import 'airspace_highlight_layers.dart';
import 'map_overlay_style.dart';
import 'map_style_preparer.dart';
import 'map_style_data.dart';
export 'map_style_data.dart'
    show kTrafficLookaheadPeriodSeconds, kTrafficBaseIconSizePx;
export 'map_overlay_style.dart'
    show kAircraftIconSize, kTrafficIconSize, kPoiIconSize;
import '../../domain/utils/airspace_activity_utils.dart';
import '../../utils/flight_weather_geojson.dart';
import '../../utils/geojson_builder.dart';

part 'map_camera_provider.g.dart';
part 'map_camera_interpolation.dart';
part 'map_camera_style.dart';
part 'map_camera_airspace.dart';
part 'map_camera_notam.dart';
part 'map_camera_weather.dart';

class _WeatherBrightnessObserver extends WidgetsBindingObserver {
  _WeatherBrightnessObserver(this.onChange);
  final void Function() onChange;
  @override
  void didChangePlatformBrightness() => onChange();
}

@riverpod
class MapCamera extends _$MapCamera {
  Ref get refAccess => ref;

  MapController? _mapController;
  int _cameraRevision = 0;
  CameraPosition? _eventCamera;
  CameraPosition? _presentedCamera;
  CameraPosition? _trafficEndingCamera;
  bool _trafficViewportDue = false;
  final _controllerCompleter = Completer<MapController>();
  Timer? _followResumeTimer;
  bool _isFollowPaused = false;
  bool _hasExplicitFocus = false;
  Object? _activeTransitionToken;
  bool get _isTransitionAnimating => _activeTransitionToken != null;
  int _programmaticMoveCount = 0;
  DateTime? _lastProgrammaticMoveTime;
  bool _isAircraftSymbolInitialized = false;
  int _styleLoadGeneration = 0;
  StyleController? _flightWeatherStyle;
  ForecastPalette? _lastFlightWeatherPalette;
  String? _lastFlightWeatherGeoJson;
  int _flightWeatherRevision = 0;
  bool _flightWeatherWriting = false;
  bool _flightWeatherWriteScheduled = false;
  ({StyleController style, String data})? _lastCourseLineUpdate;
  Timer? _notamLayerTimer;
  bool _notamLayerDirty = false;
  bool _notamLayerWriting = false;
  StyleController? _notamStyle;
  List<NotamMapFeature>? _lastNotamMapFeatures = const [];

  List<String>? _lastActiveAirspaceIds;
  List<String>? _lastInactiveAirspaceIds;

  Future<void>? _airspaceHighlightInFlight;

  Ticker? _interpolationTicker;
  Geographic? _currentInterpolatedCenter;
  double? _currentInterpolatedZoom;
  double? _currentInterpolatedPitch;
  double? _currentInterpolatedBearing;
  DateTime? _lastUpdateTimestamp;
  Duration _lastUpdateInterval = const Duration(seconds: 1);
  DateTime? _lastRouteUpdateTime;
  Timer? _routeUpdateTimer;
  Timer? _routeRetryTimer;
  int _routeRetryAttempts = 0;
  Geographic? _lastKnownRouteOrigin;
  bool _routeWriting = false;
  bool? _pendingRouteForce;
  ({StyleController style, String data})? _lastNavigationRouteUpdate;

  @override
  void build() {
    final brightnessObserver = _WeatherBrightnessObserver(() {
      unawaited(_updateFlightWeatherPalette());
    });
    WidgetsBinding.instance.addObserver(brightnessObserver);
    ref.onDispose(
      () => WidgetsBinding.instance.removeObserver(brightnessObserver),
    );
    ref.listen(
      telemetryProvider.select(
        (s) => (
          latitude: s.latitude,
          longitude: s.longitude,
          heading: s.heading,
          groundSpeed: s.groundSpeed,
          indicatedAirSpeed: s.indicatedAirSpeed,
          isFlying: s.isFlying,
          mapViewState: s.mapViewState,
        ),
      ),
      (previous, next) {
        final position = _navigationPosition(next.latitude, next.longitude);
        if (position != null) _lastKnownRouteOrigin = position;
        if (_mapController == null) return;

        if (next.latitude != previous?.latitude ||
            next.longitude != previous?.longitude) {
          _updateNavigationRouteOnMap(
            force:
                position != null &&
                _navigationPosition(previous?.latitude, previous?.longitude) ==
                    null,
          );
        }

        if (_isAircraftSymbolInitialized &&
            _mapController?.style != null &&
            _interpolationTicker == null) {
          if (next.latitude != previous?.latitude ||
              next.longitude != previous?.longitude ||
              next.heading != previous?.heading) {
            _mapController!.style!.sources.updateGeoJsonData(
              'aircraft-source',
              GeoJsonData.text(
                GeoJsonBuilder.buildAircraftGeoJson(
                  next.latitude,
                  next.longitude,
                  next.heading,
                ),
              ),
            );
          }

          if (next.latitude != previous?.latitude ||
              next.longitude != previous?.longitude ||
              next.heading != previous?.heading ||
              next.groundSpeed != previous?.groundSpeed ||
              next.indicatedAirSpeed != previous?.indicatedAirSpeed ||
              next.isFlying != previous?.isFlying) {
            final settings = ref.read(appSettingsProvider).value;
            final telemetry = ref.read(telemetryProvider);
            unawaited(
              _updateCourseLineOnMap(
                GeoJsonBuilder.buildCourseLineGeoJson(telemetry, settings),
              ),
            );
          }
        }

        final settings = ref.read(appSettingsProvider).value;
        final center = GeoUtils.validatedPosition(
          next.latitude,
          next.longitude,
        );

        if (next.mapViewState == MapViewState.follow) {
          _hasExplicitFocus = false;
          if (center != null && !_isFollowPaused && !_isTransitionAnimating) {
            final isContinuousFollow =
                previous?.mapViewState == MapViewState.follow;

            final coordsChanged =
                previous?.latitude != next.latitude ||
                previous?.longitude != next.longitude ||
                previous?.heading != next.heading;

            if (isContinuousFollow && !coordsChanged) {
              return;
            }

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
                targetPitch: settings?.mapFollowPitch ?? 30.0,
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
                  pitch: settings?.mapFollowPitch ?? 30.0,
                  bearing: next.heading ?? 0.0,
                  animate: true,
                ),
              );
            }
          }
        } else {
          _cancelInterpolation();
          if (next.mapViewState == MapViewState.overview &&
              !_hasExplicitFocus &&
              center != null) {
            final stateChanged = previous?.mapViewState != next.mapViewState;
            final coordsBecameValid =
                GeoUtils.validatedPosition(
                  previous?.latitude,
                  previous?.longitude,
                ) ==
                null;

            if (stateChanged || coordsBecameValid) {
              unawaited(
                moveCamera(
                  center: center,
                  zoom: settings?.mapOverviewZoom ?? 10.0,
                  pitch: 0,
                  bearing: 0,
                  animate:
                      kIsWeb && previous?.mapViewState != MapViewState.follow
                      ? false
                      : !coordsBecameValid,
                ),
              );
            }
          }
        }
      },
    );

    ref.listen(appSettingsProvider, (previous, next) {
      final telemetry = ref.read(telemetryProvider);
      final settings = next.value;
      final previousPitch = previous?.value?.mapFollowPitch ?? 30.0;
      if (settings != null &&
          settings.mapFollowPitch != previousPitch &&
          telemetry.mapViewState == MapViewState.follow &&
          !_isFollowPaused) {
        snapBackToAircraft(animate: false);
      }

      if (_mapController == null ||
          !_isAircraftSymbolInitialized ||
          _mapController?.style == null) {
        return;
      }

      unawaited(
        _updateCourseLineOnMap(
          GeoJsonBuilder.buildCourseLineGeoJson(telemetry, settings),
        ),
      );
      updateTrafficOnMap();
    });

    // The app bootstrap has already selected a bounded local camera. Do not
    // start a second GPS/GeoIP lookup while preparing its initial style.
    if (ref.read(initialMapCameraProvider) == null) {
      ref.listen(currentLocationProvider, (previous, next) {
        next.whenData((location) {
          if (location != null) {
            final telemetry = ref.read(telemetryProvider);
            final settings = ref.read(appSettingsProvider).value;
            if (telemetry.mapViewState == MapViewState.init &&
                settings != null) {
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
    }

    ref.listen(navigationProvider, (previous, next) {
      _updateNavigationRouteOnMap(force: true);
    });

    ref.listen(
      flightWeatherPlanProvider,
      (_, _) => _updateFlightWeatherOnMap(),
    );
    ref.listen(routePointWindsProvider, (_, _) => _updateFlightWeatherOnMap());
    ref.listen(displayPreferencesProvider, (_, _) {
      _updateFlightWeatherOnMap();
      unawaited(_updateFlightWeatherPalette());
    });
    ref.listen(
      appSettingsProvider.select(
        (s) => (s.value?.showFlightWeather, s.value?.windSpeedUnit),
      ),
      (_, _) => _updateFlightWeatherOnMap(),
    );

    ref.listen(notamsProvider, (_, next) {
      if (!next.isLoading) updateNotamsOnMap();
    });

    ref.listen(favoritesProvider, (previous, next) {
      if (next.hasValue) {
        updateFavoritesOnMap();
        _updateFlightWeatherOnMap();
      }
    });

    ref.listen(airspaceActivityProvider, (previous, next) {
      unawaited(updateAirspacesOnMap());
    });

    ref.listen(filteredTrafficProvider, (previous, next) {
      if (!_sameUnthreatenedTraffic(previous, next)) {
        updateTrafficOnMap(next);
      }
    });

    final trafficTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (_mapController != null && _isAircraftSymbolInitialized) {
        final currentTraffic = ref.read(filteredTrafficProvider);
        if (currentTraffic.isNotEmpty) {
          updateTrafficOnMap(currentTraffic);
        }
      }
    });

    ref.onDispose(() {
      trafficTimer.cancel();
      _routeUpdateTimer?.cancel();
      _routeRetryTimer?.cancel();
      _moveThrottleTimer?.cancel();
      _followResumeTimer?.cancel();
      _notamLayerTimer?.cancel();
      _notamLayerTimer = null;
      _notamLayerDirty = false;
      _cancelInterpolation();
    });
  }

  void attachController(
    MapController controller, {
    bool cameraPrepared = false,
    InitialMapCamera? preparedCamera,
  }) {
    _cameraRevision++;
    _eventCamera = controller.camera;
    _presentedCamera = null;
    _trafficEndingCamera = null;
    _trafficViewportDue = false;
    _mapController = controller;
    if (!_controllerCompleter.isCompleted) {
      _controllerCompleter.complete(controller);
    }

    if (cameraPrepared) {
      if (_hasExplicitFocus) return;
      final telemetry = ref.read(telemetryProvider);
      final latest = _navigationPosition(
        telemetry.latitude,
        telemetry.longitude,
      );
      // The Android plugin can call onMapCreated before populating camera.
      final current =
          controller.camera?.center ??
          preparedCamera?.center ??
          ref.read(initialMapCameraProvider)?.center;
      if (latest == null ||
          (latest.lat == current?.lat && latest.lon == current?.lon)) {
        return;
      }
    }
    final telemetry = ref.read(telemetryProvider);
    final settings = ref.read(appSettingsProvider).value;
    final center = GeoUtils.validatedPosition(
      telemetry.latitude,
      telemetry.longitude,
    );
    if (!_hasExplicitFocus && center != null && settings != null) {
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
          center: center,
          zoom: zoom,
          pitch: telemetry.mapViewState == MapViewState.follow
              ? settings.mapFollowPitch
              : 0.0,
          animate: false,
        ),
      );
    }
  }

  /// Moves the camera to a valid telemetry position. [allowZeroCoordinate]
  /// permits explicit points, including the unset telemetry position (0, 0).
  Future<void> moveCamera({
    required Geographic center,
    required double zoom,
    double pitch = 0,
    double bearing = 0,
    bool animate = true,
    Duration? duration,
    bool allowZeroCoordinate = false,
  }) async {
    _cancelInterpolation();
    if (_mapController != null &&
        (allowZeroCoordinate ||
            GeoUtils.validatedPosition(
                  center.lat.toDouble(),
                  center.lon.toDouble(),
                ) !=
                null)) {
      _programmaticMoveCount++;
      _lastProgrammaticMoveTime = DateTime.now();
      Object? token;
      if (animate) {
        token = Object();
        _activeTransitionToken = token;
      }
      try {
        if (animate) {
          await _mapController!.animateCamera(
            CameraUpdate.position(
              center: center,
              zoom: zoom,
              pitch: pitch,
              bearing: bearing,
            ),
            animation: CameraAnimation.fly(
              duration: duration ?? const Duration(seconds: 2),
            ),
          );
        } else {
          _mapController!.moveCamera(
            CameraUpdate.position(
              center: center,
              zoom: zoom,
              pitch: pitch,
              bearing: bearing,
            ),
          );
        }
      } finally {
        _lastProgrammaticMoveTime = DateTime.now();
        await Future.delayed(const Duration(milliseconds: 200));
        _programmaticMoveCount--;
        if (token != null && _activeTransitionToken == token) {
          _activeTransitionToken = null;
        }
      }
    }
  }

  /// Moves the camera to the given point and switches to the north-up overview
  /// state (static "preview", stops following the aircraft). Waits for the map
  /// controller when the map page is not mounted yet.
  Future<void> focusOnPoint({
    required double latitude,
    required double longitude,
    double zoom = 10.0,
  }) async {
    _followResumeTimer?.cancel();
    _isFollowPaused = false;
    _hasExplicitFocus = true;

    ref.read(telemetryProvider.notifier).setMapViewState(MapViewState.overview);

    if (_mapController == null) {
      await _controllerCompleter.future;
      if (!ref.mounted) return;
    }

    await moveCamera(
      center: Geographic(lon: longitude, lat: latitude),
      zoom: zoom,
      pitch: 0,
      bearing: 0,
      animate: true,
      allowZeroCoordinate: true,
    );
  }

  void handleUserInteraction({bool isExplicitInteraction = true}) {
    if (!isExplicitInteraction && isMovingProgrammatically) {
      return;
    }

    final telemetry = ref.read(telemetryProvider);
    if (telemetry.mapViewState != MapViewState.follow) return;

    _followResumeTimer?.cancel();
    if (!_isFollowPaused) {
      _isFollowPaused = true;
      _cancelInterpolation();
    }
    _activeTransitionToken = null;

    _followResumeTimer = Timer(const Duration(seconds: 5), () {
      if (!ref.mounted) return;

      _isFollowPaused = false;

      final currentTelemetry = ref.read(telemetryProvider);
      if (currentTelemetry.mapViewState == MapViewState.follow) {
        snapBackToAircraft();
      }
    });
  }

  void snapBackToAircraft({bool animate = true}) {
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
          pitch: settings?.mapFollowPitch ?? 30.0,
          bearing: telemetry.heading ?? 0.0,
          animate: animate,
        ),
      );
    }
  }

  Future<void> handleGpsToggle() async {
    // A live external GPS fix does not require the phone's location service.
    final external = ref.read(telemetryProvider);
    if (external.isGpsDroneCan &&
        GeoUtils.validatedPosition(external.latitude, external.longitude) !=
            null) {
      ref
          .read(telemetryProvider.notifier)
          .setMapViewState(
            external.mapViewState == MapViewState.follow
                ? MapViewState.overview
                : MapViewState.follow,
          );
      return;
    }

    final hasPermission = await LocationService.hasPermission();
    if (!ref.mounted) return;

    final telemetry = ref.read(telemetryProvider);
    final mapViewState = telemetry.mapViewState;

    if (!hasPermission ||
        mapViewState == MapViewState.init ||
        mapViewState == MapViewState.waitingForGps) {
      ref
          .read(telemetryProvider.notifier)
          .setMapViewState(MapViewState.waitingForGps);

      final location = await LocationService.getGpsLocationOnly(
        requestPermission: true,
      );
      if (!ref.mounted) return;
      final permissionGranted = await LocationService.hasPermission();
      if (!ref.mounted) return;

      if (permissionGranted) {
        ref.read(geolocatorStreamProvider.notifier).start();
      }

      if (location != null) {
        ref
            .read(telemetryProvider.notifier)
            .updateGPS(latitude: location.lat, longitude: location.lon);
      } else if (!permissionGranted &&
          ref.read(telemetryProvider).mapViewState ==
              MapViewState.waitingForGps) {
        final previousView = switch (mapViewState) {
          MapViewState.follow || MapViewState.overview => mapViewState,
          _ => _hasExplicitFocus ? MapViewState.overview : MapViewState.init,
        };
        ref.read(telemetryProvider.notifier).setMapViewState(previousView);
      }
    } else {
      final nextState = mapViewState == MapViewState.follow
          ? MapViewState.overview
          : MapViewState.follow;

      ref.read(telemetryProvider.notifier).setMapViewState(nextState);
    }
  }

  Future<void> autoStartGps() async {
    final preparedCamera = ref.read(initialMapCameraProvider);
    final locationPrepared = preparedCamera != null;
    Geographic? initialLocation = preparedCamera?.hasLocation == true
        ? preparedCamera!.center
        : null;
    final telemetry = ref.read(telemetryProvider);
    if (telemetry.mapViewState == MapViewState.init) {
      final settings = ref.read(appSettingsProvider).value;

      initialLocation = locationPrepared
          ? initialLocation
          : await LocationService.getCurrentLocation(requestPermission: false);
      if (!ref.mounted) return;

      if (_mapController == null) {
        await _controllerCompleter.future;
        if (!ref.mounted) return;
      }

      if (!locationPrepared &&
          !_hasExplicitFocus &&
          initialLocation != null &&
          _mapController != null &&
          ref.read(telemetryProvider).mapViewState == MapViewState.init) {
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
        if (ref.read(telemetryProvider).mapViewState == MapViewState.init) {
          ref
              .read(telemetryProvider.notifier)
              .setMapViewState(MapViewState.waitingForGps);
        }

        ref.read(geolocatorStreamProvider.notifier).start();

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

  Timer? _moveThrottleTimer;
  bool _refreshTrafficAfterCameraMove = false;

  bool get isAircraftSymbolInitialized => _isAircraftSymbolInitialized;
  MapController? get mapController => _mapController;

  void handleMapEvent(
    MapEvent event, {
    Function(List<dynamic> features, Geographic coordinate)? onFeaturesTapped,
  }) {
    final eventCamera = switch (event) {
      MapEventCameraMove(:final camera) => camera,
      MapEventCameraMoveEnd(:final camera) => camera,
      _ => null,
    };
    if (eventCamera != null && eventCamera != _eventCamera) {
      _eventCamera = eventCamera;
      _cameraRevision++;
    }
    if (event is MapEventCameraMove) {
      _trafficEndingCamera = null;
      handleUserInteraction(isExplicitInteraction: false);
      _scheduleTrafficViewportUpdate();
    }
    if (event is MapEventCameraMoveEnd) {
      _trafficEndingCamera = event.camera;
      // Frame-by-frame follow can emit idle events between programmatic moves.
      // Share the existing viewport timer instead of rebuilding traffic per tick.
      if (_isFollowingCamera && isMovingProgrammatically) {
        _refreshTrafficAfterCameraMove = true;
        _scheduleTrafficViewportUpdate();
        return;
      }
      _moveThrottleTimer?.cancel();
      _refreshTrafficAfterCameraMove = true;
      _updateTrafficFilter();
    }
    if (event is MapEventClick) {
      debugPrint('Map clicked at ${event.point}');
      if (onFeaturesTapped != null) {
        _handleMapClick(event, onFeaturesTapped);
      }
    }
  }

  void _scheduleTrafficViewportUpdate() {
    if (_moveThrottleTimer?.isActive ?? false) return;
    _moveThrottleTimer = Timer(const Duration(milliseconds: 500), () {
      _updateTrafficFilter();
    });
  }

  void updateTrafficOnMap([List<TrafficAircraft>? trafficList]) {
    if (_mapController == null ||
        !_isAircraftSymbolInitialized ||
        _mapController?.style == null) {
      return;
    }

    final traffic = trafficList ?? ref.read(filteredTrafficProvider);
    if (traffic == null || traffic.isEmpty) {
      _mapController!.style!.sources.updateGeoJsonData(
        'traffic-source',
        GeoJsonData.text(
          jsonEncode({'type': 'FeatureCollection', 'features': []}),
        ),
      );
      return;
    }

    _mapController!.style!.sources.updateGeoJsonData(
      'traffic-source',
      GeoJsonData.text(_buildTrafficGeoJson(traffic)),
    );
  }

  // Other telemetry can republish the same traffic. The viewport and periodic
  // refreshes still update projected positions as the camera and time change.
  bool _sameUnthreatenedTraffic(
    List<TrafficAircraft>? previous,
    List<TrafficAircraft> next,
  ) {
    if (previous == null || previous.length != next.length) return false;
    for (var i = 0; i < next.length; i++) {
      final before = previous[i];
      final after = next[i];
      // Relative altitude labels for threats also depend on ownship telemetry.
      if (before.isCollisionThreat ||
          after.isCollisionThreat ||
          before.id != after.id ||
          before.callsign != after.callsign ||
          before.latitude != after.latitude ||
          before.longitude != after.longitude ||
          before.altitude != after.altitude ||
          before.track != after.track ||
          before.groundSpeed != after.groundSpeed ||
          before.verticalSpeed != after.verticalSpeed ||
          before.aircraftType != after.aircraftType ||
          before.lastSeen != after.lastSeen) {
        return false;
      }
    }
    return true;
  }

  // Called by a MapLibreMap child observing the camera of the shown texture.
  void handleCameraPresented(CameraPosition camera) {
    if (_presentedCamera != null && _presentedCamera != camera) {
      _cameraRevision++;
    }
    _presentedCamera = camera;
    if (_trafficViewportDue) _updateTrafficFilter();
  }

  bool get _isFollowingCamera =>
      !_isFollowPaused &&
      ref.read(telemetryProvider).mapViewState == MapViewState.follow;

  void _updateTrafficFilter() {
    if (_mapController == null) return;
    _trafficViewportDue = true;
    final endingCamera = _trafficEndingCamera;
    // Continuous follow reads the currently displayed viewport on the throttle:
    // waiting for the latest target would starve updates while it keeps moving.
    if (!_isFollowingCamera &&
        endingCamera != null &&
        (_presentedCamera != endingCamera ||
            _mapController!.camera != endingCamera)) {
      return;
    }
    _trafficViewportDue = false;
    try {
      final bounds = _mapController!.getVisibleBounds();
      ref.read(trafficProvider.notifier).updateViewport(bounds);
      if (_refreshTrafficAfterCameraMove) {
        _refreshTrafficAfterCameraMove = false;
        updateTrafficOnMap();
      }
    } catch (e) {
      debugPrint('Failed to update traffic filter bounds: $e');
    }
  }

  Future<void> _handleMapClick(
    MapEventClick event,
    Function(List<dynamic> features, Geographic coordinate) onFeaturesTapped,
  ) async {
    final controller = _mapController;
    if (controller == null) return;
    final revision = _cameraRevision;
    bool isCurrent() =>
        ref.mounted &&
        identical(controller, _mapController) &&
        revision == _cameraRevision;
    try {
      final airportFeatures = await controller.queryRenderedFeatures(
        QueryGeometry.point(event.screenPoint),
        layerIds: [
          'airport_clicktarget',
          'airport_runway',
          'airport_parachute',
          'airport_gliding',
          'airport_gliding_winch',
          'airport_other',
          'airport_with_code_runway',
          'airport_with_code',
          'airport_runway_intl',
          'airport_intl',
        ],
      );

      final airspaceFeatures = await controller.queryRenderedFeatures(
        QueryGeometry.point(event.screenPoint),
        layerIds: ['airspace_clicktarget'],
      );

      final placeFeatures = await controller.queryRenderedFeatures(
        QueryGeometry.point(event.screenPoint),
        layerIds: ['places_locality'],
      );

      final notamFeatures = await controller.queryRenderedFeatures(
        QueryGeometry.point(event.screenPoint),
        layerIds: ['notams-fill-layer'],
      );

      final favoriteFeatures = await controller.queryRenderedFeatures(
        QueryGeometry.point(event.screenPoint),
        layerIds: ['favorites-layer'],
      );

      final trafficFeatures = await controller.queryRenderedFeatures(
        QueryGeometry.point(event.screenPoint),
        layerIds: ['traffic-layer'],
      );

      final featureMaps = <Map<String, dynamic>>[];
      for (final f in airportFeatures) {
        featureMaps.add({
          'id': f.id,
          'properties': f.properties,
          'layerType': 'airport',
        });
      }
      for (final f in airspaceFeatures) {
        featureMaps.add({
          'id': f.id,
          'properties': f.properties,
          'layerType': 'airspace',
        });
      }
      for (final f in placeFeatures) {
        featureMaps.add({
          'id': f.id,
          'properties': f.properties,
          'layerType': 'place',
        });
      }
      for (final f in notamFeatures) {
        featureMaps.add({
          'id': f.id,
          'properties': f.properties,
          'layerType': 'notam',
        });
      }
      for (final f in favoriteFeatures) {
        featureMaps.add({
          'id': f.id,
          'properties': f.properties,
          'layerType': 'favorite',
        });
      }
      for (final f in trafficFeatures) {
        featureMaps.add({
          'id': f.id,
          'properties': f.properties,
          'layerType': 'traffic',
        });
      }

      if (_flightWeatherStyle != null &&
          identical(_flightWeatherStyle, _mapController?.style)) {
        final forecastFeatures = await controller.queryRenderedFeatures(
          QueryGeometry.point(event.screenPoint),
          layerIds: [
            forecastHitLayer,
            forecastWindLayer,
            forecastLabelLayer,
            'flight-weather-point-wind',
            'flight-weather-point-label',
          ],
        );
        for (final f in forecastFeatures) {
          featureMaps.add({
            'properties': f.properties,
            'layerType': 'flight-weather',
          });
        }
      }

      if (!isCurrent()) return;
      debugPrint('Tapped features: $featureMaps');
      onFeaturesTapped(featureMaps, event.point);
    } catch (e) {
      if (!isCurrent()) return;
      debugPrint('Error querying map features: $e');
      onFeaturesTapped(const [], event.point);
    }
  }

  bool get isMovingProgrammatically {
    if (_programmaticMoveCount > 0 ||
        _interpolationTicker != null ||
        _isTransitionAnimating) {
      return true;
    }
    final lastMove = _lastProgrammaticMoveTime;
    if (lastMove != null) {
      final elapsed = DateTime.now().difference(lastMove);
      if (elapsed < const Duration(milliseconds: 300)) {
        return true;
      }
    }
    return false;
  }

  void _updateNavigationRouteOnMap({
    bool force = false,
    bool retrying = false,
  }) {
    if (!retrying) {
      _routeRetryTimer?.cancel();
      _routeRetryTimer = null;
      _routeRetryAttempts = 0;
    }
    final style = _mapController?.style;
    if (!_isAircraftSymbolInitialized || style == null) return;

    if (force) {
      _routeUpdateTimer?.cancel();
      _routeUpdateTimer = null;
    } else if (_lastRouteUpdateTime case final previous?) {
      final remaining =
          const Duration(seconds: 2) - clock.now().difference(previous);
      if (remaining > Duration.zero) {
        // Coalesce position changes, but always deliver the latest one even
        // when no further GPS sample arrives (for example while stationary).
        _routeUpdateTimer ??= Timer(remaining, () {
          _routeUpdateTimer = null;
          if (ref.mounted) _updateNavigationRouteOnMap(force: true);
        });
        return;
      }
    }
    if (_routeWriting) {
      _pendingRouteForce = force || (_pendingRouteForce ?? false);
      return;
    }
    final data = _buildNavigationGeoJson();
    if (_lastNavigationRouteUpdate == (style: style, data: data)) return;
    _lastRouteUpdateTime = clock.now();
    _routeWriting = true;
    unawaited(_writeNavigationRoute(style, data));
  }

  Future<void> _writeNavigationRoute(StyleController style, String data) async {
    try {
      await style.sources.updateGeoJsonData(
        'navigation-route-source',
        GeoJsonData.text(data),
      );
      if (ref.mounted && identical(style, _mapController?.style)) {
        _lastNavigationRouteUpdate = (style: style, data: data);
        _routeRetryAttempts = 0;
      }
    } catch (error) {
      if (ref.mounted && identical(style, _mapController?.style)) {
        _lastNavigationRouteUpdate = null;
        if (_routeRetryAttempts < 3) {
          _routeRetryAttempts++;
          _routeRetryTimer?.cancel();
          _routeRetryTimer = Timer(
            Duration(milliseconds: 250 * _routeRetryAttempts),
            () {
              _routeRetryTimer = null;
              if (ref.mounted && identical(style, _mapController?.style)) {
                _updateNavigationRouteOnMap(force: true, retrying: true);
              }
            },
          );
        }
      }
      debugPrint('Navigation route update failed: $error');
    } finally {
      _routeWriting = false;
      final pending = _pendingRouteForce;
      _pendingRouteForce = null;
      if (ref.mounted && pending != null) {
        _updateNavigationRouteOnMap(force: pending);
      }
    }
  }

  MapStyleData get _styleData => MapStyleData(
    ref,
    routeOrigin: _lastKnownRouteOrigin,
    toScreenLocation: _mapController?.toScreenLocation,
  );

  String _buildNavigationGeoJson() {
    final telemetry = ref.read(telemetryProvider);
    final position = _navigationPosition(
      telemetry.latitude,
      telemetry.longitude,
    );
    if (position != null) _lastKnownRouteOrigin = position;
    return _styleData.buildNavigationGeoJson();
  }

  String _buildTrafficGeoJson(List<TrafficAircraft> traffic) =>
      _styleData.buildTrafficGeoJson(traffic);

  String _buildFavoritesGeoJson() => _styleData.buildFavoritesGeoJson();

  Geographic? _navigationPosition(double? latitude, double? longitude) =>
      GeoUtils.validatedPosition(latitude, longitude);

  void updateFavoritesOnMap() {
    if (_mapController == null ||
        !_isAircraftSymbolInitialized ||
        _mapController?.style == null) {
      return;
    }

    _mapController!.style!.sources.updateGeoJsonData(
      'favorites-source',
      GeoJsonData.text(_buildFavoritesGeoJson()),
    );
  }
}
