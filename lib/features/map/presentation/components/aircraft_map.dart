import 'package:flutter/material.dart';
import 'package:maplibre/maplibre.dart';

class AircraftMap extends StatelessWidget {
  final String style;
  final Function(MapController) onMapCreated;
  final Function(StyleController) onStyleLoaded;
  final Function(MapEvent) onEvent;
  final VoidCallback onUserInteraction;

  const AircraftMap({
    super.key,
    required this.style,
    required this.onMapCreated,
    required this.onStyleLoaded,
    required this.onEvent,
    required this.onUserInteraction,
  });

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => onUserInteraction(),
      onPointerMove: (_) => onUserInteraction(),
      child: MapLibreMap(
        options: MapOptions(
          initCenter: Geographic(lon: 0, lat: 0),
          initZoom: 2,
          maxZoom: 18,
          initStyle: style,
          gestures: MapGestures(
            rotate: false,
            pitch: false,
            pan: true,
            zoom: true,
          ),
        ),
        onMapCreated: onMapCreated,
        onStyleLoaded: onStyleLoaded,
        onEvent: onEvent,
      ),
    );
  }
}
