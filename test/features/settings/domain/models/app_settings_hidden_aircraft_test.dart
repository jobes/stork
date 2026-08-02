import 'package:flutter_test/flutter_test.dart';
import 'package:stork/features/settings/domain/models/app_settings.dart';

void main() {
  group('AppSettings hiddenAircraftIds Tests', () {
    test('copyWith adds and removes entries in hiddenAircraftIds', () {
      const settings = AppSettings();
      expect(settings.hiddenAircraftIds, isEmpty);

      final added = settings.copyWith(
        hiddenAircraftIds: {'flrdda5e6', 'ogn123456'},
      );
      expect(added.hiddenAircraftIds, contains('flrdda5e6'));
      expect(added.hiddenAircraftIds, contains('ogn123456'));

      final removed = added.copyWith(
        hiddenAircraftIds: Set<String>.from(added.hiddenAircraftIds)
          ..remove('flrdda5e6'),
      );
      expect(removed.hiddenAircraftIds, isNot(contains('flrdda5e6')));
      expect(removed.hiddenAircraftIds, contains('ogn123456'));
    });

    test('hiddenAircraftIds defaults to an empty set', () {
      const settings = AppSettings();
      expect(settings.hiddenAircraftIds, isEmpty);
      expect(settings.hiddenAircraftIds, isA<Set<String>>());
    });
  });
}
