import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart'
    show Color, Paint, Canvas, ColorFilter, BlendMode, Offset;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre/maplibre.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../core/services/location_provider.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/utils/geo_utils.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../settings/domain/models/aircraft_type.dart';
import '../../../settings/domain/models/altitude_unit.dart';
import '../../../telemetry/domain/models/map_view_state.dart';
import '../../../telemetry/presentation/providers/telemetry_provider.dart';
import '../../../telemetry/presentation/providers/traffic_provider.dart';
import '../../../telemetry/presentation/providers/agl_provider.dart';
import '../../../navigation/presentation/providers/navigation_provider.dart';
import 'notams_provider.dart';
import 'airspace_activity_provider.dart';
import 'airspace_highlight_layers.dart';
import '../../domain/utils/airspace_activity_utils.dart';
import '../../utils/geojson_builder.dart';

part 'map_camera_provider.g.dart';
part 'map_camera_interpolation.dart';
part 'map_camera_style.dart';
part 'map_camera_airspace.dart';

const double kTrafficLookaheadPeriodSeconds = 10.0;
const double kTrafficBaseIconSizePx = 64.0;

@riverpod
class MapCamera extends _$MapCamera {
  // Helper to access ref from part-files without protected member warnings
  dynamic get refAccess => ref;

  MapController? _mapController;
  final _controllerCompleter = Completer<MapController>();
  Timer? _followResumeTimer;
  bool _isFollowPaused = false;
  Object? _activeTransitionToken;
  bool get _isTransitionAnimating => _activeTransitionToken != null;
  int _programmaticMoveCount = 0;
  DateTime? _lastProgrammaticMoveTime;
  bool _isAircraftSymbolInitialized = false;

  // Last applied airspace activity id lists, used to skip redundant map style
  // updates (removeLayer + addLayer) when nothing changed.
  List<String>? _lastActiveAirspaceIds;
  List<String>? _lastInactiveAirspaceIds;

  // In-flight airspace highlight application, used to serialize concurrent
  // updateAirspacesOnMap() executions so layer mutations cannot interleave.
  Future<void>? _airspaceHighlightInFlight;

  Timer? _interpolationTimer;
  Geographic? _currentInterpolatedCenter;
  double? _currentInterpolatedZoom;
  double? _currentInterpolatedPitch;
  double? _currentInterpolatedBearing;
  DateTime? _lastUpdateTimestamp;
  Duration _lastUpdateInterval = const Duration(seconds: 1);
  DateTime? _lastRouteUpdateTime;

