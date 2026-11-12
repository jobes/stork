import 'dart:async';
import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:maplibre/maplibre.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/services/map_assets_server.dart';
import '../../data/repositories/radar_repository.dart';

part 'map_radar.g.dart';

@riverpod
MapRadar mapRadar(Ref ref) {
  final radar = MapRadar(repository: ref.watch(radarRepositoryProvider));
  ref.onDispose(radar.dispose);
  return radar;
}

typedef RadarDisplay = ({
  DateTime? latest,
  DateTime? playing,
  bool preparing,
  bool unavailable,
  bool historyUnavailable,
});

typedef RadarTileRegistration =
    ({String template, VoidCallback close}) Function(
      Future<Uint8List?> Function(int, int, int),
    );

class MapRadar extends ValueNotifier<RadarDisplay> {
  MapRadar({required this._repository, RadarTileRegistration? registerTiles})
    : _registerTiles = registerTiles ?? MapAssetsServer.registerRadarTiles,
      super(_empty);

  static const refreshInterval = Duration(minutes: 5);
  static const _maxFrameAge = Duration(minutes: 20);
  static const _frameInterval = Duration(milliseconds: 750);
  static const _empty = (
    latest: null,
    playing: null,
    preparing: false,
    unavailable: false,
    historyUnavailable: false,
  );

  final RadarRepository _repository;
  final RadarTileRegistration _registerTiles;
  _RadarLayers? _layers;
  List<RadarFrame> _frames = const [];
  Future<void>? _refreshing;
  Future<void>? _clearing;
  DateTime? _lastRefreshAttempt;
  Timer? _expiry;
  Completer<void>? _playback;
  Completer<void>? _playbackDone;
  bool _disposed = false;

  void attachStyle(StyleController style) {
    if (_disposed || identical(_layers?.style, style)) return;
    final unavailable = value.unavailable;
    _detach();
    late final _RadarLayers layers;
    layers = _RadarLayers(
      style,
      _registerTiles,
      _repository,
      () => _fail(layers),
      _historyUnavailable,
    );
    _layers = layers;
    _setDisplay(unavailable: unavailable, historyUnavailable: false);
    unawaited(refresh(force: true));
  }

  void _detach() {
    interruptPlayback();
    _playback = null;
    _playbackDone = null;
    _expiry?.cancel();
    _layers?.detach();
    _layers = null;
    _refreshing = null;
    _clearing = null;
    _frames = const [];
  }

  void onMapEvent(MapEvent event) {
    if (event is MapEventStartMoveCamera &&
        event.reason == CameraChangeReason.apiGesture) {
      interruptPlayback();
    }
  }

  Future<void> refresh({bool force = false}) async {
    final layers = _layers;
    if (layers == null || _disposed) return;
    final now = clock.now();
    if (layers.latest case final frame? when !_isFresh(frame, now)) {
      _fail(layers);
    }
    if (_clearing case final clearing?) await clearing;
    if (!layers.attached || _playback != null) return;
    if (_refreshing case final refresh?) return refresh;
    final last = _lastRefreshAttempt;
    if (!force &&
        last != null &&
        now.difference(last) < const Duration(minutes: 1)) {
      return;
    }
    _lastRefreshAttempt = now;
    final refresh = _refresh(layers);
    _refreshing = refresh;
    try {
      await refresh;
    } finally {
      if (identical(layers, _layers)) _refreshing = null;
    }
  }

  Future<void> _refresh(_RadarLayers layers) async {
    try {
      if (layers.failed) {
        await layers.clear();
        if (!layers.attached) return;
      }
      layers.reset();
      final frames = await Future.any<List<RadarFrame>?>([
        _repository.fetchFrames(),
        layers.invalidated.then((_) => null),
      ]);
      if (frames == null || !layers.attached || layers.failed) return;
      final now = clock.now();
      if (frames.isEmpty || !_isFresh(frames.last, now)) {
        _fail(layers);
        return;
      }

      final newest = frames.last;
      final previous = layers.latest;
      if (previous != null && newest.time.isBefore(previous.time)) return;
      _frames = frames;
      if (newest == previous) return;
      await layers.stage([newest]);
      if (!layers.attached || layers.failed) return;
      await layers.show(newest);
      if (!layers.attached || layers.failed) return;
      final remaining = _maxFrameAge - clock.now().difference(newest.time);
      if (remaining <= Duration.zero) {
        _fail(layers);
        return;
      }
      layers.latest = newest;
      _expiry?.cancel();
      _expiry = Timer(remaining, () => _fail(layers));
      _setDisplay(latest: newest.time, preparing: value.preparing);
      if (previous != null) await layers.remove(previous);
    } catch (error) {
      debugPrint('RainViewer refresh failed: $error');
      _fail(layers);
    }
  }

