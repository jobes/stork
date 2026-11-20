import 'dart:async';
import 'dart:convert';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' show Response;
import 'package:http/testing.dart';
import 'package:maplibre/maplibre.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:stork/features/map/data/repositories/notam_catalog_repository.dart';
import 'package:stork/features/map/data/repositories/notam_repository.dart';
import 'package:stork/features/map/presentation/providers/notams_provider.dart';
import 'package:stork/features/navigation/domain/models/navigation_point.dart';
import 'package:stork/features/navigation/domain/models/navigation_state.dart';
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

class _PendingPreferencesStore extends InMemorySharedPreferencesStore {
  _PendingPreferencesStore(super.data) : super.withData();

  final writeStarted = Completer<void>();
  final writeResult = Completer<bool>();

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    writeStarted.complete();
    if (!await writeResult.future) return false;
    return super.setValue(valueType, key, value);
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

  void testPendingHide(String description, {required bool succeeds}) {
    test(description, () async {
      const key = 'hidden_notam_expirations';
      const committed = '{"A0002/26":"PERM"}';
      final originalStore = SharedPreferencesStorePlatform.instance;
      final store = _PendingPreferencesStore({'flutter.$key': committed});
      SharedPreferences.resetStatic();
      SharedPreferencesStorePlatform.instance = store;
      addTearDown(() {
        SharedPreferencesStorePlatform.instance = originalStore;
        SharedPreferences.resetStatic();
      });
      final prefs = await SharedPreferences.getInstance();
      final repository = HttpNotamRepository(
        loadPreferences: () async => prefs,
        client: MockClient(
          (_) async => Response(
            jsonEncode({
              'success': true,
              'notams': [
                for (final id in ['A0001/26', 'A0002/26'])
                  {
                    'location': 'LZBB',
                    'number': id,
                    'text':
                        '$id NOTAMN\n'
                        'Q) LZBB/QFAXX/IV/NBO/A/000/999/4810N01710E025\n'
                        'A) LZBB B) 2611130000 C) PERM\nE) WIP ON APRON',
                  },
              ],
            }),
            200,
          ),
        ),
      );
      await repository.fetchNotamsByLocations(['LZBB']);
      final container = ProviderContainer.test(
        overrides: [
          notamLocationsProvider.overrideWith((_) async => {'LZBB'}),
          notamRepositoryProvider.overrideWithValue(repository),
        ],
      );
      container.listen(notamsProvider, (_, _) {});
      final initial = await container.read(notamsProvider.future);
      final notam = initial.notams.single;
      expect(notam.id, 'A0001/26');

      final hide = container.read(notamsProvider.notifier).hideNotam(notam);
      await store.writeStarted.future;
      expect(prefs.getString(key), contains(notam.key));
      container.invalidate(notamsProvider);
      expect((await container.read(notamsProvider.future)).notams, [notam]);

      store.writeResult.complete(succeeds);
      expect(await hide, succeeds);
      final active = await container.read(notamsProvider.future);
      expect(active.notams, succeeds ? isEmpty : [notam]);
      if (succeeds) {
        await prefs.reload();
        expect(jsonDecode(prefs.getString(key)!), {
          'A0002/26': 'PERM',
          notam.key: 'PERM',
        });
      } else {
        expect(prefs.getString(key), committed);
        container.invalidate(notamsProvider);
        expect((await container.read(notamsProvider.future)).notams, [notam]);
      }
    });
  }

  testPendingHide(
    'a failed hide stays visible across refreshes and restores preferences',
    succeeds: false,
  );
  testPendingHide(
    'a successful hide persists and updates the replacement provider',
    succeeds: true,
  );

  test('10 NM and route changes recalculate ICAOs, hourly refresh only fetches NOTAMs', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    fakeAsync((time) {
      final catalogs = _Catalogs();
      var requests = 0;
      final repository = HttpNotamRepository(
        loadPreferences: () async => prefs,
        client: MockClient((_) async {
          requests++;
          return Response('{"success":true,"notams":[]}', 200);
        }),
      );
      final container = ProviderContainer.test(
        overrides: [
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
  });
}
