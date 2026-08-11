part of 'map_camera_provider.dart';

// Icon sizes relative to the sprite frames (see
// documentation/architecture/map-sprite.md). Kept as named constants so a
// sprite regeneration that changes frame sizes only needs updating here.
const double kAircraftIconSize = 0.88; // 192px frame -> previous size (676/4)
const double kTrafficIconSize = 0.40; // 128px SDF frame
const double kPoiIconSize = 0.64; // 64px frame

extension MapCameraStyle on MapCamera {
  Future<void> handleStyleLoaded(StyleController style) async {
    try {
      // All map icons come from the app sprite (`assets/map_sprites/`, sprite
      // id "default"): `aircraft-icon` (aircraft-layer), `possibleLoc`
      // (traffic-possible-layer), `traffic-icon-*` (traffic-layer, SDF
      // silhouettes tinted via the `icon-color` expression) and `poi-icon-*`
      // (favorites-layer). No icons are added programmatically here.

      final telemetry = refAccess.read(telemetryProvider);
      final settings = refAccess.read(appSettingsProvider).value;

      await style.addSource(
        GeoJsonSource(
          id: 'course-line-source',
          data: GeoJsonBuilder.buildCourseLineGeoJson(telemetry, settings),
        ),
      );
      if (!refAccess.mounted) return;

      await style.addLayer(
        LineStyleLayer(
          id: 'course-line-border',
          sourceId: 'course-line-source',
          paint: {'line-color': '#000000', 'line-width': 5.0},
        ),
      );
      if (!refAccess.mounted) return;

      await style.addLayer(
        LineStyleLayer(
          id: 'course-line-white',
          sourceId: 'course-line-source',
          filter: ['==', 'isEven', false],
          paint: {'line-color': '#FFFFFF', 'line-width': 3.0},
        ),
      );
      if (!refAccess.mounted) return;

      await style.addSource(
        GeoJsonSource(
          id: 'navigation-route-source',
          data: jsonEncode({'type': 'FeatureCollection', 'features': []}),
        ),
      );
      if (!refAccess.mounted) return;

      await style.addLayer(
        LineStyleLayer(
          id: 'navigation-route-border',
          sourceId: 'navigation-route-source',
          paint: {'line-color': '#000000', 'line-width': 6.0},
        ),
      );
      if (!refAccess.mounted) return;

      await style.addLayer(
        LineStyleLayer(
          id: 'navigation-route-line',
          sourceId: 'navigation-route-source',
          paint: {'line-color': '#FF9800', 'line-width': 3.5},
        ),
      );
      if (!refAccess.mounted) return;

      await style.addSource(
        GeoJsonSource(
          id: 'notams-source',
          data: jsonEncode({'type': 'FeatureCollection', 'features': []}),
        ),
      );
      if (!refAccess.mounted) return;

      await style.addLayer(
        FillStyleLayer(
          id: 'notams-fill-layer',
          sourceId: 'notams-source',
          paint: {'fill-color': '#FF5722', 'fill-opacity': 0.25},
        ),
      );
      if (!refAccess.mounted) return;

      await style.addLayer(
        LineStyleLayer(
          id: 'notams-line-layer',
          sourceId: 'notams-source',
          paint: {
            'line-color': '#FF5722',
            'line-width': 2.0,
            'line-dasharray': [2.0, 2.0],
          },
        ),
      );
      if (!refAccess.mounted) return;

      // Real-time airspace activity (AUP/UUP) highlight layers are defined in
      // `assets/openaip/styles.json` (on the existing `openaip-data` source)
      // and their filters are updated dynamically in `updateAirspacesOnMap()`.

      await style.addSource(
        GeoJsonSource(
          id: 'aircraft-source',
          data: GeoJsonBuilder.buildAircraftGeoJson(
            telemetry.latitude,
            telemetry.longitude,
            telemetry.heading,
          ),
        ),
      );
      if (!refAccess.mounted) return;

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
            'icon-size': kAircraftIconSize,
          },
        ),
      );
      if (!refAccess.mounted) return;

      await style.addSource(
        GeoJsonSource(
          id: 'traffic-source',
          data: jsonEncode({'type': 'FeatureCollection', 'features': []}),
        ),
      );
      if (!refAccess.mounted) return;

      await style.addLayer(
        SymbolStyleLayer(
          id: 'traffic-possible-layer',
          sourceId: 'traffic-source',
          layout: {
            'icon-image': 'possibleLoc',
            'icon-size': ['get', 'possiblePositionRatio'],
            'icon-rotate': ['get', 'heading'],
            'icon-rotation-alignment': 'map',
            'icon-pitch-alignment': 'map',
            'icon-allow-overlap': true,
            'icon-ignore-placement': false,
            'icon-optional': false,
            'icon-anchor': 'bottom',
          },
        ),
      );
      if (!refAccess.mounted) return;

      final mapFontSize = (settings?.mapFontSize ?? 1.0) * 1.5;

      await style.addLayer(
        SymbolStyleLayer(
          id: 'traffic-layer',
          sourceId: 'traffic-source',
          layout: {
            'icon-image': ['get', 'icon-image'],
            'icon-rotate': ['get', 'heading'],
            'icon-rotation-alignment': 'map',
            'icon-pitch-alignment': 'viewport',
            'icon-allow-overlap': true,
            'icon-ignore-placement': true,
            'icon-size': kTrafficIconSize,
            'text-font': ['Roboto Regular,Noto Sans Regular'],
            'text-field': ['get', 'altitudeTag'],
            'text-size': 11.0 * mapFontSize,
            'text-offset': [1.4, 0],
            'text-anchor': 'left',
            'text-allow-overlap': true,
            'text-ignore-placement': true,
          },
          paint: {
            'icon-color': [
              'case',
              [
                '==',
                ['get', 'isThreat'],
                true,
              ],
              mapColorHex(kTrafficThreatColor),
              [
                '==',
                ['get', 'isFlying'],
                true,
              ],
              mapColorHex(kTrafficFlyingColor),
              mapColorHex(kTrafficInactiveColor),
            ],
            'text-color': [
              'case',
              [
                '==',
                ['get', 'isThreat'],
                true,
              ],
              mapColorHex(kTrafficThreatColor),
              '#FFFFFF',
            ],
            'text-halo-color': '#000000',
            'text-halo-width': 1.5,
          },
        ),
      );
      if (!refAccess.mounted) return;

      // User favourite points (rendered with POI icons from PoiType)
      await style.addSource(
        GeoJsonSource(
          id: 'favorites-source',
          data: jsonEncode({'type': 'FeatureCollection', 'features': []}),
        ),
      );
      if (!refAccess.mounted) return;

      await style.addLayer(
        SymbolStyleLayer(
          id: 'favorites-layer',
          sourceId: 'favorites-source',
          layout: {
            'icon-image': ['get', 'icon-image'],
            'icon-size': kPoiIconSize,
            'icon-allow-overlap': true,
            'icon-ignore-placement': true,
            'text-font': ['Roboto Mono Regular,Noto Sans Regular'],
            'text-field': ['get', 'name'],
            'text-size': 12.0 * mapFontSize,
            'text-offset': [0, 0.8],
            'text-anchor': 'top',
            'text-allow-overlap': true,
            'text-ignore-placement': true,
          },
          paint: {'text-color': '#000000', 'text-halo-width': 0},
        ),
      );
      if (!refAccess.mounted) return;

      _isAircraftSymbolInitialized = true;
      _updateNavigationRouteOnMap();
      updateNotamsOnMap();
      updateFavoritesOnMap();
      // The (re)loaded style wiped the runtime highlight layers, so clear the
      // diff cache to force updateAirspacesOnMap to re-apply them.
      _lastActiveAirspaceIds = null;
      _lastInactiveAirspaceIds = null;
      await updateAirspacesOnMap();
      if (!refAccess.mounted) return;
      _updateTrafficFilter();
      debugPrint('Aircraft symbols initialized 😎');
    } catch (e) {
      debugPrint('Error initializing native aircraft symbol: $e');
    }
  }
}
