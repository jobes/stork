import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stork/services/database/database_service.dart';

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
      final result = await DatabaseService.getOpenAipFeature('non_existent');
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

      final result = await DatabaseService.getOpenAipFeature('apt123');
      expect(result, isNotNull);
      expect(result!.id, equals('apt123'));
      expect(result.name, equals('Valid Airport'));
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

      final result = await DatabaseService.getOpenAipFeature('apt_malformed');
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

      final result = await DatabaseService.getOpenAipFeature('apt_list');
      expect(result, isNull);
    });
  });
}
