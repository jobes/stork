import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Loads and caches frames from the app sprite.
///
/// The sprite is a single sheet (`sprite.png` / `sprite@2x.png`) described by
/// `sprite.json` / `sprite@2x.json`. Frames are cropped once and reused, so
/// every UI site that shares an icon pays no extra decode cost.
///
/// The cache is app-lifetime (see `spriteCacheProvider` in
/// `lib/core/widgets/sprite_icon.dart`), so the decoded sheet and cropped
/// frames are kept in memory on purpose.
class SpriteCache {
  SpriteCache();

  /// Sprite density for standard-density displays.
  static const double scale1x = 1.0;

  /// Sprite density for high-DPI displays.
  static const double scale2x = 2.0;

  static const String _index1x = 'assets/map_sprites/sprite.json';
  static const String _index2x = 'assets/map_sprites/sprite@2x.json';
  static const String _sheet1x = 'assets/map_sprites/sprite.png';
  static const String _sheet2x = 'assets/map_sprites/sprite@2x.png';

  final Map<String, Future<ui.Image>> _frameCache = {};
  final Map<String, Future<Map<String, dynamic>>> _indexCache = {};
  final Map<String, Future<ui.Image>> _sheetCache = {};

  /// Picks the sprite density (1.0 or 2.0) for a given device pixel ratio, so
  /// the icon stays crisp on high-DPI screens.
  static double scaleForDevicePixelRatio(double devicePixelRatio) =>
      devicePixelRatio >= 1.5 ? scale2x : scale1x;

  static String _indexPathFor(double scale) =>
      scale >= 1.5 ? _index2x : _index1x;

  static String _sheetPathFor(double scale) =>
      scale >= 1.5 ? _sheet2x : _sheet1x;

  /// Returns the cropped [frameId] frame for the given sprite [scale]
  /// (1.0 or 2.0). The result is cached.
  Future<ui.Image> loadFrame(String frameId, {required double scale}) {
    final key = '$frameId@$scale';
    return _frameCache.putIfAbsent(key, () async {
      try {
        final index = await _loadIndex(scale);
        final frame = index[frameId];
        if (frame == null) {
          throw StateError(
            'Sprite frame "$frameId" not found in ${_indexPathFor(scale)}',
          );
        }
        final sheet = await _loadSheet(scale);
        return _crop(
          sheet,
          (frame['x'] as num).toDouble(),
          (frame['y'] as num).toDouble(),
          (frame['width'] as num).toDouble(),
          (frame['height'] as num).toDouble(),
        );
      } catch (error, stackTrace) {
        // Do not cache failures so a later request can retry (e.g. after a
        // sprite regeneration).
        _frameCache.remove(key);
        Error.throwWithStackTrace(error, stackTrace);
      }
    });
  }

  Future<Map<String, dynamic>> _loadIndex(double scale) {
    final path = _indexPathFor(scale);
    return _indexCache.putIfAbsent(path, () async {
      try {
        final raw = await rootBundle.loadString(path);
        return jsonDecode(raw) as Map<String, dynamic>;
      } catch (error, stackTrace) {
        // Do not cache failures so a later request can retry.
        _indexCache.remove(path);
        Error.throwWithStackTrace(error, stackTrace);
      }
    });
  }

  Future<ui.Image> _loadSheet(double scale) {
    final path = _sheetPathFor(scale);
    return _sheetCache.putIfAbsent(path, () async {
      try {
        final data = await rootBundle.load(path);
        final bytes = data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        );
        return await _decodeImage(bytes);
      } catch (error, stackTrace) {
        // Do not cache failures so a later request can retry.
        _sheetCache.remove(path);
        Error.throwWithStackTrace(error, stackTrace);
      }
    });
  }

  /// Decodes [bytes] into a [ui.Image]. Uses [ui.instantiateImageCodec] so a
  /// decode failure propagates as an error (instead of a hanging future) and
  /// can be retried by the caller.
  static Future<ui.Image> _decodeImage(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    try {
      final frame = await codec.getNextFrame();
      return frame.image;
    } finally {
      codec.dispose();
    }
  }

  static Future<ui.Image> _crop(
    ui.Image source,
    double x,
    double y,
    double width,
    double height,
  ) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawImageRect(
      source,
      Rect.fromLTWH(x, y, width, height),
      Rect.fromLTWH(0, 0, width, height),
      Paint(),
    );
    final picture = recorder.endRecording();
    final cropped = await picture.toImage(width.round(), height.round());
    picture.dispose();
    return cropped;
  }
}
