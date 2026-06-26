import 'package:flutter_test/flutter_test.dart';
import 'package:stork/features/telemetry/domain/models/telemetry_entry.dart';

void main() {
  group('TelemetryEntry', () {
    test('toMap and fromMap round-trip', () {
      final now = DateTime.now().toUtc();
      final entry = TelemetryEntry(
        id: 42,
        flightUuid: 'flight-uuid-123',
        timestamp: now,
        isSnapshot: true,
        data: {
          'latitude': 37.7749,
          'longitude': -122.4194,
          'heading': 180.0,
        },
      );

      final map = entry.toMap();
      expect(map['id'], 42);
      expect(map['flight_uuid'], 'flight-uuid-123');
      expect(map['timestamp'], now.toIso8601String());
      expect(map['is_snapshot'], 1);
      expect(map['latitude'], 37.7749);
      expect(map['longitude'], -122.4194);
      expect(map['heading'], 180.0);

      final decoded = TelemetryEntry.fromMap(map);
      expect(decoded.id, entry.id);
      expect(decoded.flightUuid, entry.flightUuid);
      expect(decoded.timestamp, entry.timestamp);
      expect(decoded.isSnapshot, entry.isSnapshot);
      expect(decoded.data['latitude'], 37.7749);
      expect(decoded.data['longitude'], -122.4194);
      expect(decoded.data['heading'], 180.0);
    });

    test('fromMap with null/missing values', () {
      final now = DateTime.now().toUtc();
      final map = <String, dynamic>{
        'id': null,
        'flight_uuid': 'flight-uuid-456',
        'timestamp': now.toIso8601String(),
        'is_snapshot': null,
        'latitude': 37.7749,
        'longitude': null,
      };

      final decoded = TelemetryEntry.fromMap(map);
      expect(decoded.id, isNull);
      expect(decoded.flightUuid, 'flight-uuid-456');
      expect(decoded.timestamp, now);
      expect(decoded.isSnapshot, isFalse);
      expect(decoded.data['latitude'], 37.7749);
      expect(decoded.data.containsKey('longitude'), isFalse);
    });
  });
}
