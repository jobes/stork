import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'radar_repository.g.dart';

@riverpod
RadarRepository radarRepository(Ref ref) {
  final repository = RadarRepository();
  ref.onDispose(repository.close);
  return repository;
}

class RadarRequestLimitReached implements Exception {
  const RadarRequestLimitReached();
}

class RadarRepository {
  RadarRepository({http.Client? client}) : _client = client ?? http.Client();

  static final _manifest = Uri.https(
    'api.rainviewer.com',
    '/public/weather-maps.json',
  );
  static const requestTimeout = Duration(seconds: 15);
  final http.Client _client;

  Future<List<RadarFrame>> fetchFrames() async {
    final response = await _get(_manifest);
    return response.statusCode == 200 ? _decodeFrames(response.body) : const [];
  }

  Future<Uint8List?> fetchTile(RadarFrame frame, int z, int x, int y) async {
    final uri = Uri.parse('${frame.tileBase}/256/$z/$x/$y/2/1_1.png');
    final response = await _get(uri);
    const pngSignature = [137, 80, 78, 71, 13, 10, 26, 10];
    final bytes = response.bodyBytes;
    if (response.statusCode == 200 &&
        listEquals(bytes.take(pngSignature.length).toList(), pngSignature)) {
      return bytes;
    }
    return null;
  }

  Future<http.Response> _get(Uri uri) async {
    final response = await _client.get(uri).timeout(requestTimeout);
    if (response.statusCode == 429) throw const RadarRequestLimitReached();
    return response;
  }

  void close() => _client.close();
}

typedef RadarFrame = ({DateTime time, Uri tileBase});

final _radarPath = RegExp(r'^/v2/radar/[a-zA-Z0-9_-]+$');

List<RadarFrame> _decodeFrames(String body) {
  final manifest = jsonDecode(body);
  if (manifest case {
    'host': final String host,
    'radar': {'past': final List<dynamic> past},
  }) {
    final tileServer = Uri.tryParse(host);
    if (tileServer == null ||
        tileServer.scheme != 'https' ||
        tileServer.host.isEmpty ||
        tileServer.userInfo.isNotEmpty ||
        tileServer.hasQuery ||
        tileServer.hasFragment) {
      return const [];
    }
    final serverPath = tileServer.path.replaceFirst(RegExp(r'/+$'), '');
    final frames = <DateTime, RadarFrame>{};
    for (final frame in past) {
      // RainViewer sends Unix seconds. The upper bound filters out typical
      // Unix millisecond timestamps supplied by mistake.
      if (frame case {'time': final int seconds, 'path': final String path}
          when seconds > 0 &&
              seconds < 10000000000 &&
              _radarPath.hasMatch(path)) {
        final time = DateTime.fromMillisecondsSinceEpoch(
          seconds * 1000,
          isUtc: true,
        );
        frames[time] = (
          time: time,
          tileBase: tileServer.replace(path: '$serverPath$path'),
        );
      }
    }
    return frames.values.toList()..sort((a, b) => a.time.compareTo(b.time));
  }
  return const [];
}
