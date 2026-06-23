part of 'map_camera_provider.dart';

extension MapCameraStyle on MapCamera {
  Future<void> handleStyleLoaded(StyleController style) async {
    try {
      await style.addImageFromAssets(
        id: 'aircraft-icon',
        asset: 'assets/images/aircraft.png',
      );
      if (!refAccess.mounted) return;

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
          paint: {
            'fill-color': '#FF5722',
            'fill-opacity': 0.25,
          },
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
            'icon-size': 1 / 4,
          },
        ),
      );
      if (!refAccess.mounted) return;

      _isAircraftSymbolInitialized = true;
      _updateNavigationRouteOnMap();
      updateNotamsOnMap();
      debugPrint('Aircraft symbol initialized 😎');
    } catch (e) {
      debugPrint('Error initializing native aircraft symbol: $e');
    }
  }
}
