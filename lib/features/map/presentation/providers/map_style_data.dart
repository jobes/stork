import 'dart:convert';
import 'dart:ui' show Offset;

import 'package:clock/clock.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/material.dart' show ThemeMode, Brightness;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre/maplibre.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../core/startup/initial_map_camera.dart';
import '../../../../core/utils/geo_utils.dart';
import '../../../settings/presentation/providers/display_preferences_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../settings/domain/models/aircraft_type.dart';
import '../../../settings/domain/models/altitude_unit.dart';
import '../../../settings/domain/models/speed_unit.dart' as app;
import '../../../weather/domain/flight_forecast.dart';
import '../../../weather/presentation/providers/flight_weather_provider.dart';
import '../../../weather/presentation/providers/route_waypoint_weather_provider.dart';
import '../../../telemetry/presentation/providers/telemetry_provider.dart';
import '../../../telemetry/presentation/providers/traffic_provider.dart';
import '../../../telemetry/presentation/providers/agl_provider.dart';
import '../../../navigation/presentation/providers/navigation_provider.dart';
import '../../../favorites/presentation/providers/favorites_provider.dart';
import 'notams_provider.dart';
import 'airspace_activity_provider.dart';
import 'map_overlay_style.dart';
import 'map_style_preparer.dart';

import '../../domain/utils/airspace_activity_utils.dart';
import '../../utils/flight_weather_geojson.dart';
import '../../utils/geojson_builder.dart';

const double kTrafficLookaheadPeriodSeconds = 10.0;
const double kTrafficBaseIconSizePx = 64.0;

/// Captures provider values for preparation and builds the same data for live updates.
class MapStyleData {
  const MapStyleData(this.ref, {this.routeOrigin, this.toScreenLocation});
  final Ref ref;
  final Geographic? routeOrigin;
  final Offset Function(Geographic)? toScreenLocation;

  Object inputs() => (
    ref.read(telemetryProvider),
    ref.read(navigationProvider).value,
    ref.read(favoritesProvider).value,
    ref.read(notamsProvider),
    ref.read(flightWeatherPlanProvider),
    ref.read(routePointWindsProvider),
    ref.read(displayPreferencesProvider).value,
    ref.read(appSettingsProvider).value,
    ref.read(filteredTrafficProvider),
  );

  PreparedMapStyle prepare(String baseStyle) {
    final capturedInputs = inputs();
    final telemetry = ref.read(telemetryProvider);
    final settings = ref.read(appSettingsProvider).value;
    final noticesState = ref.read(notamsProvider);
    final notices =
        (noticesState.hasError ? null : noticesState.value)?.notams ?? [];
    final visible = <NotamMapFeature>[
      for (final notam in notices)
        if (notam.radius > 0)
          (
            key: notam.key,
            id: notam.id,
            title: notam.featureName.isEmpty ? notam.msg : notam.featureName,
            lat: notam.latitude,
            lon: notam.longitude,
            radius: notam.radius,
          ),
    ];

    final data = <String, String>{
      'course-line-source': GeoJsonBuilder.buildCourseLineGeoJson(
        telemetry,
        settings,
      ),
      'navigation-route-source': buildNavigationGeoJson(),
      'notams-source': buildNotamGeoJson(visible),
      'aircraft-source': GeoJsonBuilder.buildAircraftGeoJson(
        telemetry.latitude,
        telemetry.longitude,
        telemetry.heading,
      ),
      'traffic-source': buildTrafficGeoJson(ref.read(filteredTrafficProvider)),
      'favorites-source': buildFavoritesGeoJson(),
      forecastSource: buildFlightWeatherGeoJson(flightWeatherInput()),
    };
    final activities = splitAirspaceActivityIds(
      ref.read(airspaceActivityProvider),
      clock.now(),
    );
    return const MapStylePreparer().prepare(
      baseStyle: baseStyle,
      data: data,
      fontScale: settings?.mapFontSize ?? 1,
      palette: forecastPalette(),
      inputs: capturedInputs,
      notams: visible,
      activeIds: activities.activeIds,
      inactiveIds: activities.inactiveIds,
    );
  }

