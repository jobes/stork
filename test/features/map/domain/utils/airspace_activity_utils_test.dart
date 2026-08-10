import 'package:flutter_test/flutter_test.dart';
import 'package:stork/features/map/domain/models/airspace_activity_status.dart';
import 'package:stork/features/map/domain/utils/airspace_activity_utils.dart';

AupAirspaceActivity _activity(
  String id,
  AirspaceActivityStatus status, {
  DateTime? validFrom,
  DateTime? validTo,
}) {
  return AupAirspaceActivity(
    airspaceId: id,
    designator: id,
    name: id,
    status: status,
    validFrom: validFrom,
    validTo: validTo,
    source: 'TEST',
    updatedAt: DateTime.utc(2026, 8, 2, 4),
  );
}

void main() {
  group('AupAirspaceActivity.statusAt (time validity)', () {
    final now = DateTime.utc(2026, 8, 2, 12);

    test(
      'active without a validity window stays active (e.g. SVK state only)',
      () {
        final activity = _activity('a', AirspaceActivityStatus.active);
        expect(activity.statusAt(now), AirspaceActivityStatus.active);
      },
    );

    test('active inside its window is active', () {
      final activity = _activity(
        'a',
        AirspaceActivityStatus.active,
        validFrom: DateTime.utc(2026, 8, 2, 8),
        validTo: DateTime.utc(2026, 8, 2, 16),
      );
      expect(activity.statusAt(now), AirspaceActivityStatus.active);
    });

    test('active before its window is inactive', () {
      final activity = _activity(
        'a',
        AirspaceActivityStatus.active,
        validFrom: DateTime.utc(2026, 8, 2, 8),
        validTo: DateTime.utc(2026, 8, 2, 16),
      );
      expect(
        activity.statusAt(DateTime.utc(2026, 8, 2, 6)),
        AirspaceActivityStatus.inactive,
      );
    });

    test('active after its window is inactive', () {
      final activity = _activity(
        'a',
        AirspaceActivityStatus.active,
        validFrom: DateTime.utc(2026, 8, 2, 8),
        validTo: DateTime.utc(2026, 8, 2, 16),
      );
      expect(
        activity.statusAt(DateTime.utc(2026, 8, 2, 18)),
        AirspaceActivityStatus.inactive,
      );
    });

    test('active exactly at the end of its window is inactive', () {
      final activity = _activity(
        'a',
        AirspaceActivityStatus.active,
        validFrom: DateTime.utc(2026, 8, 2, 8),
        validTo: DateTime.utc(2026, 8, 2, 16),
      );
      expect(
        activity.statusAt(DateTime.utc(2026, 8, 2, 16)),
        AirspaceActivityStatus.inactive,
      );
    });

    test('inactive and unknown are returned unchanged', () {
      final inactive = _activity('a', AirspaceActivityStatus.inactive);
      final unknown = _activity('a', AirspaceActivityStatus.unknown);
      expect(inactive.statusAt(now), AirspaceActivityStatus.inactive);
      expect(unknown.statusAt(now), AirspaceActivityStatus.unknown);
    });
  });

  group('splitAirspaceActivityIds', () {
    final now = DateTime.utc(2026, 8, 2, 12);

    test('splits activities by effective status', () {
      final activities = {
        'active_1': _activity(
          'active_1',
          AirspaceActivityStatus.active,
          validFrom: DateTime.utc(2026, 8, 2, 8),
          validTo: DateTime.utc(2026, 8, 2, 16),
        ),
        // Raw active but outside its window -> effective inactive.
        'expired_2': _activity(
          'expired_2',
          AirspaceActivityStatus.active,
          validFrom: DateTime.utc(2026, 8, 2, 8),
          validTo: DateTime.utc(2026, 8, 2, 10),
        ),
        'inactive_3': _activity('inactive_3', AirspaceActivityStatus.inactive),
        'unknown_4': _activity('unknown_4', AirspaceActivityStatus.unknown),
      };

      final split = splitAirspaceActivityIds(activities, now);

      expect(split.activeIds, ['active_1']);
      expect(split.inactiveIds, containsAll(['expired_2', 'inactive_3']));
      expect(split.activeIds, isNot(contains('unknown_4')));
      expect(split.inactiveIds, isNot(contains('unknown_4')));
    });

    test('ignores entries without an airspace id', () {
      final activities = {'': _activity('', AirspaceActivityStatus.active)};
      final split = splitAirspaceActivityIds(activities, now);
      expect(split.activeIds, isEmpty);
      expect(split.inactiveIds, isEmpty);
    });

    test('returns empty lists for an empty map', () {
      final split = splitAirspaceActivityIds(const {}, now);
      expect(split.activeIds, isEmpty);
      expect(split.inactiveIds, isEmpty);
    });
  });
}
