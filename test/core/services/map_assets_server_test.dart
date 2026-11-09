import 'dart:convert';
import 'dart:io';
import 'dart:typed_data' show Endian;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart'
    show TestDefaultBinaryMessengerBinding, TestWidgetsFlutterBinding;
import 'package:stork/core/services/database/database_service_io.dart';
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
        'assets/map_sprites/sprite.json': utf8.encode('{"poi-icon-home":{}}'),
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

    test(
      'serves app sprite JSON asset with application/json content type',
      () async {
        final client = HttpClient();
        try {
          final request = await client.getUrl(
            baseUri.replace(path: '/map_sprites/sprite.json'),
          );
          final response = await request.close();

          expect(response.statusCode, HttpStatus.ok);
          expect(response.headers.contentType?.mimeType, 'application/json');

          final body = await response.transform(utf8.decoder).join();
          expect(body, contains('poi-icon-home'));
        } finally {
          client.close(force: true);
        }
      },
    );

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

    test(
      'shares archive reads, reuses tiles and retries failed reads',
      () async {
        final httpOverrides = HttpOverrides.current;
        TestWidgetsFlutterBinding.ensureInitialized();
        // This test uses real loopback HTTP for both ends of the request.
        HttpOverrides.global = httpOverrides;
        final directory = await Directory.systemTemp.createTemp(
          'stork-map-assets',
        );
        final messenger =
            TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
        const channel = MethodChannel('plugins.flutter.io/path_provider');
        messenger.setMockMethodCallHandler(
          channel,
          (_) async => directory.path,
        );
        addTearDown(() async {
          messenger.setMockMethodCallHandler(channel, null);
          await directory.delete(recursive: true);
        });
        final database = await DatabaseService.database;

        // PMTiles v3 with one uncompressed tile at z=0, x=0, y=0.
        const payload = [1, 2, 3];
        const tileOffset = 16384;
        final archive = Uint8List(tileOffset + payload.length)
          ..setAll(0, [...'PMTiles'.codeUnits, 3])
          ..setAll(96, [1, 1, 1, 1])
          ..setAll(127, [1, 0, 1, payload.length, 1])
          ..setAll(tileOffset, payload);
        ByteData.sublistView(archive)
          ..setUint64(8, 127, Endian.little)
          ..setUint64(16, 5, Endian.little)
          ..setUint64(56, tileOffset, Endian.little)
          ..setUint64(64, payload.length, Endian.little);

        final backend = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        addTearDown(() => backend.close(force: true));
        var tileReads = 0;
        backend.listen((request) async {
          final range = request.headers.value(HttpHeaders.rangeHeader)!;
          final [start, end] = range
              .substring(6)
              .split('-')
              .map(int.parse)
              .toList();
          if (start == tileOffset) {
            tileReads++;
            if (tileReads == 1) {
              request.response.statusCode = HttpStatus.serviceUnavailable;
              await request.response.close();
              return;
            }
            await Future<void>.delayed(const Duration(milliseconds: 50));
          }
          request.response
            ..statusCode = HttpStatus.partialContent
            ..contentLength = end - start + 1
            ..add(Uint8List.sublistView(archive, start, end + 1));
          await request.response.close();
        });
        const kind = 'cache-test';
        MapAssetsServer.pmtilesUrls[kind] = 'http://127.0.0.1:${backend.port}';
        addTearDown(() => MapAssetsServer.pmtilesUrls.remove(kind));
        final client = HttpClient();
        addTearDown(() => client.close(force: true));
        final url = baseUri.replace(path: '/pmtiles/$kind/0/0/0.pbf');

        Future<(int, List<int>)> readTile() async {
          final response = await (await client.getUrl(url)).close();
          return (
            response.statusCode,
            await response.expand((part) => part).toList(),
          );
        }

        expect((await readTile()).$1, HttpStatus.notFound);
        final pair = await Future.wait([readTile(), readTile()]);
        for (final result in [...pair, await readTile()]) {
          expect(result.$1, HttpStatus.ok);
          expect(result.$2, payload);
        }
        expect(tileReads, 2);

        final offlineTile = Uint8List.fromList([4, 5, 6]);
        database.execute(
          'INSERT INTO map_tiles (z, x, y, kind, tile_type, tile_data) '
          'VALUES (0, 0, 0, ?, ?, ?)',
          [kind, 'pbf', offlineTile],
        );
        final offline = await readTile();
        expect(offline.$1, HttpStatus.ok);
        expect(offline.$2, offlineTile);
        expect(tileReads, 2);
      },
    );
  });
}
