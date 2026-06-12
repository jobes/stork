import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stork/features/map/domain/airport_metadata.dart';
import 'package:stork/features/map/domain/airspace_metadata.dart';
import 'package:stork/features/map/presentation/providers/airspace_metadata_provider.dart';

void main() {
  group('AirspaceMetadata JSON Parsing Guards', () {
    test('AirspaceLimit.fromJson handles null and valid inputs', () {
      final json = {'value': 1500, 'unit': 1, 'referenceDatum': 1};

      final limit = AirspaceLimit.fromJson(json);

      expect(limit.value, equals(1500.0));
      expect(limit.unit.toInt(), equals(1));
      expect(limit.referenceDatum, equals(ReferenceDatum.msl));
    });

    test('AirspaceMetadata.fromJson parses valid airspace data', () {
      final json = {
        'id': 'asp_123',
        'name': 'Bratislava CTR',
        'icaoClass': 3,
        'type': 4,
        'country': 'SK',
        'lowerLimit': {'value': 0, 'unit': 0, 'referenceDatum': 0},
        'upperLimit': {'value': 8000, 'unit': 1, 'referenceDatum': 1},
        'activity': 1,
        'byNotam': true,
      };

      final metadata = AirspaceMetadata.fromJson(json);

      expect(metadata.id, equals('asp_123'));
      expect(metadata.name, equals('Bratislava CTR'));
      expect(metadata.icaoClass, equals(AirspaceClass.d));
      expect(metadata.type, equals(AirspaceType.ctr));
      expect(metadata.country, equals('SK'));
      expect(metadata.limitLower.value, equals(0.0));
      expect(metadata.limitUpper.value, equals(8000.0));
      expect(metadata.activity, equals(AirspaceActivity.parachuting));
      expect(metadata.byNotam, equals(true));
    });

    test('AirspaceMetadata.fromJson parses airspace data with lowerLimit and upperLimit keys', () {
      final json = {
        'id': 'asp_123',
        'name': 'Bratislava CTR',
        'icaoClass': 3,
        'type': 4,
        'country': 'SK',
        'lowerLimit': {'value': 0, 'unit': 0, 'referenceDatum': 0},
        'upperLimit': {'value': 8000, 'unit': 1, 'referenceDatum': 1},
        'activity': 1,
        'byNotam': true,
      };

      final metadata = AirspaceMetadata.fromJson(json);

      expect(metadata.id, equals('asp_123'));
      expect(metadata.name, equals('Bratislava CTR'));
      expect(metadata.icaoClass, equals(AirspaceClass.d));
      expect(metadata.type, equals(AirspaceType.ctr));
      expect(metadata.country, equals('SK'));
      expect(metadata.limitLower.value, equals(0.0));
      expect(metadata.limitLower.unit, equals(OpenAipUnit.meters));
      expect(metadata.limitUpper.value, equals(8000.0));
      expect(metadata.limitUpper.unit, equals(OpenAipUnit.feet));
      expect(metadata.activity, equals(AirspaceActivity.parachuting));
      expect(metadata.byNotam, equals(true));
    });
  });

  group('AirspaceMetadataCache Concurrent Downloads', () {
    late Directory tempDir;

    setUpAll(() {
      tempDir = Directory.systemTemp.createTempSync('stork_airspace_test');
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

    test(
      'Concurrent requests for the same country code are deduplicated',
      () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final cache = container.read(airspaceMetadataCacheProvider.notifier);

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
        });

        await http.runWithClient(() async {
          final future1 = cache.getMetadata('asp1', 'US');
          final future2 = cache.getMetadata('asp1', 'US');

          final results = await Future.wait([future1, future2]);

          expect(results[0], isNotNull);
          expect(results[1], isNotNull);
          expect(results[0]?.name, equals('Test Airspace 1'));
          expect(results[1]?.name, equals('Test Airspace 1'));
          expect(requestCount, equals(1));
        }, () => mockClient);
      },
    );
  });
}
