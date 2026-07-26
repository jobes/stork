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

      final trafficBytes = await _loadAndTintImage(
        'assets/images/aircraft.png',
        const Color(0xFF2196F3),
      );
      if (!refAccess.mounted) return;
      await style.addImage('traffic-aircraft-icon', trafficBytes);
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
          id: 'traffic-layer',
          sourceId: 'traffic-source',
          layout: {
            'icon-image': 'traffic-aircraft-icon',
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
      _updateOgnFilter();
      debugPrint('Aircraft symbol initialized 😎');
    } catch (e) {
      debugPrint('Error initializing native aircraft symbol: $e');
    }
  }
}

Future<Uint8List> _loadAndTintImage(String assetPath, Color color) async {
  final data = await rootBundle.load(assetPath);
  final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
  final frame = await codec.getNextFrame();
  final image = frame.image;

  final pictureRecorder = ui.PictureRecorder();
  final canvas = Canvas(pictureRecorder);
  final paint = Paint()
    ..colorFilter = ColorFilter.mode(color, BlendMode.modulate);
  canvas.drawImage(image, Offset.zero, paint);
  
  final tintedImage = await pictureRecorder.endRecording().toImage(image.width, image.height);
  final byteData = await tintedImage.toByteData(format: ui.ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}
