import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:share_plus/share_plus.dart';
import 'package:stork/core/services/export/gpx_export_service.dart';
import 'package:stork/features/telemetry/domain/models/flight.dart';
import 'package:stork/features/telemetry/domain/models/telemetry_entry.dart';
import 'package:stork/features/telemetry/domain/models/telemetry_state.dart';
import 'package:stork/features/telemetry/domain/repositories/black_box_repository.dart';

class MockBlackBoxRepository extends Mock implements BlackBoxRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockBlackBoxRepository mockRepo;
  late Flight testFlight;
  late Directory tempDir;

  setUpAll(() {
    tempDir = Directory.systemTemp.createTempSync('stork_gpx_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'getTemporaryDirectory') {
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

  setUp(() {
    mockRepo = MockBlackBoxRepository();
    testFlight = Flight(
      uuid: 'test-uuid-123',
      name: 'Test Flight 1',
      startTime: DateTime.utc(2026, 6, 25, 12, 0, 0),
    );
  });

  group('GpxExportService', () {
    test('returns null when telemetry entries are empty', () async {
      when(() => mockRepo.getGpxTelemetryForFlight(any()))
          .thenAnswer((_) async => []);

      final result = await GpxExportService.generateFlightGpx(testFlight, mockRepo);

      expect(result, isNull);
    });

    test('generates valid GPX structure when entries exist', () async {
      final entries = [
        TelemetryEntry(
          flightUuid: 'test-uuid-123',
          timestamp: DateTime.utc(2026, 6, 25, 12, 0, 0),
          isSnapshot: false,
          data: {
            TelemetryField.latitude.dbColumnName: 48.15,
            TelemetryField.longitude.dbColumnName: 17.10,
            TelemetryField.gpsAltitude.dbColumnName: 350.0,
          },
        ),
        TelemetryEntry(
          flightUuid: 'test-uuid-123',
          timestamp: DateTime.utc(2026, 6, 25, 12, 0, 2),
          isSnapshot: false,
          data: {
            TelemetryField.latitude.dbColumnName: 48.16,
            TelemetryField.longitude.dbColumnName: 17.11,
            TelemetryField.gpsAltitude.dbColumnName: 360.0,
          },
        ),
      ];

      when(() => mockRepo.getGpxTelemetryForFlight(any()))
          .thenAnswer((_) async => entries);

      final result = await GpxExportService.generateFlightGpx(testFlight, mockRepo);

      expect(result, isNotNull);
      expect(result, isA<XFile>());

      final gpxContent = await result!.readAsString();
      expect(gpxContent, contains('<?xml version="1.0" encoding="UTF-8"?>'));
      expect(gpxContent, contains('<gpx version="1.1"'));
      expect(gpxContent, contains('<name>Test Flight 1</name>'));
      expect(gpxContent, contains('lat="48.15" lon="17.1"'));
      expect(gpxContent, contains('<ele>350.0</ele>'));
      expect(gpxContent, contains('lat="48.16" lon="17.11"'));
      expect(gpxContent, contains('<ele>360.0</ele>'));
    });
  });
}
