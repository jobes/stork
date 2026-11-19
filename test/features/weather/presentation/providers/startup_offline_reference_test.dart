import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stork/core/startup/deferred_startup_tasks.dart';
import 'package:stork/features/map/data/repositories/map_metadata_repository.dart';
import 'package:stork/features/map/domain/airport_metadata.dart';
import 'package:stork/features/map/presentation/providers/airport_metadata_provider.dart';
import 'package:stork/features/navigation/domain/models/navigation_point.dart';
import 'package:stork/features/navigation/domain/models/navigation_state.dart';
import 'package:stork/features/navigation/presentation/providers/navigation_provider.dart';
import 'package:stork/features/weather/domain/forecast_route.dart';
import 'package:stork/features/weather/presentation/providers/flight_weather_provider.dart';

const _location = (latitude: 48.2, longitude: 17.2);
final _airport = <String, dynamic>{
  '_id': 'airport',
  'name': 'Offline airport',
  'latitude': 48.2,
  'longitude': 17.2,
  'elevation': {'value': 150, 'unit': 0, 'referenceDatum': 1},
};

class _Repository extends Fake implements MapMetadataRepository {
  _Repository({this.offline = true});
  final bool offline;
  int localReads = 0;
  int remoteReads = 0;

  @override
  Future<Map<String, dynamic>?> fetchFeatureFromDb(
    String id,
    String type,
  ) async {
    localReads++;
    return offline ? _airport : null;
  }

  @override
  Future<Map<String, AirportMetadata>> fetchAirportsFromNetwork(
    String country,
  ) async {
    remoteReads++;
    return {'airport': AirportMetadata.fromJson(_airport)};
  }
}

const _navigation = NavigationState(
  isActive: true,
  points: [
    NavigationPoint(
      latitude: 48.2,
      longitude: 17.2,
      name: 'Airport',
      airportId: 'airport',
      airportCountry: 'SK',
    ),
  ],
);

class _Navigation extends NavigationNotifier {
  @override
  NavigationState build() => _navigation;
}

void main() {
  testWidgets(
    'offline terrain and airport reference resolve while online work is held',
    (tester) async {
      final tasks = DeferredStartupTasks()..hold();
      final repository = _Repository();
      var terrainReads = 0;
      final container = ProviderContainer(
        overrides: [
          deferredStartupTasksProvider.overrideWithValue(tasks),
          navigationProvider.overrideWith(_Navigation.new),
          mapMetadataRepositoryProvider.overrideWithValue(repository),
          flightWeatherPlanProvider.overrideWithValue([
            ForecastRoutePoint(
              id: 'waypoint-0',
              location: _location,
              eta: DateTime.utc(2026),
              duration: Duration.zero,
              distanceMeters: 0,
              altitudeFeet: 2000,
              waypointIndex: 0,
            ),
          ]),
          forecastPointTerrainProvider(_location).overrideWith((_) async {
            terrainReads++;
            return 123.0;
          }),
        ],
      );
      container.listen(routeForecastReferenceProvider('waypoint-0'), (_, _) {});
      await tester.pump();
      final reference = container
          .read(routeForecastReferenceProvider('waypoint-0'))
          .requireValue;
      expect(reference, (terrainMeters: 123.0, airportMeters: 150.0));
      expect(terrainReads, 1);
      expect(repository.localReads, 1);
      expect(repository.remoteReads, 0);
      // A second family request can use the session cache without opening a gate.
      expect(
        await container.read(airportMetadataProvider('airport', 'sk').future),
        isNotNull,
      );
      expect(repository.localReads, 1);
      container.dispose();
      tasks.dispose();
    },
  );

  testWidgets('missing offline airport waits only before its remote fallback', (
    tester,
  ) async {
    final tasks = DeferredStartupTasks()..hold();
    final repository = _Repository(offline: false);
    final container = ProviderContainer(
      overrides: [
        deferredStartupTasksProvider.overrideWithValue(tasks),
        mapMetadataRepositoryProvider.overrideWithValue(repository),
      ],
    );
    container.listen(airportMetadataProvider('airport', 'SK'), (_, _) {});
    container.listen(airportMetadataProvider('airport', 'sk'), (_, _) {});
    await tester.pump();
    expect(repository.localReads, 2);
    expect(repository.remoteReads, 0);
    tasks.releaseAfterFirstFrame();
    await tester.pump(const Duration(milliseconds: 2999));
    expect(repository.remoteReads, 0);
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();
    expect(repository.remoteReads, 1);
    expect(
      container
          .read(airportMetadataProvider('airport', 'SK'))
          .requireValue!
          .name,
      'Offline airport',
    );
    container.dispose();
    tasks.dispose();
  });

  testWidgets(
    'disposing while a remote fallback is held does not start a download',
    (tester) async {
      final tasks = DeferredStartupTasks()..hold();
      final repository = _Repository(offline: false);
      final container = ProviderContainer(
        overrides: [
          deferredStartupTasksProvider.overrideWithValue(tasks),
          mapMetadataRepositoryProvider.overrideWithValue(repository),
        ],
      );
      container.listen(airportMetadataProvider('airport', 'SK'), (_, _) {});
      await tester.pump();
      expect(repository.localReads, 1);
      container.dispose();
      tasks.dispose();
      await tester.pump();
      expect(repository.remoteReads, 0);
      expect(tester.takeException(), isNull);
    },
  );
}