  @override
  void build() {
    // Listen to telemetry updates to move camera
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
        if (_mapController == null) return;

        // Update navigation route on map if position changed
        if (next.latitude != previous?.latitude ||
            next.longitude != previous?.longitude) {
          _updateNavigationRouteOnMap();
        }

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

          if (next.latitude != previous?.latitude ||
              next.longitude != previous?.longitude ||
              next.heading != previous?.heading ||
              next.groundSpeed != previous?.groundSpeed ||
              next.indicatedAirSpeed != previous?.indicatedAirSpeed ||
              next.isFlying != previous?.isFlying) {
            final settings = ref.read(appSettingsProvider).value;
            final telemetry = ref.read(telemetryProvider);
            _mapController!.style!.updateGeoJsonSource(
              id: 'course-line-source',
              data: GeoJsonBuilder.buildCourseLineGeoJson(telemetry, settings),
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
              !_isFollowPaused &&
              !_isTransitionAnimating) {
            final isContinuousFollow =
                previous?.mapViewState == MapViewState.follow;

            // Only interpolate if coordinates or heading actually changed
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
      updateTrafficOnMap();
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

    // Listen to navigation updates to redraw route on map
    ref.listen(navigationProvider, (previous, next) {
      _updateNavigationRouteOnMap(force: true);
    });

    // Listen to NOTAMs updates to redraw NOTAMs on map
    ref.listen(notamsProvider, (previous, next) {
      if (next.hasValue) {
        updateNotamsOnMap();
      }
    });

    // Listen to airspace activity (AUP/UUP) updates to redraw airspaces on map
    ref.listen(airspaceActivityProvider, (previous, next) {
      unawaited(updateAirspacesOnMap());
    });

    // Listen to traffic updates to redraw traffic on map
    ref.listen(filteredTrafficProvider, (previous, next) {
      updateTrafficOnMap(next);
    });

    // Periodic timer to recalculate possible location cone as time elapses
    final trafficTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (_mapController != null && _isAircraftSymbolInitialized) {
        final currentTraffic = ref.read(filteredTrafficProvider);
        if (currentTraffic.isNotEmpty) {
          updateTrafficOnMap(currentTraffic);
        }
      }
    });

    // Clean up timer on dispose
    ref.onDispose(() {
      trafficTimer.cancel();
      _moveThrottleTimer?.cancel();
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

  void handleUserInteraction({bool isExplicitInteraction = true}) {
    // Only proceed if it's not a programmatical movement
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

  Timer? _moveThrottleTimer;

  bool get isAircraftSymbolInitialized => _isAircraftSymbolInitialized;
  MapController? get mapController => _mapController;

  void handleMapEvent(
    MapEvent event, {
    Function(List<dynamic> features, Geographic coordinate)? onFeaturesTapped,
  }) {
    if (event is MapEventMoveCamera) {
      handleUserInteraction(isExplicitInteraction: false);
      if (_moveThrottleTimer == null || !_moveThrottleTimer!.isActive) {
        _moveThrottleTimer = Timer(const Duration(milliseconds: 500), () {
          _updateTrafficFilter();
        });
      }
    }
    if (event is MapEventCameraIdle) {
      _moveThrottleTimer?.cancel();
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

    final now = DateTime.now();

    final telemetry = ref.read(telemetryProvider);
    final settings = ref.read(appSettingsProvider).value;
    final resolvedAlt = ref.read(resolvedAltitudeProvider).mslValue;
    final myAlt = resolvedAlt ?? telemetry.gpsAltitude ?? 0.0;
    final altUnit = settings?.heightUnit ?? AltitudeUnit.meters;

    final features = traffic.map((ac) {
      final acType = AircraftType.fromOgnCode(ac.aircraftType);
      final isFlying = ac.groundSpeed > 1.0;
      final iconId = ac.isCollisionThreat
          ? acType.threatTrafficMapIconId
          : (isFlying
                ? acType.trafficMapIconId
                : acType.inactiveTrafficMapIconId);

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
        final l10n = lookupAppLocalizations(
          ui.PlatformDispatcher.instance.locale,
        );
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
          'possiblePositionRatio': possiblePositionRatio,
        },
      };
    }).toList();

    _mapController!.style!.updateGeoJsonSource(
      id: 'traffic-source',
      data: jsonEncode({'type': 'FeatureCollection', 'features': features}),
    );
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
      for (final f in trafficFeatures) {
        featureMaps.add({
          'id': f.id,
          'properties': f.properties,
          'layerType': 'traffic',
        });
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
        _interpolationTimer != null ||
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

  void _updateNavigationRouteOnMap({bool force = false}) {
    if (_mapController == null ||
        !_isAircraftSymbolInitialized ||
        _mapController?.style == null) {
      return;
    }

    final now = DateTime.now();
    if (!force) {
      if (_lastRouteUpdateTime != null &&
          now.difference(_lastRouteUpdateTime!) < const Duration(seconds: 2)) {
        return;
      }
    }
    _lastRouteUpdateTime = now;

    final telemetry = ref.read(telemetryProvider);
    final navState = ref.read(navigationProvider).value;
    final points = navState?.points ?? [];
    final isActive = navState?.isActive ?? false;

    if (!isActive ||
        points.isEmpty ||
        telemetry.latitude == null ||
        telemetry.longitude == null ||
        (telemetry.latitude == 0.0 && telemetry.longitude == 0.0)) {
      _mapController!.style!.updateGeoJsonSource(
        id: 'navigation-route-source',
        data: jsonEncode({'type': 'FeatureCollection', 'features': []}),
      );
      return;
    }

    final List<List<double>> interpolatedCoordinates = [];
    double currentLat = telemetry.latitude!;
    double currentLon = telemetry.longitude!;

    for (final p in points) {
      final legPath = _interpolateGreatCircle(
        currentLat,
        currentLon,
        p.latitude,
        p.longitude,
      );
      if (legPath != null) {
        if (interpolatedCoordinates.isNotEmpty && legPath.isNotEmpty) {
          interpolatedCoordinates.addAll(legPath.skip(1));
        } else {
          interpolatedCoordinates.addAll(legPath);
        }
      }
      currentLat = p.latitude;
      currentLon = p.longitude;
    }

    if (interpolatedCoordinates.length < 2) {
      _mapController!.style!.updateGeoJsonSource(
        id: 'navigation-route-source',
        data: jsonEncode({'type': 'FeatureCollection', 'features': []}),
      );
      return;
    }

    final geojson = jsonEncode({
      'type': 'FeatureCollection',
      'features': [
        {
          'type': 'Feature',
          'geometry': {
            'type': 'LineString',
            'coordinates': interpolatedCoordinates,
          },
        },
      ],
    });

    _mapController!.style!.updateGeoJsonSource(
      id: 'navigation-route-source',
      data: geojson,
    );
  }

  List<List<double>>? _interpolateGreatCircle(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    if (lat1 == lat2 && lon1 == lon2) {
      return null;
    }

    final lat1Rad = lat1 * math.pi / 180.0;
    final lon1Rad = lon1 * math.pi / 180.0;
    final lat2Rad = lat2 * math.pi / 180.0;
    final lon2Rad = lon2 * math.pi / 180.0;

    final dLat = lat2Rad - lat1Rad;
    final dLon = lon2Rad - lon1Rad;
    final sinLatSq = math.sin(dLat / 2) * math.sin(dLat / 2);
    final sinLonSq = math.sin(dLon / 2) * math.sin(dLon / 2);
    final a = sinLatSq + math.cos(lat1Rad) * math.cos(lat2Rad) * sinLonSq;
    final d = 2 * math.asin(math.sqrt(math.min(1.0, a)));

    if (d < 1e-6) {
      return [
        [lon1, lat1],
        [lon2, lat2],
      ];
    }

    final distanceMeters = d * 6371000.0;
    final segments = (distanceMeters / 50000.0).clamp(5, 100).toInt();

    final List<List<double>> path = [];
    final sinD = math.sin(d);

    for (int i = 0; i <= segments; i++) {
      final f = i / segments;
      final weightA = math.sin((1.0 - f) * d) / sinD;
      final weightB = math.sin(f * d) / sinD;

      final x =
          weightA * math.cos(lat1Rad) * math.cos(lon1Rad) +
          weightB * math.cos(lat2Rad) * math.cos(lon2Rad);
      final y =
          weightA * math.cos(lat1Rad) * math.sin(lon1Rad) +
          weightB * math.cos(lat2Rad) * math.sin(lon2Rad);
      final z = weightA * math.sin(lat1Rad) + weightB * math.sin(lat2Rad);

      final lat = math.atan2(z, math.sqrt(x * x + y * y));
      final lon = math.atan2(y, x);

      path.add([lon * 180.0 / math.pi, lat * 180.0 / math.pi]);
    }

    return path;
  }

  void updateNotamsOnMap() {
    if (_mapController == null ||
        !_isAircraftSymbolInitialized ||
        _mapController?.style == null) {
      return;
    }

    final notamsAsync = ref.read(notamsProvider);
    final notams = notamsAsync.value ?? [];

    final List<Map<String, dynamic>> features = [];

    for (final notam in notams) {
      // Generate circle polygon coordinates
      final List<List<double>> ring = [];
      const int segments = 32;
      final latRad = notam.latitude * math.pi / 180.0;
      final lonRad = notam.longitude * math.pi / 180.0;
      final dRad =
          notam.radius /
          6371000.0; // Radius in meters divided by Earth's radius

      for (int i = 0; i <= segments; i++) {
        final double angle = i * 2.0 * math.pi / segments;
        final double destLatRad = math.asin(
          math.sin(latRad) * math.cos(dRad) +
              math.cos(latRad) * math.sin(dRad) * math.cos(angle),
        );
        final double destLonRad =
            lonRad +
            math.atan2(
              math.sin(angle) * math.sin(dRad) * math.cos(latRad),
              math.cos(dRad) - math.sin(latRad) * math.sin(destLatRad),
            );
        ring.add([destLonRad * 180.0 / math.pi, destLatRad * 180.0 / math.pi]);
      }

      features.add({
        'type': 'Feature',
        'id': notam.id,
        'properties': {
          'id': notam.id,
          'fir': notam.fir,
          'title': notam.featureName,
          'description': notam.msg,
          'startTime': notam.startDate,
          'endTime': notam.endDate,
          'lowerLimit': notam.lowerLimit2 ?? 'GND',
          'upperLimit': notam.upperLimit2 ?? 'UNL',
        },
        'geometry': {
          'type': 'Polygon',
          'coordinates': [ring],
        },
      });
    }

    final geojson = jsonEncode({
      'type': 'FeatureCollection',
      'features': features,
    });

    _mapController!.style!.updateGeoJsonSource(
      id: 'notams-source',
      data: geojson,
    );
  }
}
