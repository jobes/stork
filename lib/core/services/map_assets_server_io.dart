import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pmtiles/pmtiles.dart';

import 'database/database_service.dart';
import 'protomaps_resolver.dart';

class MapAssetsServer {
  static HttpServer? _server;
  static String? _baseUrl;
  static AssetBundle bundle = rootBundle;

  static final Map<String, String> _pmtilesUrls = {
    'openaip':
        'https://huggingface.co/datasets/jobes666/openaip-mptiles/resolve/main/openaip.pmtiles',
    'protomaps': ProtomapsResolver.fallbackUrl,
    'terrain': 'https://download.mapterhorn.com/planet.pmtiles',
  };

  static final Map<String, Future<PmTilesArchive>> _archives = {};

  static String get baseUrl {
    final url = _baseUrl;
    if (url == null) {
      throw StateError(
        'MapAssetsServer.start() must be called before using baseUrl',
      );
    }
    return url;
  }

  static Map<String, String> get pmtilesUrls => _pmtilesUrls;

  /// Gets or creates a [PmTilesArchive] for the given [id].
  ///
  /// This ensures only one archive instance is created per ID even with concurrent requests.
  static Future<PmTilesArchive> getArchive(String id) {
    final url = _pmtilesUrls[id];
    if (url == null) {
      throw ArgumentError('Unknown archive id: $id');
    }
    return _archives.putIfAbsent(id, () => PmTilesArchive.from(url));
  }

  /// Starts the local assets server.
  static Future<void> start() async {
    if (_server != null) return;

    try {
      _pmtilesUrls['protomaps'] = await ProtomapsResolver.getLatestUrl();

      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      _server = server;
      _baseUrl = 'http://${server.address.host}:${server.port}';

      debugPrint('MapAssetsServer started at $_baseUrl');

      server.listen(
        _handleRequest,
        onError: (e) {
          debugPrint('MapAssetsServer stream error: $e');
        },
      );
    } catch (e) {
      debugPrint('Failed to start MapAssetsServer: $e');
      rethrow;
    }
  }

  /// Stops the local assets server and clears cached archives.
  static Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
    _baseUrl = null;
    _archives.clear();
  }

  static Future<void> _handleRequest(HttpRequest request) async {
    try {
      final segments = request.uri.pathSegments
          .map(Uri.decodeComponent)
          .toList();

      if (segments.isEmpty) {
        return await _sendNotFound(request);
      }

      final firstSegment = segments[0];

      // Route PMTiles requests
      if (firstSegment == 'pmtiles' && segments.length >= 5) {
        return await _handlePmTilesRequest(request, segments);
      }

      // Route static asset requests
      if (firstSegment == 'openaip' || firstSegment == 'fonts') {
        return await _handleAssetRequest(request, segments);
      }

      return await _sendNotFound(request);
    } catch (e) {
      debugPrint('Error handling request ${request.uri}: $e');
      return await _sendError(request);
    }
  }

  static Future<void> _handlePmTilesRequest(
    HttpRequest request,
    List<String> segments,
  ) async {
    final id = segments[1];
    final z = int.tryParse(segments[2]);
    final x = int.tryParse(segments[3]);
    final yFile = segments[4];
    final yStr = yFile.contains('.')
        ? yFile.substring(0, yFile.lastIndexOf('.'))
        : yFile;
    final y = int.tryParse(yStr);

    if (z == null || x == null || y == null || !_pmtilesUrls.containsKey(id)) {
      return _sendNotFound(request);
    }

    // 1. Try local Database first
    final tile = await DatabaseService.getTile(z, x, y, id);
    if (tile != null) {
      final bytes = tile['data'] as List<int>;
      final type = tile['type'] as String;
      _setResponseContentType(request, type);
      request.response.add(bytes);
      await request.response.close();
      return;
    }

    // 2. Fallback: Remote PMTiles archive
    try {
      final archive = await getArchive(id);
      final tileId = ZXY(z, x, y).toTileId();
      final remoteTile = await archive.tile(tileId);
      final bytes = remoteTile.bytes();

      if (bytes.isNotEmpty) {
        final ext = yFile.contains('.')
            ? yFile.split('.').last.toLowerCase()
            : '';
        _setResponseContentType(request, ext);
        request.response.add(bytes);
        await request.response.close();
        return;
      }
    } catch (e) {
      debugPrint('PmTiles fallback error for $id ($z,$x,$y): $e');
    }

    return _sendNotFound(request);
  }

  static Future<void> _handleAssetRequest(
    HttpRequest request,
    List<String> segments,
  ) async {
    final String assetPath = segments[0] == 'openaip'
        ? 'assets/openaip/${segments.sublist(1).join('/')}'
        : 'assets/fonts/${segments.sublist(1).join('/')}';

    try {
      final data = await bundle.load(assetPath);
      final bytes = data.buffer.asUint8List();
      final ext = assetPath.split('.').last.toLowerCase();

      _setResponseContentType(request, ext);
      request.response.add(bytes);
      await request.response.close();
    } catch (e) {
      return _sendNotFound(request);
    }
  }

  static void _setResponseContentType(HttpRequest request, String extOrType) {
    final type = extOrType.toLowerCase();
    switch (type) {
      case 'png':
        request.response.headers.contentType = ContentType('image', 'png');
        break;
      case 'webp':
        request.response.headers.contentType = ContentType('image', 'webp');
        break;
      case 'pbf':
      case 'mvt':
        request.response.headers.contentType = ContentType(
          'application',
          'x-protobuf',
        );
        break;
      case 'json':
        request.response.headers.contentType = ContentType(
          'application',
          'json',
          charset: 'utf-8',
        );
        break;
    }
  }

  static Future<void> _sendNotFound(HttpRequest request) async {
    request.response.statusCode = HttpStatus.notFound;
    await request.response.close();
  }

  static Future<void> _sendError(HttpRequest request) async {
    request.response.statusCode = HttpStatus.internalServerError;
    await request.response.close();
  }
}
