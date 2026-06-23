import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:maplibre/maplibre.dart';
import 'package:fake_async/fake_async.dart';
import 'package:stork/core/providers/shared_preferences_provider.dart';
import 'package:stork/features/map/domain/models/notam.dart';
import 'package:stork/features/map/domain/repositories/notam_repository.dart';
import 'package:stork/features/map/presentation/providers/notams_provider.dart';
import 'package:stork/features/map/data/repositories/notam_repository.dart';
import 'package:stork/features/telemetry/presentation/providers/telemetry_provider.dart';
import 'package:stork/features/navigation/presentation/providers/navigation_provider.dart';
import 'package:stork/features/map/domain/utils/fir_utils.dart';

class FakeNotamRepository implements NotamRepository {
  final List<List<String>> queriedFirsLogs = [];
  List<Notam> mockNotamsToReturn = [];
  bool shouldThrow = false;

  @override
  Future<List<Notam>> fetchNotamsByFirs(List<String> firs) async {
    queriedFirsLogs.add(firs);
    if (shouldThrow) {
      throw Exception('Simulated network error');
    }
    return mockNotamsToReturn;
  }

  @override
  Future<List<Notam>> fetchNotamsAroundPoint(
    Geographic point,
    int radiusMeters,
  ) async {
    return [];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Notams Provider Tests', () {
    late FakeNotamRepository mockRepository;
    late SharedPreferences mockPrefs;

    final testNotam = Notam(
      facilityDesignator: 'LZIB',
      notamNumber: 'A1234/26',
      featureName: 'BRATISLAVA',
      issueDate: '2026-03-25T13:00:00Z',
      startDate: '2026-03-25T13:15:00Z',
      endDate: '2026-06-25T18:00:00Z',
      icaoMessage: '',
      id: 'A1234/26',
      type: 'NOTAMN',
      issuer: 'LZIB',
      from: DateTime.utc(2026, 3, 25),
      to: DateTime.utc(2026, 6, 25),
      msg: 'TEST NOTAM MESSAGE',
      fir: 'LZBB',
      latitude: 48.17,
      longitude: 17.17,
      radius: 5000,
      flightLevelLowerLimit: 0,
      flightLevelUpperLimit: 999,
    );

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      mockPrefs = await SharedPreferences.getInstance();
      mockRepository = FakeNotamRepository();
      await FirUtils.initialize(rawJson: File('assets/geojson/fir.geojson').readAsStringSync());
    });

    test('Loads NOTAMs on initial GPS fix and only updates FIR on route changes', () {
      fakeAsync((async) {
        mockRepository.mockNotamsToReturn = [testNotam];

        final container = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWith((ref) => mockPrefs),
            notamRepositoryProvider.overrideWith((ref) => mockRepository),
          ],
        );
        addTearDown(container.dispose);

        // Pre-initialize navigationProvider
        container.read(navigationProvider);
        async.flushMicrotasks();

        // Keep notamsProvider alive
        final sub = container.listen(notamsProvider, (_, _) {});
        addTearDown(sub.close);

        // Initially telemetry coordinates are not set (latitude=null, longitude=null), currentFir is null
        var state = container.read(notamsProvider).value;
        expect(state, isNull);
        async.flushMicrotasks();
        state = container.read(notamsProvider).value;
        expect(state, isEmpty);
        expect(mockRepository.queriedFirsLogs, isEmpty);

        // 1. Initial GPS fix in LZBB FIR.
        container.read(telemetryProvider.notifier).updateGPS(
          latitude: 48.17,
          longitude: 17.17,
          groundSpeed: 0.0,
        );
        async.elapse(const Duration(milliseconds: 100));

        var listState = container.read(notamsProvider).value!;
        expect(listState, hasLength(1));
        expect(listState.first.id, 'A1234/26');
        expect(mockRepository.queriedFirsLogs, equals([['LZBB']]));

        // Clear query logs
        mockRepository.queriedFirsLogs.clear();

        // 2. Telemetry update to Czech Republic (LKAA FIR).
        // Since this is an intermediate coordinate change and the route is not changing,
        // it should NOT trigger a new FIR recalculation or NOTAM fetch.
        container.read(telemetryProvider.notifier).updateGPS(
          latitude: 50.0,
          longitude: 15.0,
        );
        async.elapse(const Duration(milliseconds: 100));

        // Verify no repository loads were triggered (FIR remains LZBB)
        expect(mockRepository.queriedFirsLogs, isEmpty);

        // 3. Trigger a route change by adding a point.
        // This route change should cause the FIR provider to recalculate using the current telemetry coordinates (LKAA).
        container.read(navigationProvider.notifier).addPoint(
          const NavigationPoint(
            name: 'LKPR',
            latitude: 50.1,
            longitude: 14.26,
          ),
        );
        async.elapse(const Duration(milliseconds: 100));

        // Since the route changed, it should re-evaluate and fetch LKAA notams (and route notams)
        // Check that LKAA was queried
        final flatQueries = mockRepository.queriedFirsLogs.expand((x) => x).toList();
        expect(flatQueries, contains('LKAA'));
      });
    });

    test('Does not reload NOTAMs when point is removed due to auto-advance, but reloads on manual removal', () {
      fakeAsync((async) {
        mockRepository.mockNotamsToReturn = [testNotam];

        final container = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWith((ref) => mockPrefs),
            notamRepositoryProvider.overrideWith((ref) => mockRepository),
          ],
        );
        addTearDown(container.dispose);

        // Pre-initialize navigationProvider and add points
        final navNotifier = container.read(navigationProvider.notifier);
        async.flushMicrotasks();

        container.read(telemetryProvider.notifier).updateGPS(
          latitude: 48.17,
          longitude: 17.17,
          groundSpeed: 0.0,
        );

        navNotifier.addPoint(
          const NavigationPoint(
            name: 'P1',
            latitude: 48.18,
            longitude: 17.18,
          ),
        );
        navNotifier.addPoint(
          const NavigationPoint(
            name: 'P2',
            latitude: 48.19,
            longitude: 17.19,
          ),
        );
        async.elapse(const Duration(milliseconds: 100));

        // Keep notamsProvider alive
        final sub = container.listen(notamsProvider, (_, _) {});
        addTearDown(sub.close);
        async.elapse(const Duration(milliseconds: 100));

        // Verify NOTAMs loaded initially
        expect(container.read(notamsProvider).value, isNotEmpty);
        expect(mockRepository.queriedFirsLogs, isNotEmpty);
        mockRepository.queriedFirsLogs.clear();

        // 1. Simulate auto-advance (point removed because goal was reached)
        navNotifier.removePoints(1, isAutoAdvance: true);
        async.elapse(const Duration(milliseconds: 100));

        // Verify NO new NOTAM fetch was triggered
        expect(mockRepository.queriedFirsLogs, isEmpty);

        // 2. Simulate manual point removal (not auto-advance)
        navNotifier.removePoints(1, isAutoAdvance: false);
        async.elapse(const Duration(milliseconds: 100));

        // Verify a new NOTAM fetch WAS triggered
        expect(mockRepository.queriedFirsLogs, isNotEmpty);
      });
    });
  });
}
