import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:maplibre/maplibre.dart';
import 'package:stork/features/map/presentation/providers/airport_metadata_provider.dart';
import 'package:stork/features/map/presentation/providers/airspace_metadata_provider.dart';
import 'package:stork/features/offline_maps/domain/tile_utils.dart';
import 'package:stork/features/offline_maps/presentation/providers/offline_maps_provider.dart';
import 'package:stork/core/services/database/database_service.dart';

void main() {
  group('TileUtils', () {
    test('getTilesForRegion should return zoom 0 tile', () {
      final tiles = getTilesForRegion(
        minLat: -90,
        minLon: -180,
        maxLat: 90,
        maxLon: 180,
        minZ: 0,
        maxZ: 0,
        kind: 'protomaps',
      );
      expect(tiles.length, 1);
      expect(tiles.first, TileCoord(0, 0, 0, 'protomaps'));
    });

    test('getTilesForRegion should return correct tiles for zoom 1', () {
      final tiles = getTilesForRegion(
        minLat: -90,
        minLon: -180,
        maxLat: 90,
        maxLon: 180,
        minZ: 1,
        maxZ: 1,
        kind: 'protomaps',
      );
      expect(tiles.length, 4);
      expect(
        tiles,
        containsAll([
          TileCoord(1, 0, 0, 'protomaps'),
          TileCoord(1, 1, 0, 'protomaps'),
          TileCoord(1, 0, 1, 'protomaps'),
          TileCoord(1, 1, 1, 'protomaps'),
        ]),
      );
    });

    test('getTilesForRegion should return tiles for a small area', () {
      // Bratislava area
      final tiles = getTilesForRegion(
        minLat: 48.0,
        minLon: 17.0,
        maxLat: 48.2,
        maxLon: 17.2,
        minZ: 10,
        maxZ: 10,
        kind: 'protomaps',
      );
      // At zoom 10, 1 degree is ~2.8 tiles. 0.2 degrees should be 1 tile.
      expect(tiles.isNotEmpty, true);
      for (final tile in tiles) {
        expect(tile.z, 10);
      }
    });
  });

  group('OfflineMapsNotifier Cache Clearing', () {
    late Directory tempDir;

    setUpAll(() {
      tempDir = Directory.systemTemp.createTempSync('stork_offline_maps_test');
      TestWidgetsFlutterBinding.ensureInitialized();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (MethodCall methodCall) async {
              if (methodCall.method == 'getApplicationSupportDirectory') {
                return tempDir.path;
              }
              return null;
            },
          );
    });

    tearDownAll(() {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    });

    test('startDownload clears airport and airspace metadata caches', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final airportCache = container.read(
        airportMetadataCacheProvider.notifier,
      );
      final airspaceCache = container.read(
        airspaceMetadataCacheProvider.notifier,
      );

      var airportRequestCount = 0;
      var airspaceRequestCount = 0;

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('_apt.geojson')) {
          airportRequestCount++;
          return http.Response(
            json.encode({
              'features': [
                {
                  'type': 'Feature',
                  'properties': {
                    'id': 'apt1',
                    'name': 'Test Airport 1',
                    'type': 1,
                    'country': 'US',
                  },
                },
              ],
            }),
            200,
          );
        } else if (request.url.path.contains('_asp.geojson')) {
          airspaceRequestCount++;
          return http.Response(
            json.encode({
              'features': [
                {
                  'type': 'Feature',
                  'properties': {
                    'id': 'asp1',
                    'name': 'Test Airspace 1',
                    'icaoClass': 2,
                    'type': 7,
                    'country': 'US',
                  },
                },
              ],
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      await http.runWithClient(() async {
        // 1. Populate the caches by loading metadata once
        final apt1 = await airportCache.getMetadata('apt1', 'US');
        final asp1 = await airspaceCache.getMetadata('asp1', 'US');

        expect(apt1?.name, equals('Test Airport 1'));
        expect(asp1?.name, equals('Test Airspace 1'));
        expect(airportRequestCount, equals(1));
        expect(airspaceRequestCount, equals(1));

        // 2. Querying again should hit the memory cache, not HTTP
        final apt2 = await airportCache.getMetadata('apt1', 'US');
        final asp2 = await airspaceCache.getMetadata('asp1', 'US');

        expect(apt2?.name, equals('Test Airport 1'));
        expect(asp2?.name, equals('Test Airspace 1'));
        expect(airportRequestCount, equals(1));
        expect(airspaceRequestCount, equals(1));

        // 3. Initialize offline map downloading
        final offlineNotifier = container.read(offlineMapsProvider.notifier);
        offlineNotifier.addRegion(
          Geographic(lon: 17.0, lat: 48.0),
          Geographic(lon: 17.2, lat: 48.2),
        );

        // Call startDownload. This clears the caches, prepares the db tiles, and runs sequence in background.
        // We will catch exceptions or wait for the initial synchronous part to finish.
        try {
          await offlineNotifier.startDownload();
        } catch (_) {
          // ignore any DB/background download errors since we only care about cache clearing
        }

        // 4. Querying again should NOT hit the memory cache, triggering new HTTP requests
        final apt3 = await airportCache.getMetadata('apt1', 'US');
        final asp3 = await airspaceCache.getMetadata('asp1', 'US');

        expect(apt3?.name, equals('Test Airport 1'));
        expect(asp3?.name, equals('Test Airspace 1'));
        expect(airportRequestCount, equals(2));
        expect(airspaceRequestCount, equals(2));
      }, () => mockClient);
    });

    test('_storeFeatures handles non-Map properties gracefully', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await DatabaseService.resetDatabase();

      final offlineNotifier = container.read(offlineMapsProvider.notifier);
      await Future.delayed(const Duration(milliseconds: 50));

      final mixedFeatures = [
        // 1. Valid feature
        {
          'type': 'Feature',
          'properties': {
            'id': 'valid_apt',
            'name': 'Valid Airport',
            'type': 1,
            'country': 'US',
          },
        },
        // 2. properties is a String (invalid)
        {'type': 'Feature', 'properties': 'not a map'},
        // 3. properties is null (invalid)
        {'type': 'Feature', 'properties': null},
        // 4. properties is missing (invalid)
        {'type': 'Feature'},
        // 5. feature is not a Map (invalid)
        'not a map feature',
      ];

      // Call storeFeaturesForTesting and ensure it doesn't throw
      await expectLater(
        offlineNotifier.storeFeaturesForTesting(mixedFeatures, 'US', 'airport'),
        completes,
      );

      // Verify that only the valid feature was inserted into the database
      final validResult = await DatabaseService.getOpenAipFeature(
        'valid_apt',
        'airport',
      );
      expect(validResult, isNotNull);
      expect(validResult!['name'], equals('Valid Airport'));
    });
  });
}
