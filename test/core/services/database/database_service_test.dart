import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stork/core/services/database/database_service.dart';

void main() {
  group('DatabaseService getOpenAipFeature tests', () {
    late Directory tempDir;

    setUpAll(() async {
      tempDir = Directory.systemTemp.createTempSync('stork_db_test');
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

    setUp(() async {
      await DatabaseService.resetDatabase();
    });

    test('getOpenAipFeature returns null if feature not found', () async {
      final result = await DatabaseService.getOpenAipFeature('non_existent', 'airport');
      expect(result, isNull);
    });

    test('getOpenAipFeature successfully decodes valid JSON', () async {
      final validJson = {
        'id': 'apt123',
        'name': 'Valid Airport',
        'type': 1,
        'country': 'US',
      };
      
      await DatabaseService.insertOpenAipFeatures([
        {
          'id': 'apt123',
          'json': json.encode(validJson),
          'country': 'US',
          'type': 'airport',
        }
      ]);

      final result = await DatabaseService.getOpenAipFeature('apt123', 'airport');
      expect(result, isNotNull);
      final nonNull = result!;
      expect(nonNull['id'], equals('apt123'));
      expect(nonNull['name'], equals('Valid Airport'));
    });

    test('getOpenAipFeature returns null and swallows exception for malformed JSON string', () async {
      await DatabaseService.insertOpenAipFeatures([
        {
          'id': 'apt_malformed',
          'json': '{invalid_json',
          'country': 'US',
          'type': 'airport',
        }
      ]);

      final result = await DatabaseService.getOpenAipFeature('apt_malformed', 'airport');
      expect(result, isNull);
    });

    test('getOpenAipFeature returns null when decoded JSON is not a Map', () async {
      await DatabaseService.insertOpenAipFeatures([
        {
          'id': 'apt_list',
          'json': '[1, 2, 3]',
          'country': 'US',
          'type': 'airport',
        }
      ]);

      final result = await DatabaseService.getOpenAipFeature('apt_list', 'airport');
      expect(result, isNull);
    });

    test('composite primary key allows same id with different types', () async {
      final aptJson = {
        'id': 'feat123',
        'name': 'Airport Feature',
      };
      final aspJson = {
        'id': 'feat123',
        'name': 'Airspace Feature',
      };

      await DatabaseService.insertOpenAipFeatures([
        {
          'id': 'feat123',
          'json': json.encode(aptJson),
          'country': 'US',
          'type': 'apt',
        },
        {
          'id': 'feat123',
          'json': json.encode(aspJson),
          'country': 'US',
          'type': 'asp',
        }
      ]);

      final aptResult = await DatabaseService.getOpenAipFeature('feat123', 'apt');
      final aspResult = await DatabaseService.getOpenAipFeature('feat123', 'asp');

      expect(aptResult, isNotNull);
      expect(aptResult!['name'], equals('Airport Feature'));

      expect(aspResult, isNotNull);
      expect(aspResult!['name'], equals('Airspace Feature'));

      // Verify that inserting same id and type updates the feature
      final updatedAptJson = {
        'id': 'feat123',
        'name': 'Updated Airport Feature',
      };
      await DatabaseService.insertOpenAipFeatures([
        {
          'id': 'feat123',
          'json': json.encode(updatedAptJson),
          'country': 'US',
          'type': 'apt',
        }
      ]);

      final updatedAptResult = await DatabaseService.getOpenAipFeature('feat123', 'apt');
      expect(updatedAptResult!['name'], equals('Updated Airport Feature'));

      // Airspace feature remains unchanged
      final unchangedAspResult = await DatabaseService.getOpenAipFeature('feat123', 'asp');
      expect(unchangedAspResult!['name'], equals('Airspace Feature'));
    });
  });
}
