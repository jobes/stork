import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:stork/features/settings/domain/models/aircraft_type.dart';

void main() {
  test('AircraftType asset files exist on filesystem', () {
    for (final type in AircraftType.values) {
      final file = File(type.assetPath);
      expect(
        file.existsSync(),
        isTrue,
        reason: 'Asset file missing: ${type.assetPath}',
      );
    }
  });
}
