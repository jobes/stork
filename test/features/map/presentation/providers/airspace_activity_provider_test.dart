import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fake_async/fake_async.dart';
import 'package:http/http.dart' as http;
import 'package:stork/features/map/data/repositories/aup_repository.dart';
import 'package:stork/features/map/data/repositories/map_metadata_repository.dart';
import 'package:stork/features/map/domain/models/airspace_activity_status.dart';
import 'package:stork/features/map/domain/utils/fir_utils.dart';
import 'package:stork/core/services/location_provider.dart';
import 'package:stork/features/map/presentation/providers/airspace_activity_provider.dart';
import 'package:stork/features/telemetry/presentation/providers/telemetry_provider.dart';

/// Two synthetic FIR rectangles used for the 30 km buffer tests:
///   TEST1: lat 48.0..49.0, lon 17.0..18.0
///   TEST2: lat 49.2..50.0, lon 17.0..18.0
const String _testFirGeoJson = '''
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "properties": {
        "ICAO": "TEST1",
        "MinLat": 48.0, "MinLon": 17.0, "MaxLat": 49.0, "MaxLon": 18.0
      },
      "geometry": {
        "type": "Polygon",
        "coordinates": [[
          [17.0, 48.0], [18.0, 48.0], [18.0, 49.0], [17.0, 49.0], [17.0, 48.0]
        ]]
      }
    },
    {
      "type": "Feature",
      "properties": {
        "ICAO": "TEST2",
        "MinLat": 49.2, "MinLon": 17.0, "MaxLat": 50.0, "MaxLon": 18.0
      },
      "geometry": {
        "type": "Polygon",
        "coordinates": [[
          [17.0, 49.2], [18.0, 49.2], [18.0, 50.0], [17.0, 50.0], [17.0, 49.2]
        ]]
      }
    }
  ]
}
''';

class FakeAupRepository extends AupRepository {
  FakeAupRepository()
    : super(const [], MapMetadataRepository(client: http.Client()));

  final List<String> fetchedFirs = [];
  List<AupAirspaceActivity> activitiesToReturn = const [];