  MapOverlayStyle overlays() {
    final prepared = prepare('{"version":8,"sources":{},"layers":[]}');
    return MapOverlayStyle.build(
      data: prepared.snapshot.sources,
      fontScale: ref.read(appSettingsProvider).value?.mapFontSize ?? 1,
      palette: prepared.snapshot.palette,
    );
  }

  String buildTrafficGeoJson(List<TrafficAircraft> traffic) {
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
            final p1 = toScreenLocation!(startCoord);
            final p2 = toScreenLocation!(destCoord);
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

  String buildNavigationGeoJson() {
    final telemetry = ref.read(telemetryProvider);
    final livePosition = GeoUtils.validatedPosition(
      telemetry.latitude,
      telemetry.longitude,
    );
    final prepared = ref.read(initialMapCameraProvider);
    return GeoJsonBuilder.buildNavigationRouteGeoJson(
      ref.read(navigationProvider).value,
      origin:
          livePosition ??
          routeOrigin ??
          (prepared?.hasLocation == true
              ? GeoUtils.validatedPosition(
                  prepared!.center.lat,
                  prepared.center.lon,
                )
              : null),
    );
  }

  String buildFavoritesGeoJson() {
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

  ForecastPalette forecastPalette() {
    final mode =
        ref.read(displayPreferencesProvider).value?.themeMode ??
        ThemeMode.system;
    final dark =
        mode == ThemeMode.dark ||
        (mode == ThemeMode.system &&
            SchedulerBinding.instance.platformDispatcher.platformBrightness ==
                Brightness.dark);
    return dark ? forecastDark : forecastLight;
  }

  FlightWeatherMapInput flightWeatherInput() {
    final settings = ref.read(appSettingsProvider).value;
    final enabled = settings?.showFlightWeather ?? false;
    final points = ref.read(flightWeatherPlanProvider);
    final route = ref.read(navigationProvider).value?.points ?? [];
    final favorites = ref.read(favoritesProvider).value ?? [];
    final start = points.isEmpty ? null : points.first;
    final aircraftAtStart = start != null && isAircraftForecastPoint(start.id);
    if (!enabled || !aircraftAtStart) {
      return (
        enabled: enabled,
        points: points,
        route: route,
        favorites: favorites,
        winds: const {},
      );
    }
    final unit = settings?.windSpeedUnit ?? app.SpeedUnit.kmh;
    final language =
        ref.read(displayPreferencesProvider).value?.language ??
        AppLanguage.system;
    final l10n = lookupAppLocalizations(language.resolvedLocale);
    final unitLabel = unit.getAbbreviation(l10n);
    final pointWinds = ref.read(routePointWindsProvider);
    final winds = <String, ForecastWindMarker>{};
    for (final point in points) {
      final data = pointWinds[point.id];
      final isAircraft = isAircraftForecastPoint(point.id);
      if (data == null && !isAircraft) continue;
      final wind = data?.wind;
      final speed = wind == null
          ? null
          : unit.convertFromMs(wind.speedMs).round();
      final gust = data?.gustMs;
      winds[point.id] = (
        arrow: wind == null
            ? '·'
            : wind.speedMs < 0.05
            ? '○'
            : '↑',
        direction: wind == null ? 0.0 : (wind.directionFrom + 180) % 360,
        label: [
          if (speed != null) '$speed $unitLabel',
          if (gust != null)
            '${l10n.weatherGustMapLabel} ${unit.convertFromMs(gust).round()}',
        ].join('\n'),
      );
    }
    return (
      enabled: enabled,
      points: points,
      route: route,
      favorites: favorites,
      winds: winds,
    );
  }
}
