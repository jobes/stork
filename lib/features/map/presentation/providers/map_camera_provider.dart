import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/material.dart'
    show ThemeMode, Brightness, WidgetsBinding, WidgetsBindingObserver;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre/maplibre.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../core/services/location_provider.dart';
import '../../../../core/startup/initial_map_camera.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/utils/geo_utils.dart';
import '../../../settings/presentation/providers/display_preferences_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../settings/domain/models/aircraft_type.dart';
import '../../../settings/domain/models/altitude_unit.dart';
import '../../../settings/domain/models/speed_unit.dart' as app;
import '../../../weather/domain/flight_forecast.dart';
import '../../../weather/presentation/providers/flight_weather_provider.dart';
import '../../../weather/presentation/providers/route_waypoint_weather_provider.dart';
import '../../../telemetry/domain/models/map_view_state.dart';
import '../../../telemetry/presentation/providers/telemetry_provider.dart';
import '../../../telemetry/presentation/providers/traffic_provider.dart';
import '../../../telemetry/presentation/providers/agl_provider.dart';
import '../../../navigation/presentation/providers/navigation_provider.dart';
import '../../../favorites/presentation/providers/favorites_provider.dart';
import 'notams_provider.dart';
import 'airspace_activity_provider.dart';
import 'airspace_highlight_layers.dart';
import 'map_overlay_style.dart';
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

