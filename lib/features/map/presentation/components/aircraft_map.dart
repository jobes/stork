import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:maplibre/maplibre.dart';
import '../../../telemetry/domain/models/telemetry_state.dart';

class AircraftMap extends StatefulWidget {
  final String style;
  final TelemetryState telemetry;
  final Function(MapController) onMapCreated;
  final Function(StyleController) onStyleLoaded;
  final Function(MapEvent) onEvent;
  final VoidCallback onUserInteraction;

  const AircraftMap({
    super.key,
    required this.style,
    required this.telemetry,
    required this.onMapCreated,
    required this.onStyleLoaded,
    required this.onEvent,
    required this.onUserInteraction,
  });

  @override
  State<AircraftMap> createState() => _AircraftMapState();
}

class _AircraftMapState extends State<AircraftMap> {
  bool _isAircraftSymbolInitialized = false;
  MapController? _mapController;

  @override
  void didUpdateWidget(AircraftMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isAircraftSymbolInitialized && _mapController?.style != null) {
      // Update symbol position and rotation when telemetry changes
      if (widget.telemetry.latitude != oldWidget.telemetry.latitude ||
          widget.telemetry.longitude != oldWidget.telemetry.longitude ||
          widget.telemetry.heading != oldWidget.telemetry.heading) {
        if (widget.telemetry.latitude != 0 && widget.telemetry.longitude != 0) {
          _mapController!.style!.updateGeoJsonSource(
            id: 'aircraft-source',
            data: _getAircraftGeoJson(
              widget.telemetry.latitude,
              widget.telemetry.longitude,
              widget.telemetry.heading,
            ),
          );
        }
      }
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

  Future<void> _initNativeAircraftSymbol(
    StyleController style,
    TelemetryState telemetry,
  ) async {
    try {
      await style.addImageFromAssets(
        id: 'aircraft-icon',
        asset: 'assets/images/aircraft.png',
      );

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

      if (mounted) {
        setState(() {
          _isAircraftSymbolInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing native aircraft symbol: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => widget.onUserInteraction(),
      onPointerMove: (_) => widget.onUserInteraction(),
      child: MapLibreMap(
        options: MapOptions(
          initCenter: Geographic(lon: 0, lat: 0),
          initZoom: 2,
          maxZoom: 18,
          initStyle: widget.style,
          gestures: MapGestures(
            rotate: false,
            pitch: false,
            pan: true,
            zoom: true,
          ),
        ),
        onMapCreated: (controller) {
          _mapController = controller;
          widget.onMapCreated(controller);
        },
        onStyleLoaded: (style) async {
          await _initNativeAircraftSymbol(style, widget.telemetry);
          widget.onStyleLoaded(style);
        },
        onEvent: widget.onEvent,
      ),
    );
  }
}
