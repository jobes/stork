import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stork/features/map/domain/airport_metadata.dart';
import 'package:stork/features/map/presentation/providers/airport_metadata_provider.dart';

void main() {
  group('AirportMetadata JSON Parsing Guards', () {
    test(
      'RunwaySurface.fromJson handles null and malformed composition elements',
      () {
        final json = {
          'composition': [
            0,
            null,
            'invalid',
            2,
            {'invalid': 'map'},
            1.5,
          ],
          'mainComposite': 1,
          'condition': 3,
        };

        final surface = RunwaySurface.fromJson(json);

        // composition should filter out null, 'invalid', and map, but keep 0, 2, 1.5 (which becomes 1 as int)
        expect(surface.composition.length, equals(3));
        expect(surface.composition[0], equals(RunwayComposition.fromInt(0)));
        expect(surface.composition[1], equals(RunwayComposition.fromInt(2)));
        expect(surface.composition[2], equals(RunwayComposition.fromInt(1)));
        expect(surface.mainComposite, equals(RunwayComposition.fromInt(1)));
        expect(surface.condition, equals(3));
      },
    );

    test(
      'AirportMetadata.fromJson handles null and malformed elements in trafficType, frequencies, runways, images',
      () {
        final json = {
          'id': 'airport_123',
          'name': 'Test Airport',
          'type': 3,
          'trafficType': [1, null, 'not_a_num', 2],
          'country': 'US',
          'frequencies': [
            {
              'id': 'f1',
              'value': '118.1',
              'unit': 2,
              'type': 14,
              'name': 'Tower',
              'primary': true,
              'publicUse': true,
            },
            null,
            'malformed_frequency',
            123,
            {
              'id': 'f2',
              'value': '121.9',
              'unit': 2,
              'type': 9,
              'name': 'Ground',
              'primary': false,
              'publicUse': true,
            },
          ],
          'runways': [
            {
              'id': 'r1',
              'designator': '09/27',
              'trueHeading': 90.0,
              'pilotCtrlLighting': false,
            },
            null,
            'malformed_runway',
            [1, 2],
            {
              'id': 'r2',
              'designator': '18/36',
              'trueHeading': 180.0,
              'pilotCtrlLighting': true,
            },
          ],
          'images': [
            {'id': 'img1', 'filename': 'pic1.png'},
            null,
            'malformed_image',
            {'id': 'img2', 'filename': 'pic2.png'},
          ],
        };

        final metadata = AirportMetadata.fromJson(json);

        expect(metadata.id, equals('airport_123'));
        expect(metadata.name, equals('Test Airport'));

        // trafficType should filter out null and string
        expect(metadata.trafficType, equals([1, 2]));

        // frequencies should parse 2 valid maps, ignoring null/string/int
        expect(metadata.frequencies.length, equals(2));
        expect(metadata.frequencies[0].id, equals('f1'));
        expect(metadata.frequencies[0].name, equals('Tower'));
        expect(metadata.frequencies[1].id, equals('f2'));
        expect(metadata.frequencies[1].name, equals('Ground'));

        // runways should parse 2 valid maps, ignoring null/string/list
        expect(metadata.runways.length, equals(2));
        expect(metadata.runways[0].id, equals('r1'));
        expect(metadata.runways[0].designator, equals('09/27'));
        expect(metadata.runways[1].id, equals('r2'));
        expect(metadata.runways[1].designator, equals('18/36'));

        // images should parse 2 valid maps, ignoring null/string
        expect(metadata.images.length, equals(2));
        expect(metadata.images[0].id, equals('img1'));
        expect(metadata.images[0].filename, equals('pic1.png'));
        expect(metadata.images[1].id, equals('img2'));
        expect(metadata.images[1].filename, equals('pic2.png'));
      },
    );
  });

  group('AirportMetadataCache Concurrent Downloads', () {
    late Directory tempDir;

    setUpAll(() {
      tempDir = Directory.systemTemp.createTempSync('stork_test');
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

    test('Concurrent requests for the same country code are deduplicated', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final cache = container.read(airportMetadataCacheProvider.notifier);

      var requestCount = 0;
      final mockClient = MockClient((request) async {
        requestCount++;
        await Future.delayed(const Duration(milliseconds: 50));
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
                }
              }
            ]
          }),
          200,
        );
      });

      await http.runWithClient(() async {
        final future1 = cache.getMetadata('apt1', 'US');
        final future2 = cache.getMetadata('apt1', 'US');

        final results = await Future.wait([future1, future2]);

        expect(results[0], isNotNull);
        expect(results[1], isNotNull);
        expect(results[0]?.name, equals('Test Airport 1'));
        expect(results[1]?.name, equals('Test Airport 1'));
        expect(requestCount, equals(1));
      }, () => mockClient);
    });

    test('Failed request can be retried on next call', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final cache = container.read(airportMetadataCacheProvider.notifier);

      var requestCount = 0;
      final mockClient = MockClient((request) async {
        requestCount++;
        if (requestCount == 1) {
          return http.Response('Internal Server Error', 500);
        }
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
                }
              }
            ]
          }),
          200,
        );
      });

      await http.runWithClient(() async {
        await expectLater(
          cache.getMetadata('apt1', 'US'),
          throwsA(isA<Exception>()),
        );
        expect(requestCount, equals(1));

        final res2 = await cache.getMetadata('apt1', 'US');
        expect(res2, isNotNull);
        expect(res2?.name, equals('Test Airport 1'));
        expect(requestCount, equals(2));
      }, () => mockClient);
    });
  });
}
