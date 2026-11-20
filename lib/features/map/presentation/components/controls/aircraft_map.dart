import 'package:flutter/material.dart';
import 'package:maplibre/maplibre.dart';

import '../../providers/map_style_preparer.dart';

import '../../../../../core/constants/map_constants.dart';
import '../../../../../core/theme/stork_colors.dart';

class AircraftMap extends StatefulWidget {
  final PreparedMapStyle style;
  final Geographic initialCenter;
  final double initialZoom;
  final double initialPitch;
  final double initialBearing;
  final Geographic? searchPin;
  final Function(MapController) onMapCreated;
  final void Function(StyleController, PreparedMapStyle preparedStyle)
  onStyleLoaded;
  final Function(MapEvent) onEvent;
  final VoidCallback onUserInteraction;

  const AircraftMap({
    super.key,
    required this.style,
    this.initialCenter = const Geographic(lon: 17.11, lat: 48.15),
    this.initialZoom = 6,
    this.initialPitch = 0,
    this.initialBearing = 0,
    this.searchPin,
    required this.onMapCreated,
    required this.onStyleLoaded,
    required this.onEvent,
    required this.onUserInteraction,
  });

  @override
  State<AircraftMap> createState() => _AircraftMapState();
}

class _AircraftMapState extends State<AircraftMap> {
  late PreparedMapStyle _requestedStyle = widget.style;
  bool _mapCreated = false;
  bool _loadingStyle = true;

  @override
  void didUpdateWidget(covariant AircraftMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    _applyStyle();
  }

  void _applyStyle() {
    if (!_mapCreated ||
        _loadingStyle ||
        _requestedStyle.json == widget.style.json) {
      return;
    }
    // Coalesce slider changes while the native map is loading a style.
    setState(() {
      _requestedStyle = widget.style;
      _loadingStyle = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => widget.onUserInteraction(),
      onPointerMove: (_) => widget.onUserInteraction(),
      child: MapLibreMap(
        options: MapOptions(
          initCamera: CameraUpdate.position(
            center: widget.initialCenter,
            zoom: widget.initialZoom,
            pitch: widget.initialPitch,
            bearing: widget.initialBearing,
          ),
          maxZoom: kMaxMapZoom.toDouble(),
          style: MapStyle.json(_requestedStyle.json),
          movements: MapMovements(
            rotate: false,
            pitch: false,
            pan: true,
            zoom: true,
          ),
        ),
        onMapCreated: (controller) {
          _mapCreated = true;
          widget.onMapCreated(controller);
          _applyStyle();
        },
        onStyleLoaded: (style) {
          _loadingStyle = false;
          if (_requestedStyle.json == widget.style.json) {
            widget.onStyleLoaded(style, _requestedStyle);
          } else {
            _applyStyle();
          }
        },
        onClick: widget.onEvent,
        onCameraMoveStart: widget.onEvent,
        onCameraMove: widget.onEvent,
        onCameraMoveEnd: widget.onEvent,
        children: [
          if (widget.searchPin case final point?)
            WidgetLayer(
              markers: [
                Marker(
                  point: point,
                  size: const Size.square(40),
                  alignment: Alignment.bottomCenter,
                  child: const Icon(
                    Icons.location_on,
                    size: 40,
                    color: StorkColors.lightPrimary,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
