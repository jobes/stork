import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:maplibre/maplibre.dart';
import 'package:stork/core/services/database/database_service.dart';
import 'package:stork/features/map/data/repositories/notam_catalog_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final requests = <String>[];
  late Directory directory;
  late NotamCatalogRepository repository;

  setUp(() async {
    directory = Directory.systemTemp.createTempSync('stork_notam_catalog_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => directory.path,
        );
    await DatabaseService.resetDatabase();
    requests.clear();
    repository = NotamCatalogRepository(
      MockClient((request) async {
        final file = request.url.pathSegments.last;
        requests.add(file);
        final airport = file == 'airports.geojson';
        return http.Response(
          jsonEncode({
            'type': 'FeatureCollection',
            'features': [
              {
                'type': 'Feature',
                'properties': {'icao': airport ? 'LZIB' : 'LZBB'},
                'geometry': airport
                    ? {
                        'type': 'Point',
                        'coordinates': [17, 48],
                      }
                    : {
                        'type': 'MultiPolygon',
                        'coordinates': [
                          [
                            [
                              [16, 47],
                              [19, 47],
                              [19, 49],
                              [16, 47],
                            ],
                          ],
                        ],
                      },
              },
            ],
          }),
          200,
        );
      }),
    );
  });

  tearDown(() async {
    await DatabaseService.resetDatabase();
    directory.deleteSync(recursive: true);
  });

  const points = [Geographic(lat: 48, lon: 17)];

  test('serializes selections and reuses downloaded documents', () async {
    var current = true;
    final first = repository.selectLocations(points, isCurrent: () => current);
    final skipped = repository.selectLocations(points, isCurrent: () => false);
    final latest = repository.selectLocations(points, isCurrent: () => true);
    current = false;
    expect(await first, isEmpty);
    expect(await skipped, isEmpty);
    expect(await latest, {'LZIB', 'LZBB'});
    expect(await repository.selectLocations(points, isCurrent: () => true), {
      'LZIB',
      'LZBB',
    });
    expect(requests, unorderedEquals(NotamCatalogRepository.files));
    expect(await DatabaseService.getMetadataSize(), 0);
  });

  test(
    'offline download fetches fresh files and selection reads SQLite',
    () async {
      await repository.selectLocations(points, isCurrent: () => true);
      var completed = 0;
      await repository.downloadForOffline(
        isCurrent: () => true,
        onFileDownloaded: () => completed++,
      );
      expect(completed, 2);
      expect(requests, hasLength(4));
      expect(await DatabaseService.getMetadataSize(), greaterThan(0));

      final reopened = NotamCatalogRepository(
        MockClient((_) async {
          fail('Expected to load offline metadata');
        }),
      );
      expect(await reopened.selectLocations(points, isCurrent: () => true), {
        'LZIB',
        'LZBB',
      });
    },
  );

  test('database reset waits for a worker reading the offline file', () async {
    final started = Completer<void>();
    final finish = Completer<void>();
    final read = DatabaseService.readOfflineMetadata((_) async {
      started.complete();
      await finish.future;
      return true;
    });
    await started.future;
    var resetFinished = false;
    final reset = DatabaseService.resetDatabase().then(
      (_) => resetFinished = true,
    );
    await pumpEventQueue();
    expect(resetFinished, isFalse);
    finish.complete();
    await read;
    await reset;
    expect(resetFinished, isTrue);
  });

  test('cancellation leaves neither catalog in SQLite', () async {
    var current = true;
    await repository.downloadForOffline(
      isCurrent: () => current,
      onFileDownloaded: () => current = false,
    );
    expect(await DatabaseService.getMetadataSize(), 0);
    expect(requests, hasLength(1));
  });
}