  static bool _isFresh(RadarFrame frame, DateTime now) {
    final age = now.difference(frame.time);
    return age >= -refreshInterval && age < _maxFrameAge;
  }

  void _fail(_RadarLayers layers) {
    if (!layers.attached || _clearing != null) return;
    layers.invalidate();
    _expiry?.cancel();
    _frames = const [];
    interruptPlayback();
    _setDisplay(unavailable: true, historyUnavailable: false);

    final refreshing = _refreshing;
    final playback = _playbackDone?.future;
    _clearing = Future<void>.microtask(() async {
      try {
        await refreshing;
        await playback;
        await layers.clear();
      } catch (error) {
        debugPrint('RainViewer layer cleanup failed: $error');
      } finally {
        if (identical(layers, _layers)) _clearing = null;
      }
    });
  }

  Future<void> play() async {
    if (_disposed) return;
    final layers = _layers;
    if (layers == null) {
      _setDisplay(unavailable: true, historyUnavailable: false);
      return;
    }
    if (layers.latest case final frame? when !_isFresh(frame, clock.now())) {
      _fail(layers);
    }
    if (_clearing case final clearing?) await clearing;
    if (!layers.attached || _playback != null) return;

    final refreshBeforePlaying = layers.latest == null
        ? refresh(force: true)
        : _refreshing;
    final stop = Completer<void>();
    final done = Completer<void>();
    _playback = stop;
    _playbackDone = done;
    _setDisplay(
      latest: value.latest,
      preparing: !value.unavailable,
      unavailable: value.unavailable,
    );
    List<RadarFrame> history = const [];
    try {
      if (refreshBeforePlaying != null) {
        await Future.any([refreshBeforePlaying, stop.future]);
      }
      if (stop.isCompleted || !layers.attached || layers.failed) return;

      final latest = layers.latest;
      if (latest == null) return;
      final start = latest.time.subtract(const Duration(hours: 1));
      history = _frames
          .where(
            (frame) =>
                !frame.time.isBefore(start) && frame.time.isBefore(latest.time),
          )
          .toList();
      if (history.isEmpty) {
        _historyUnavailable();
        return;
      }

      _setDisplay(
        latest: latest.time,
        preparing: true,
        historyUnavailable: false,
      );
      await layers.stage(history, cancel: stop);
      for (final frame in history) {
        if (stop.isCompleted || !layers.attached) break;
        await layers.show(frame);
        if (stop.isCompleted || !layers.attached) break;
        _setDisplay(latest: latest.time, playing: frame.time);
        final nextFrame = Completer<void>();
        final timer = Timer(_frameInterval, nextFrame.complete);
        try {
          await Future.any([nextFrame.future, stop.future]);
        } finally {
          timer.cancel();
        }
      }
    } catch (error) {
      debugPrint('RainViewer playback failed: $error');
      _fail(layers);
    } finally {
      try {
        if (layers.attached && !layers.failed) {
          final latest = layers.latest;
          if (latest != null) await layers.show(latest);
          if (layers.attached && !layers.failed) {
            _setDisplay(latest: latest?.time);
            for (final frame in history) {
              await layers.remove(frame);
            }
          }
        }
      } catch (error) {
        debugPrint('RainViewer playback cleanup failed: $error');
        _fail(layers);
      } finally {
        if (identical(_playback, stop)) {
          _playback = null;
          _playbackDone = null;
        }
        done.complete();
      }
    }
  }

  void _setDisplay({
    DateTime? latest,
    DateTime? playing,
    bool preparing = false,
    bool unavailable = false,
    bool? historyUnavailable,
  }) {
    value = (
      latest: latest,
      playing: playing,
      preparing: preparing,
      unavailable: unavailable,
      historyUnavailable: historyUnavailable ?? value.historyUnavailable,
    );
  }

  void _historyUnavailable() {
    interruptPlayback();
    _setDisplay(latest: value.latest, historyUnavailable: true);
  }

  void interruptPlayback() {
    final playback = _playback;
    if (playback != null && !playback.isCompleted) playback.complete();
  }

  @override
  void dispose() {
    _disposed = true;
    _detach();
    super.dispose();
  }
}

extension on RadarFrame {
  String get id {
    final encodedTileBase = base64Url.encode(utf8.encode(tileBase.toString()));
    return 'rainviewer-${time.millisecondsSinceEpoch}-$encodedTileBase';
  }
}

class _RadarSource {
  final requested = Completer<void>();
  final ready = Completer<void>();
  late final VoidCallback close;
  bool added = false;
  bool staged = false;
  bool shown = false;
  bool closed = false;
  int loading = 0;
}

class _RadarLayers {
  _RadarLayers(
    this.style,
    this.registerTiles,
    this.repository,
    this.onTileError,
    this.onHistoryLimited,
  );

