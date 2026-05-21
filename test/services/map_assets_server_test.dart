import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:stork/core/services/map_assets_server.dart';
import 'package:test/test.dart';

class _FakeAssetBundle extends CachingAssetBundle {
  _FakeAssetBundle(this._assets);

  final Map<String, List<int>> _assets;

  @override
  Future<ByteData> load(String key) async {
    final bytes = _assets[key];
    if (bytes == null) {
      throw Exception('Asset not found: $key');
    }
    return ByteData.view(Uint8List.fromList(bytes).buffer);
  }
}

void main() {
  test('baseUrl throws StateError if start() was not called', () {
    expect(() => MapAssetsServer.baseUrl, throwsStateError);
  });

  group('MapAssetsServer after start', () {
    late Uri baseUri;

    setUpAll(() async {
      MapAssetsServer.bundle = _FakeAssetBundle({
        'assets/openaip/styles.json': utf8.encode('{"ok":true}'),
        'assets/fonts/Roboto Regular,Noto Sans Regular/0-255.pbf': [1, 2, 3],
      });

      await MapAssetsServer.start();
      baseUri = Uri.parse(MapAssetsServer.baseUrl);
    });

    test('baseUrl returns HTTP URL on loopback', () {
      expect(baseUri.scheme, 'http');
      expect(baseUri.host, anyOf('127.0.0.1', 'localhost'));
      expect(baseUri.port, isPositive);
    });

    test('start() is idempotent and keeps same URL', () async {
      final first = MapAssetsServer.baseUrl;
      await MapAssetsServer.start();
      final second = MapAssetsServer.baseUrl;
      expect(second, first);
    });

    test(
      'serves openaip JSON asset with application/json content type',
      () async {
        final client = HttpClient();
        try {
          final request = await client.getUrl(
            baseUri.replace(path: '/openaip/styles.json'),
          );
          final response = await request.close();

          expect(response.statusCode, HttpStatus.ok);
          expect(response.headers.contentType?.mimeType, 'application/json');

          final body = await response.transform(utf8.decoder).join();
          expect(body, isNotEmpty);
        } finally {
          client.close(force: true);
        }
      },
    );

    test('serves font PBF asset with x-protobuf content type', () async {
      // This path corresponds to an existing asset declared in pubspec.yaml.
      final client = HttpClient();
      try {
        final request = await client.getUrl(
          baseUri.replace(
            path: '/fonts/Roboto%20Regular%2CNoto%20Sans%20Regular/0-255.pbf',
          ),
        );
        final response = await request.close();

        expect(response.statusCode, HttpStatus.ok);
        expect(
          response.headers.contentType?.mimeType,
          'application/x-protobuf',
        );

        var totalBytes = 0;
        await for (final chunk in response) {
          totalBytes += chunk.length;
        }
        expect(totalBytes, greaterThan(0));
      } finally {
        client.close(force: true);
      }
    });

    test('returns 404 for unknown top-level path', () async {
      final client = HttpClient();
      try {
        final request = await client.getUrl(
          baseUri.replace(path: '/unknown/path'),
        );
        final response = await request.close();

        expect(response.statusCode, HttpStatus.notFound);
      } finally {
        client.close(force: true);
      }
    });

    test('returns 404 for non-existent asset under known prefix', () async {
      final client = HttpClient();
      try {
        final request = await client.getUrl(
          baseUri.replace(path: '/openaip/does_not_exist.json'),
        );
        final response = await request.close();

        expect(response.statusCode, HttpStatus.notFound);
      } finally {
        client.close(force: true);
      }
    });

    test('returns 404 for root path', () async {
      final client = HttpClient();
      try {
        final request = await client.getUrl(baseUri.replace(path: '/'));
        final response = await request.close();

        expect(response.statusCode, HttpStatus.notFound);
      } finally {
        client.close(force: true);
      }
    });
  });
}
