import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:stork/features/settings/domain/models/app_settings.dart';

void main() {
  group('Traffic Settings Default Values & CopyWith', () {
    test('default traffic settings are enabled and have standard ranges', () {
      const settings = AppSettings();
      expect(settings.trafficFilterMaxHorizontalDistanceEnabled, isTrue);
      expect(settings.trafficMaxHorizontalDistance, 50000.0);
      expect(settings.trafficFilterMaxVerticalDistanceEnabled, isTrue);
      expect(settings.trafficMaxVerticalDistance, 1500.0);
    });

    test('copyWith updates traffic settings correctly', () {
      const settings = AppSettings();
      final updated = settings.copyWith(
        trafficFilterMaxHorizontalDistanceEnabled: false,
        trafficMaxHorizontalDistance: 30000.0,
        trafficFilterMaxVerticalDistanceEnabled: false,
        trafficMaxVerticalDistance: 1000.0,
      );

      expect(updated.trafficFilterMaxHorizontalDistanceEnabled, isFalse);
      expect(updated.trafficMaxHorizontalDistance, 30000.0);
      expect(updated.trafficFilterMaxVerticalDistanceEnabled, isFalse);
      expect(updated.trafficMaxVerticalDistance, 1000.0);
    });

    test('json serialization roundtrip preserves traffic settings', () {
      const settings = AppSettings(
        trafficFilterMaxHorizontalDistanceEnabled: false,
        trafficMaxHorizontalDistance: 25000.0,
        trafficFilterMaxVerticalDistanceEnabled: true,
        trafficMaxVerticalDistance: 2000.0,
      );

      final jsonMap = json.decode(json.encode(settings.toJson())) as Map<String, dynamic>;
      final deserialized = AppSettings.fromJson(jsonMap);

      expect(deserialized.trafficFilterMaxHorizontalDistanceEnabled, isFalse);
      expect(deserialized.trafficMaxHorizontalDistance, 25000.0);
      expect(deserialized.trafficFilterMaxVerticalDistanceEnabled, isTrue);
      expect(deserialized.trafficMaxVerticalDistance, 2000.0);
    });
  });
}
