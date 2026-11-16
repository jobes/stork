import 'package:flutter/material.dart';
import 'package:maplibre/maplibre.dart';

import '../../../../../core/constants/map_constants.dart';

class AircraftMap extends StatefulWidget {
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
  State<AircraftMap> createState() => _AircraftMapState();
}

class _AircraftMapState extends State<AircraftMap> {
  late final String _initialStyle = widget.style;
  late String _requestedStyle = _initialStyle;
  MapController? _controller;
  bool _loadingStyle = true;

  @override
  void didUpdateWidget(covariant AircraftMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    _applyStyle();
  }

  void _applyStyle() {
    final controller = _controller;
    if (controller == null ||
        _loadingStyle ||
        _requestedStyle == widget.style) {
      return;
    }
    // Coalesce slider changes while the native map is loading a style.
    _requestedStyle = widget.style;
    _loadingStyle = true;
    controller.setStyle(_requestedStyle);
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
          maxZoom: kMaxMapZoom.toDouble(),
          initStyle: _initialStyle,
          gestures: MapGestures(
            rotate: false,
            pitch: false,
            pan: true,
            zoom: true,
          ),
        ),
        onMapCreated: (controller) {
          _controller = controller;
          widget.onMapCreated(controller);
          _applyStyle();
        },
        onStyleLoaded: (style) {
          _loadingStyle = false;
          if (_requestedStyle == widget.style) {
            widget.onStyleLoaded(style);
          } else {
            _applyStyle();
          }
        },
        onEvent: widget.onEvent,
      ),
    );
  }
}