  @override
  Future<List<AupAirspaceActivity>> fetchActivitiesForFir(
    String firIcao,
  ) async {
    fetchedFirs.add(firIcao);
    return activitiesToReturn;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await FirUtils.initialize(rawJson: _testFirGeoJson);
  });

  group('AirspaceActivity 30 km FIR buffer pre-fetch', () {
    test('no GPS fix or distant position does not trigger a fetch', () async {
      final fakeRepo = FakeAupRepository();
      final container = ProviderContainer(
        overrides: [
          aupRepositoryProvider.overrideWith((ref) => fakeRepo),
          compassStreamProvider.overrideWithValue(
            const AsyncValue<double?>.data(null),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Start the provider (no GPS fix yet).
      container.read(airspaceActivityProvider);
      await pumpEventQueue();
      expect(fakeRepo.fetchedFirs, isEmpty);

      // Position far away from both FIRs (south of TEST1 by ~333 km).
      container
          .read(telemetryProvider.notifier)
          .updateGPS(latitude: 45.0, longitude: 17.5, groundSpeed: 0.0);
      await pumpEventQueue();
      expect(fakeRepo.fetchedFirs, isEmpty);
      expect(container.read(airspaceActivityProvider), isEmpty);
    });

    test('position inside a FIR triggers pre-fetch for that FIR', () async {
      final fakeRepo = FakeAupRepository();
      fakeRepo.activitiesToReturn = [
        AupAirspaceActivity(
          airspaceId: 'asp_test1',
          designator: 'LZR33',
          name: 'R 33',
          status: AirspaceActivityStatus.active,
          validFrom: DateTime.utc(2026, 8, 2, 4),
          validTo: DateTime.utc(2026, 8, 2, 20),
          source: 'SVK_LZPS',
          updatedAt: DateTime.utc(2026, 8, 2, 4),
        ),
      ];
      final container = ProviderContainer(
        overrides: [
          aupRepositoryProvider.overrideWith((ref) => fakeRepo),
          compassStreamProvider.overrideWithValue(
            const AsyncValue<double?>.data(null),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(airspaceActivityProvider);
      await pumpEventQueue();

      // Position inside TEST1 FIR (Bratislava region).
      container
          .read(telemetryProvider.notifier)
          .updateGPS(latitude: 48.5, longitude: 17.5, groundSpeed: 0.0);
      await pumpEventQueue();

      expect(fakeRepo.fetchedFirs, contains('TEST1'));

      // The bound activity is stored in the provider state.
      final state = container.read(airspaceActivityProvider);
      expect(state, hasLength(1));
      expect(state['asp_test1']!.status, AirspaceActivityStatus.active);
    });

    test(
      'position within the 30 km buffer outside a FIR triggers pre-fetch',
      () async {
        final fakeRepo = FakeAupRepository();
        final container = ProviderContainer(
          overrides: [
            aupRepositoryProvider.overrideWith((ref) => fakeRepo),
            compassStreamProvider.overrideWithValue(
              const AsyncValue<double?>.data(null),
            ),
          ],
        );
        addTearDown(container.dispose);

        container.read(airspaceActivityProvider);
        await pumpEventQueue();

        // (49.1, 17.5) is 11 km north of TEST1's boundary and 11 km south of
        // TEST2's boundary -> both are inside the 30 km buffer.
        container
            .read(telemetryProvider.notifier)
            .updateGPS(latitude: 49.1, longitude: 17.5, groundSpeed: 0.0);
        await pumpEventQueue();

        expect(fakeRepo.fetchedFirs, containsAll(['TEST1', 'TEST2']));
      },
    );

    test('re-evaluates position at most once per minute', () {
      fakeAsync((async) {
        final fakeRepo = FakeAupRepository();
        final container = ProviderContainer(
          overrides: [
            aupRepositoryProvider.overrideWith((ref) => fakeRepo),
            compassStreamProvider.overrideWithValue(
              const AsyncValue<double?>.data(null),
            ),
          ],
        );
        addTearDown(container.dispose);

        container.read(airspaceActivityProvider);
        async.flushMicrotasks();

        // Inside TEST1 -> fetch.
        container
            .read(telemetryProvider.notifier)
            .updateGPS(latitude: 48.5, longitude: 17.5, groundSpeed: 0.0);
        async.flushMicrotasks();
        expect(fakeRepo.fetchedFirs, contains('TEST1'));
        fakeRepo.fetchedFirs.clear();

        // Movement within the same minute -> throttled, no re-fetch.
        container
            .read(telemetryProvider.notifier)
            .updateGPS(latitude: 48.6, longitude: 17.5, groundSpeed: 0.0);
        async.flushMicrotasks();
        expect(fakeRepo.fetchedFirs, isEmpty);
      });
    });

    test('fetches data immediately once the one-minute interval elapses', () {
      fakeAsync((async) {
        final fakeRepo = FakeAupRepository();
        final container = ProviderContainer(
          overrides: [
            aupRepositoryProvider.overrideWith((ref) => fakeRepo),
            compassStreamProvider.overrideWithValue(
              const AsyncValue<double?>.data(null),
            ),
          ],
        );
        addTearDown(container.dispose);

        container.read(airspaceActivityProvider);
        async.flushMicrotasks();

        container
            .read(telemetryProvider.notifier)
            .updateGPS(latitude: 48.5, longitude: 17.5, groundSpeed: 0.0);
        async.flushMicrotasks();
        expect(fakeRepo.fetchedFirs, contains('TEST1'));
        fakeRepo.fetchedFirs.clear();

        // After the 1-minute interval, the next evaluation fetches fresh data
        // immediately (no long cooldown).
        async.elapse(const Duration(minutes: 1));
        container
            .read(telemetryProvider.notifier)
            .updateGPS(latitude: 48.55, longitude: 17.5, groundSpeed: 0.0);
        async.flushMicrotasks();
        expect(fakeRepo.fetchedFirs, contains('TEST1'));
      });
    });

    test('prunes activities when the aircraft leaves the FIR vicinity', () {
      fakeAsync((async) {
        final fakeRepo = FakeAupRepository();
        fakeRepo.activitiesToReturn = [
          AupAirspaceActivity(
            airspaceId: 'asp_test1',
            designator: 'LZR33',
            name: 'R 33',
            status: AirspaceActivityStatus.active,
            source: 'SVK_LZPS',
            updatedAt: DateTime.utc(2026, 8, 2, 4),
          ),
        ];
        final container = ProviderContainer(
          overrides: [
            aupRepositoryProvider.overrideWith((ref) => fakeRepo),
            compassStreamProvider.overrideWithValue(
              const AsyncValue<double?>.data(null),
            ),
          ],
        );
        addTearDown(container.dispose);

        container.read(airspaceActivityProvider);
        async.flushMicrotasks();

        // Inside TEST1 -> fetch and store the activity.
        container
            .read(telemetryProvider.notifier)
            .updateGPS(latitude: 48.5, longitude: 17.5, groundSpeed: 0.0);
        async.flushMicrotasks();
        expect(container.read(airspaceActivityProvider), hasLength(1));

        // Move far away and let the evaluation interval elapse -> the stale
        // activity of TEST1 must be pruned from the state.
        async.elapse(const Duration(minutes: 1));
        container
            .read(telemetryProvider.notifier)
            .updateGPS(latitude: 45.0, longitude: 17.5, groundSpeed: 0.0);
        async.flushMicrotasks();
        expect(container.read(airspaceActivityProvider), isEmpty);
      });
    });

    test('re-fetching a FIR replaces its previous activities', () {
      fakeAsync((async) {
        final fakeRepo = FakeAupRepository();
        fakeRepo.activitiesToReturn = [
          AupAirspaceActivity(
            airspaceId: 'asp_test1',
            designator: 'LZR33',
            name: 'R 33',
            status: AirspaceActivityStatus.active,
            source: 'SVK_LZPS',
            updatedAt: DateTime.utc(2026, 8, 2, 4),
          ),
        ];
        final container = ProviderContainer(
          overrides: [
            aupRepositoryProvider.overrideWith((ref) => fakeRepo),
            compassStreamProvider.overrideWithValue(
              const AsyncValue<double?>.data(null),
            ),
          ],
        );
        addTearDown(container.dispose);

        container.read(airspaceActivityProvider);
        async.flushMicrotasks();

        container
            .read(telemetryProvider.notifier)
            .updateGPS(latitude: 48.5, longitude: 17.5, groundSpeed: 0.0);
        async.flushMicrotasks();
        expect(container.read(airspaceActivityProvider), hasLength(1));

        // Next evaluation returns no activities -> the previous entry must be
        // removed, not kept (e.g. airspace deactivated by a UUP).
        fakeRepo.activitiesToReturn = const [];
        async.elapse(const Duration(minutes: 1));
        container
            .read(telemetryProvider.notifier)
            .updateGPS(latitude: 48.6, longitude: 17.5, groundSpeed: 0.0);
        async.flushMicrotasks();
        expect(container.read(airspaceActivityProvider), isEmpty);
      });
    });
  });
}
