part of 'map_camera_provider.dart';

extension MapCameraStyle on MapCamera {
  Future<void> handleStyleLoaded(StyleController style) async {
    try {
      // Load all aircraft type icons into style
      for (final type in AircraftType.values) {
        try {
          await style.addImageFromAssets(
            id: type.mapIconId,
            asset: type.assetPath,
          );
          if (!refAccess.mounted) return;

          // Clean untinted icon for flying traffic
          await style.addImageFromAssets(
            id: type.trafficMapIconId,
            asset: type.assetPath,
          );
          if (!refAccess.mounted) return;

          // Grey tinted icon for inactive (ground / stationary) traffic
          final inactiveBytes = await _loadAndTintImage(
            type.assetPath,
            const Color(0xFF9E9E9E),
          );
          if (!refAccess.mounted) return;
          await style.addImage(type.inactiveTrafficMapIconId, inactiveBytes);
          if (!refAccess.mounted) return;

          // Red tinted icon for threat traffic
          final threatBytes = await _loadAndTintImage(
            type.assetPath,
            const Color(0xFFFF0000),
          );
          if (!refAccess.mounted) return;
          await style.addImage(type.threatTrafficMapIconId, threatBytes);
          if (!refAccess.mounted) return;
        } catch (e) {
          debugPrint('Failed to load aircraft icon for ${type.name}: $e');
        }
      }

      // Traffic possible location indicator image
      await style.addImageFromAssets(
        id: 'possibleLoc',
        asset: 'assets/images/possible-loc.png',
      );
      if (!refAccess.mounted) return;

      // Legacy fallbacks
      await style.addImageFromAssets(
        id: 'aircraft-icon',
        asset: 'assets/images/aircraft.png',
      );
      if (!refAccess.mounted) return;

      final defaultTrafficBytes = await _loadAndTintImage(
        'assets/images/aircraft.png',
        const Color(0xFF2196F3),
      );
      if (!refAccess.mounted) return;
      await style.addImage('traffic-aircraft-icon', defaultTrafficBytes);
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
            'icon-size': 1 / 4,
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
            'icon-size': 0.12,
            'text-font': ['Roboto Regular,Noto Sans Regular'],
            'text-field': ['get', 'altitudeTag'],
            'text-size': 11.0 * mapFontSize,
            'text-offset': [1.4, 0],
            'text-anchor': 'left',
            'text-allow-overlap': true,
            'text-ignore-placement': true,
          },
          paint: {
            'text-color': [
              'case',
              [
                '==',
                ['get', 'isThreat'],
                true,
              ],
              '#FF3333',
              '#FFFFFF',
            ],
            'text-halo-color': '#000000',
            'text-halo-width': 1.5,
          },
        ),
      );
      if (!refAccess.mounted) return;

      _isAircraftSymbolInitialized = true;
      _updateNavigationRouteOnMap();
      updateNotamsOnMap();
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

Future<Uint8List> _loadAndTintImage(String assetPath, Color color) async {
  ui.Codec? codec;
  ui.Image? image;
  ui.Picture? picture;
  ui.Image? tintedImage;
  try {
    final data = await rootBundle.load(assetPath);
    codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    image = frame.image;

    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final paint = Paint()
      ..colorFilter = ColorFilter.mode(color, BlendMode.modulate);
    canvas.drawImage(image, Offset.zero, paint);

    picture = pictureRecorder.endRecording();
    tintedImage = await picture.toImage(image.width, image.height);
    final byteData = await tintedImage.toByteData(
      format: ui.ImageByteFormat.png,
    );
    if (byteData == null) {
      throw StateError(
        'Failed to convert tinted image to PNG byte data for $assetPath',
      );
    }
    return byteData.buffer.asUint8List();
  } finally {
    codec?.dispose();
    image?.dispose();
    picture?.dispose();
    tintedImage?.dispose();
  }
}