const double kTrafficLookaheadPeriodSeconds = 10.0;
const double kTrafficBaseIconSizePx = 64.0;

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
  final _preparedStyles = <String, _PreparedOverlaySnapshot>{};
  Object? _preparedOverlayInputs;
  Map<String, String> _preparedSourceData = const {};
  List<_NotamMapFeature> _preparedNotamFeatures = const [];
  ForecastPalette? _preparedForecastPalette;
  List<String> _preparedActiveAirspaceIds = const [];
  List<String> _preparedInactiveAirspaceIds = const [];
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
  List<_NotamMapFeature>? _lastNotamMapFeatures = const [];

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
            _mapController!.style!.updateGeoJsonSource(
              id: 'aircraft-source',
              data: GeoJsonBuilder.buildAircraftGeoJson(
                next.latitude,
                next.longitude,
                next.heading,
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
        final center = Geographic(
          lon: next.longitude ?? 0.0,
          lat: next.latitude ?? 0.0,
        );

        if (next.mapViewState == MapViewState.follow) {
          _hasExplicitFocus = false;
          if (next.latitude != null &&
              next.longitude != null &&
              next.latitude != 0.0 &&
              next.longitude != 0.0 &&
              !_isFollowPaused &&
              !_isTransitionAnimating) {
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
              !_hasExplicitFocus) {
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
    if (!_hasExplicitFocus &&
        telemetry.latitude != null &&
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
          pitch: telemetry.mapViewState == MapViewState.follow
              ? settings.mapFollowPitch
              : 0.0,
          animate: false,
        ),
      );
    }
  }

  /// Moves the camera. A lat/lon of exactly 0.0 is treated as an invalid
  /// telemetry coordinate and the move is skipped unless [allowZeroCoordinate]
  /// is set (used for explicit points, e.g. a favourite on the Equator /
  /// Prime Meridian).
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
        (allowZeroCoordinate || (center.lat != 0 && center.lon != 0))) {
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
    if (event is MapEventMoveCamera) {
      handleUserInteraction(isExplicitInteraction: false);
      _scheduleTrafficViewportUpdate();
    }
    if (event is MapEventCameraIdle) {
      // Frame-by-frame follow can emit idle events between programmatic moves.
      // Share the existing viewport timer instead of rebuilding traffic per tick.
      if (!_isFollowPaused &&
          isMovingProgrammatically &&
          ref.read(telemetryProvider).mapViewState == MapViewState.follow) {
        _refreshTrafficAfterCameraMove = true;
        _scheduleTrafficViewportUpdate();
        return;
      }
      _moveThrottleTimer?.cancel();
      _refreshTrafficAfterCameraMove = false;
      _updateTrafficFilter();
      updateTrafficOnMap();
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
      final refreshTraffic = _refreshTrafficAfterCameraMove;
      _refreshTrafficAfterCameraMove = false;
      _updateTrafficFilter();
      if (refreshTraffic) updateTrafficOnMap();
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
      _mapController!.style!.updateGeoJsonSource(
        id: 'traffic-source',
        data: jsonEncode({'type': 'FeatureCollection', 'features': []}),
      );
      return;
    }

    _mapController!.style!.updateGeoJsonSource(
      id: 'traffic-source',
      data: _buildTrafficGeoJson(traffic),
    );
  }

  String _buildTrafficGeoJson(List<TrafficAircraft> traffic) {
    if (traffic.isEmpty) return emptyFlightWeatherGeoJson;
    final now = DateTime.now();

    final telemetry = ref.read(telemetryProvider);
    final settings = ref.read(appSettingsProvider).value;
    final resolvedAlt = ref.read(resolvedAltitudeProvider).mslValue;
    final myAlt = resolvedAlt ?? telemetry.gpsAltitude ?? 0.0;
    final altUnit = settings?.heightUnit ?? AltitudeUnit.meters;

    final features = traffic.map((ac) {
      final acType = AircraftType.fromOgnCode(ac.aircraftType);
      final isFlying = ac.groundSpeed > 1.0;
      final iconId = acType.trafficMapIconId;

      double possiblePositionRatio = 0.0;
      if (isFlying && ac.groundSpeed > 0) {
        final elapsedSeconds =
            now.difference(ac.lastSeen).inMilliseconds / 1000.0;
        final delay = elapsedSeconds + kTrafficLookaheadPeriodSeconds;

        if (delay > 0) {
          final distanceMeters = ac.groundSpeed * delay;
          final startCoord = Geographic(lat: ac.latitude, lon: ac.longitude);
          final destCoord = GeoUtils.calculateDestination(
            startCoord,
            ac.track,
            distanceMeters,
          );

          try {
            final p1 = _mapController!.toScreenLocation(startCoord);
            final p2 = _mapController!.toScreenLocation(destCoord);
            final distancePoints = (p1 - p2).distance;
            possiblePositionRatio = distancePoints / kTrafficBaseIconSizePx;
          } catch (_) {
            possiblePositionRatio = 0.0;
          }
        }
      }

      final String altitudeTagStr;
      if (ac.isCollisionThreat) {
        final language =
            ref.read(displayPreferencesProvider).value?.language ??
            AppLanguage.system;
        final l10n = lookupAppLocalizations(language.resolvedLocale);
        final diffMeters = ac.altitude - myAlt;
        final unitLabel = altUnit.getLabel(l10n);
        final String tagNum;
        if (altUnit == AltitudeUnit.feet ||
            altUnit == AltitudeUnit.flightLevel) {
          final diffFeet = (diffMeters / 0.3048).round();
          if (diffFeet > 0) {
            tagNum = l10n.aboveAltLabel('$diffFeet$unitLabel');
          } else if (diffFeet < 0) {
            tagNum = l10n.belowAltLabel('${diffFeet.abs()}$unitLabel');
          } else {
            tagNum = l10n.sameAltLabel;
          }
        } else {
          final diffM = diffMeters.round();
          if (diffM > 0) {
            tagNum = l10n.aboveAltLabel('$diffM$unitLabel');
          } else if (diffM < 0) {
            tagNum = l10n.belowAltLabel('${diffM.abs()}$unitLabel');
          } else {
            tagNum = l10n.sameAltLabel;
          }
        }
        final String trend = ac.verticalSpeed > 0.5
            ? ' ▲'
            : (ac.verticalSpeed < -0.5 ? ' ▼' : '');
        altitudeTagStr = '$tagNum$trend';
      } else {
        altitudeTagStr = '';
      }

      return {
        'type': 'Feature',
        'id': ac.id,
        'geometry': {
          'type': 'Point',
          'coordinates': [ac.longitude, ac.latitude],
        },
        'properties': {
          'id': ac.id,
          'heading': ac.track,
          'title': ac.callsign,
          'altitude': ac.altitude,
          'groundSpeed': ac.groundSpeed,
          'verticalSpeed': ac.verticalSpeed,
          'icon-image': iconId,
          'altitudeTag': altitudeTagStr,
          'isThreat': ac.isCollisionThreat,
          'isFlying': isFlying,
          'possiblePositionRatio': possiblePositionRatio,
        },
      };
    }).toList();

    return jsonEncode({'type': 'FeatureCollection', 'features': features});
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

  void _updateTrafficFilter() {
    if (_mapController == null) return;
    try {
      final bounds = _mapController!.getVisibleRegion();
      ref.read(trafficProvider.notifier).updateViewport(bounds);
    } catch (e) {
      debugPrint('Failed to update traffic filter bounds: $e');
    }
  }

  Future<void> _handleMapClick(
    MapEventClick event,
    Function(List<dynamic> features, Geographic coordinate) onFeaturesTapped,
  ) async {
    if (_mapController == null) return;
    try {
      final airportFeatures = _mapController!.featuresAtPoint(
        event.screenPoint,
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

      final airspaceFeatures = _mapController!.featuresAtPoint(
        event.screenPoint,
        layerIds: ['airspace_clicktarget'],
      );

      final placeFeatures = _mapController!.featuresAtPoint(
        event.screenPoint,
        layerIds: ['places_locality'],
      );

      final notamFeatures = _mapController!.featuresAtPoint(
        event.screenPoint,
        layerIds: ['notams-fill-layer'],
      );

      final favoriteFeatures = _mapController!.featuresAtPoint(
        event.screenPoint,
        layerIds: ['favorites-layer'],
      );

      final trafficFeatures = _mapController!.featuresAtPoint(
        event.screenPoint,
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
        final forecastFeatures = _mapController!.featuresAtPoint(
          event.screenPoint,
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

      debugPrint('Tapped features: $featureMaps');
      onFeaturesTapped(featureMaps, event.point);
    } catch (e) {
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
      await style.updateGeoJsonSource(
        id: 'navigation-route-source',
        data: data,
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

  Geographic? _navigationPosition(double? latitude, double? longitude) =>
      GeoUtils.validatedPosition(latitude, longitude);

  String _buildNavigationGeoJson() {
    final telemetry = ref.read(telemetryProvider);
    final livePosition = _navigationPosition(
      telemetry.latitude,
      telemetry.longitude,
    );
    if (livePosition != null) _lastKnownRouteOrigin = livePosition;
    final prepared = ref.read(initialMapCameraProvider);
    return GeoJsonBuilder.buildNavigationRouteGeoJson(
      ref.read(navigationProvider).value,
      origin:
          _lastKnownRouteOrigin ??
          (prepared?.hasLocation == true
              ? _navigationPosition(prepared!.center.lat, prepared.center.lon)
              : null),
    );
  }

  void updateFavoritesOnMap() {
    if (_mapController == null ||
        !_isAircraftSymbolInitialized ||
        _mapController?.style == null) {
      return;
    }

    _mapController!.style!.updateGeoJsonSource(
      id: 'favorites-source',
      data: _buildFavoritesGeoJson(),
    );
  }

  String _buildFavoritesGeoJson() {
    final favorites = ref.read(favoritesProvider).value ?? [];

    final features = favorites.map((f) {
      return {
        'type': 'Feature',
        'id': f.id,
        'geometry': {
          'type': 'Point',
          'coordinates': [f.longitude, f.latitude],
        },
        'properties': {
          'id': f.id,
          'icon-image': f.icon.mapIconId,
          'name': f.name,
          'description': f.description,
        },
      };
    }).toList();

    return jsonEncode({'type': 'FeatureCollection', 'features': features});
  }
}
