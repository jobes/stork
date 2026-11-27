import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:maplibre/maplibre.dart';

import '../../providers/map_style_preparer.dart';
import '../../../../../core/startup/startup_timing.dart';

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
  final FutureOr<void> Function(StyleController, PreparedMapStyle preparedStyle)
  onStyleLoaded;
  final Function(MapEvent) onEvent;
  final VoidCallback onUserInteraction;
  final void Function(CameraPosition camera)? onCameraPresented;
  final VoidCallback? onInitialViewReady;
  final void Function(Object error)? onInitialViewError;

  /// Signals the first native render frame, even while the map is not idle.
  /// The startup gate uses it to reveal a rendered map when remote tiles keep
  /// the map from becoming fully rendered before the deadline.
  final VoidCallback? onFirstFrameRendered;

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
    this.onCameraPresented,
    this.onInitialViewReady,
    this.onInitialViewError,
    this.onFirstFrameRendered,
  });

  @override
  State<AircraftMap> createState() => _AircraftMapState();
}

class _AircraftMapState extends State<AircraftMap> {
  late PreparedMapStyle _requestedStyle = widget.style;
  bool _mapCreated = false;
  bool _loadingStyle = true;
  bool _styleInitialized = false;
  bool _fullyRendered = false;
  bool _webResourcesLoaded = false;
  bool _initialReadySent = false;
  bool _readyScheduled = false;
  int _generation = 0;
  MapController? _controller;

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
      _generation++;
      _styleInitialized = false;
      _fullyRendered = false;
      _webResourcesLoaded = false;
      _readyScheduled = false;
    });
  }

  Future<void> _styleLoaded(StyleController style) async {
    if (!mounted) return;
    _loadingStyle = false;
    if (_requestedStyle.json != widget.style.json) {
      _applyStyle();
      return;
    }
    final generation = _generation;
    try {
      await widget.onStyleLoaded(style, _requestedStyle);
      if (!mounted ||
          generation != _generation ||
          !identical(style, _controller?.style)) {
        return;
      }
      _styleInitialized = true;
      _notifyFirstFrame();
      _tryReady();
    } catch (error) {
      if (mounted && generation == _generation) {
        widget.onInitialViewError?.call(error);
      }
    }
  }

  void _rendered(bool fullyRendered) {
    if (!mounted || _initialReadySent) return;
    _fullyRendered = fullyRendered;
    _tryReady();
  }

  bool _frameSeen = false;
  bool _firstFrameNotified = false;

  void _recordFrame() {
    _frameSeen = true;
    _notifyFirstFrame();
  }

  /// Reports the first frame only after the overlay style is initialized, so a
  /// deadline reveal never shows a map without its live layers.
  void _notifyFirstFrame() {
    if (!mounted || _firstFrameNotified || !_frameSeen || !_styleInitialized) {
      return;
    }
    _firstFrameNotified = true;
    widget.onFirstFrameRendered?.call();
  }

  void _tryReady() {
    if (_initialReadySent ||
        _readyScheduled ||
        !_styleInitialized ||
        !_fullyRendered) {
      return;
    }
    _readyScheduled = true;
    final generation = _generation;
    // Let Flutter composite the fully rendered native texture before revealing
    // the map. The app shell still blocks gestures and semantics behind it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || generation != _generation) return;
      _readyScheduled = false;
      if (!_styleInitialized || !_fullyRendered || _initialReadySent) return;
      _initialReadySent = true;
      startupMilestone('Map fully rendered');
      widget.onInitialViewReady?.call();
    });
    WidgetsBinding.instance.ensureVisualUpdate();
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
          _controller = controller;
          _mapCreated = true;
          widget.onMapCreated(controller);
          _applyStyle();
        },
        onStyleLoaded: (style) => unawaited(_styleLoaded(style)),
        onLoadingStarted: (_) {
          _fullyRendered = false;
          _webResourcesLoaded = false;
        },
        onRenderFrame: (event) {
          _recordFrame();
          if (event.fullyRendered != null) _rendered(event.fullyRendered!);
        },
        onRenderMap: (event) {
          _recordFrame();
          _rendered(event.fullyRendered);
        },
        onLoadingFinished: (_) => _webResourcesLoaded = true,
        onIdle: (_) {
          // Web does not expose fully-rendered native frames.
          if (kIsWeb && _webResourcesLoaded) _rendered(true);
        },
        onError: (event) {
          if (!mounted) return;
          debugPrint('MapLibre ${event.kind.name}: ${event.message}');
          if (!_initialReadySent &&
              (event.kind == MapErrorKind.style ||
                  event.kind == MapErrorKind.render)) {
            widget.onInitialViewError?.call(StateError(event.message));
          }
        },
        onClick: widget.onEvent,
        onCameraMoveStart: widget.onEvent,
        onCameraMove: widget.onEvent,
        onCameraMoveEnd: widget.onEvent,
        children: [
          Builder(
            builder: (context) {
              // Native CameraPosition follows the presented texture, unlike
              // camera-move and render-finished events.
              final camera = CameraPosition.of(context);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted || _controller?.camera != camera) return;
                widget.onCameraPresented?.call(camera);
              });
              return const SizedBox.shrink();
            },
          ),
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