  static const _below = 'obstacle_clicktarget';
  static const _tileWarmup = RadarRepository.requestTimeout;

  final StyleController style;
  final RadarTileRegistration registerTiles;
  final RadarRepository repository;
  final VoidCallback onTileError;
  final VoidCallback onHistoryLimited;
  final _sources = <RadarFrame, _RadarSource>{};
  var _invalidated = Completer<void>();
  Future<void> get invalidated => _invalidated.future;
  bool attached = true;
  bool get failed => _invalidated.isCompleted;
  RadarFrame? latest;
  RadarFrame? _visible;

  void invalidate() {
    if (!failed) _invalidated.complete();
  }

  void reset() {
    _invalidated = Completer<void>();
  }

  void detach() {
    attached = false;
    invalidate();
    for (final source in _sources.values) {
      source.close();
    }
    _sources.clear();
  }

  Future<void> stage(List<RadarFrame> frames, {Completer<void>? cancel}) async {
    final requested = <Future<void>>[];
    final ready = <Future<void>>[];
    for (final frame in frames) {
      if (!attached || failed || cancel?.isCompleted == true) return;
      final source = _sources[frame] ?? await _addSource(frame, cancel);
      if (!attached || failed || cancel?.isCompleted == true) return;
      if (!source.staged) {
        await style.addLayer(
          _layer(frame, staging: true),
          belowLayerId: _below,
        );
        source.staged = true;
      }
      requested.add(source.requested.future);
      ready.add(source.ready.future);
    }
    // Allow time for MapLibre to start requesting each frame. Once requested,
    // tiles use their own HTTP deadline, even if the renderer started late.
    await Future.any<void>([
      Future.wait(requested),
      invalidated,
      ?cancel?.future,
    ]).timeout(_tileWarmup);
    await Future.any<void>([Future.wait(ready), invalidated, ?cancel?.future]);
  }

  Future<_RadarSource> _addSource(
    RadarFrame frame,
    Completer<void>? playback,
  ) async {
    final source = _RadarSource();
    bool isActive() =>
        attached && !failed && !source.closed && playback?.isCompleted != true;
    final route = registerTiles((z, x, y) async {
      if (!isActive()) return null;
      if (!source.requested.isCompleted) source.requested.complete();
      source.loading++;
      Uint8List? bytes;
      try {
        bytes = await repository.fetchTile(frame, z, x, y);
      } on RadarRequestLimitReached {
        if (playback != null && isActive()) {
          onHistoryLimited();
          return null;
        }
      } catch (error) {
        debugPrint('RainViewer tile unavailable: $error');
      } finally {
        source.loading--;
      }
      if (!isActive()) return null;
      if (bytes == null) {
        onTileError();
      } else if (source.loading == 0 && !source.ready.isCompleted) {
        source.ready.complete();
      }
      return bytes;
    });
    source.close = route.close;
    _sources[frame] = source;
    await style.addSource(
      RasterSource(
        id: frame.id,
        tiles: [route.template],
        maxZoom: 7,
        tileSize: 256,
      ),
    );
    source.added = true;
    return source;
  }

  Future<void> show(RadarFrame frame) async {
    if (!attached || failed || _visible == frame) return;
    final previous = _visible;
    await style.addLayer(_layer(frame), belowLayerId: _below);
    if (!attached) return;
    _sources[frame]!.shown = true;
    _visible = frame;
    if (previous != null) await _hide(previous);
  }

  Future<void> _hide(RadarFrame frame) async {
    final source = _sources[frame];
    if (!attached || source == null || !source.shown) return;
    await style.removeLayer('${frame.id}-visible');
    source.shown = false;
    if (_visible == frame) _visible = null;
  }

  Future<void> remove(RadarFrame frame) async {
    final source = _sources[frame];
    if (!attached || source == null) return;
    if (!source.closed) {
      source.closed = true;
      source.close();
    }
    await _hide(frame);
    if (attached && source.staged) {
      await style.removeLayer('${frame.id}-staging');
      source.staged = false;
    }
    if (attached && source.added) await style.removeSource(frame.id);
    _sources.remove(frame);
  }

  Future<void> clear() async {
    latest = null;
    final frames = _sources.keys.toList();
    // Hide the visible layers before removing the sources and staging layers.
    for (final frame in frames) {
      await _hide(frame);
    }
    for (final frame in frames) {
      await remove(frame);
    }
  }

  RasterStyleLayer _layer(RadarFrame frame, {bool staging = false}) =>
      RasterStyleLayer(
        id: '${frame.id}-${staging ? 'staging' : 'visible'}',
        sourceId: frame.id,
        paint: {
          'raster-fade-duration': 0,
          // A nonzero opacity keeps the tile loader active without visibly
          // mixing other timestamps into the displayed frame.
          'raster-opacity': staging ? 0.0001 : 0.6,
        },
      );
}
