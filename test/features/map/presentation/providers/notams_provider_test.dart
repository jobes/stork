import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' show Response;
import 'package:http/testing.dart';
import 'package:maplibre/maplibre.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stork/core/providers/shared_preferences_provider.dart';
import 'package:stork/features/map/data/repositories/notam_catalog_repository.dart';
import 'package:stork/features/map/data/repositories/notam_repository.dart';
import 'package:stork/features/map/presentation/providers/notams_provider.dart';
import 'package:stork/features/navigation/presentation/providers/navigation_provider.dart';
import 'package:stork/features/offline_maps/domain/offline_maps_state.dart';
import 'package:stork/features/offline_maps/presentation/providers/offline_maps_provider.dart';
import 'package:stork/features/telemetry/presentation/providers/telemetry_provider.dart';

class _Telemetry extends TelemetryNotifier {
  @override
  TelemetryState build() => const TelemetryState(latitude: 48, longitude: 17);

  void move(double latitude) {
    state = state.copyWith(latitude: TelemetryValue(latitude));
  }
}

class _Navigation extends NavigationNotifier {
  @override
  NavigationState build() => const NavigationState();

  void replaceRoute() {
    state = const AsyncData(
      NavigationState(
        isActive: true,
        points: [NavigationPoint(latitude: 49, longitude: 17, name: 'Target')],
      ),
    );
  }
}

class _OfflineMaps extends OfflineMapsNotifier {
  @override
  OfflineMapsState build() => OfflineMapsState();
}

class _Catalogs extends NotamCatalogRepository {
  _Catalogs()
    : super(MockClient((_) async => fail('Unexpected catalog download')));

  int selections = 0;

  @override
  Future<Set<String>> selectLocations(
    List<Geographic> points, {
    required bool Function() isCurrent,
  }) async {
    selections++;
    return {'LZBB'};
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'a selection with no ICAO codes is successful and sends no requests',
    () async {
      final repository = HttpNotamRepository(
        client: MockClient((_) async => fail('Unexpected NOTAM request')),
      );
      final container = ProviderContainer.test(
        overrides: [
          notamLocationsProvider.overrideWith((_) async => const <String>{}),
          notamRepositoryProvider.overrideWithValue(repository),
        ],
      );
      final result = await container.read(notamsProvider.future);
      expect(result.notams, isEmpty);
      expect(result.hasIssue, isFalse);
    },
  );

  test(
    '10 NM and route changes recalculate ICAOs, hourly refresh only fetches NOTAMs',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      fakeAsync((time) {
        final catalogs = _Catalogs();
        var requests = 0;
        final repository = HttpNotamRepository(
          client: MockClient((_) async {
            requests++;
            return Response('{"success":true,"notams":[]}', 200);
          }),
        );
        final container = ProviderContainer.test(
          overrides: [
            sharedPreferencesProvider.overrideWith((_) async => prefs),
            telemetryProvider.overrideWith(_Telemetry.new),
            navigationProvider.overrideWith(_Navigation.new),
            offlineMapsProvider.overrideWith(_OfflineMaps.new),
            notamRepositoryProvider.overrideWithValue(repository),
            notamCatalogRepositoryProvider.overrideWithValue(catalogs),
          ],
        );
        container.listen(notamsProvider, (_, _) {});
        void settle() => time.elapse(Duration.zero);

        settle();
        expect(catalogs.selections, 1);
        expect(requests, 1);

        (container.read(telemetryProvider.notifier) as _Telemetry).move(48.1);
        settle();
        expect(catalogs.selections, 1);

        (container.read(telemetryProvider.notifier) as _Telemetry).move(48.18);
        settle();
        expect(catalogs.selections, 2);
        expect(requests, 1);

        (container.read(navigationProvider.notifier) as _Navigation)
            .replaceRoute();
        settle();
        expect(catalogs.selections, 3);
        expect(requests, 1);

        time.elapse(const Duration(hours: 1));
        expect(catalogs.selections, 3);
        expect(requests, 2);

        container.read(notamsProvider.notifier).refresh();
        settle();
        expect(catalogs.selections, 3);
        expect(requests, 3);
        container.dispose();
      });
    },
  );
}
