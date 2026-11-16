import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stork/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:stork/features/map/data/repositories/map_metadata_repository.dart';
import 'package:stork/features/map/data/repositories/notam_catalog_repository.dart';
import 'package:stork/features/map/data/services/map_search.dart';
import 'package:stork/features/map/domain/models/map_search_result.dart';
import 'package:stork/features/map/domain/models/poi_type.dart';
import 'package:stork/features/map/presentation/components/dialogs/map_search_dialog.dart';
import 'package:stork/l10n/app_localizations.dart';

class _Favorites extends FavoritesNotifier {
  _Favorites(this.points);

  final List<FavoritePoint> points;

  @override
  Future<List<FavoritePoint>> build() async => points;
}

class _OfflineMetadata extends Fake implements MapMetadataRepository {
  _OfflineMetadata(this.airports);

  final List<Map<String, dynamic>> airports;

  @override
  Future<List<Map<String, dynamic>>> fetchAllFeaturesFromDb(
    String type,
  ) async => type == 'apt' ? List.of(airports) : [];
}

Map<String, dynamic> _airport(String name, [String code = '']) => {
  'name': name,
  'icaoCode': code,
  'latitude': 48.0,
  'longitude': 17.0,
};

const _favorite = FavoritePoint(
  id: '1',
  name: 'Martovce viewpoint',
  latitude: 48,
  longitude: 17,
  icon: PoiType.home,
);

http.Response _municipalityResponse(String name) => http.Response(
  jsonEncode({
    'features': [
      {
        'properties': {
          'name': name,
          'county': 'Komárno district',
          'country': 'Slovakia',
        },
        'geometry': {
          'type': 'Point',
          'coordinates': [18.1257, 47.8566],
        },
      },
    ],
  }),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

Future<void> _openSearch(
  WidgetTester tester, {
  required List<Map<String, dynamic>> airports,
  required MockClient client,
  List<FavoritePoint> favorites = const [],
  ValueChanged<MapSearchResult?>? onSelected,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        mapMetadataRepositoryProvider.overrideWithValue(
          _OfflineMetadata(airports),
        ),
        notamCatalogRepositoryProvider.overrideWithValue(
          NotamCatalogRepository(
            MockClient((_) async {
              fail('Offline airport records should avoid a network request');
            }),
          ),
        ),
        favoritesProvider.overrideWith(() => _Favorites(favorites)),
        photonSearchProvider.overrideWithValue(PhotonSearch(client)),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                final result = await showMapSearchDialog(
                  context,
                  latitude: 48.15,
                  longitude: 17.11,
                );
                onSelected?.call(result);
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

Future<void> _type(WidgetTester tester, String query) async {
  await tester.enterText(find.byType(TextField), query);
  await tester.pump();
}

void main() {
  test(
    'downloads the NOTAM airport GeoJSON when offline airports are missing',
    () async {
      final requests = <String>[];
      final client = MockClient((request) async {
        requests.add(request.url.pathSegments.last);
        return http.Response(
          jsonEncode({
            'type': 'FeatureCollection',
            'features': [
              {
                'properties': {'name': 'Martin', 'icao': 'LZMA'},
                'geometry': {
                  'type': 'Point',
                  'coordinates': [18.95, 49.06],
                },
              },
            ],
          }),
          200,
        );
      });
      addTearDown(client.close);
      final container = ProviderContainer.test(
        overrides: [
          mapMetadataRepositoryProvider.overrideWithValue(_OfflineMetadata([])),
          notamCatalogRepositoryProvider.overrideWithValue(
            NotamCatalogRepository(client),
          ),
        ],
      );

      final records = await container.read(airportSearchRecordsProvider.future);
      final result = searchAirportRecords(records, 'lzma').single;
      expect(result.icaoCode, 'LZMA');
      expect(result.latitude, 49.06);
      expect(searchAirportRecords(records, 'martin').single.name, 'Martin');

      container.invalidate(airportSearchRecordsProvider);
      await container.read(airportSearchRecordsProvider.future);
      expect(requests, ['airports.geojson']);
    },
  );

  test('ranks exact ICAO, prefix ICAO, then normalized name matches', () {
    final name = _airport('LŽŠ Airport', 'OTHER');
    final prefix = _airport('Prefix Airport', 'LZSL');
    final exact = _airport('Exact Airport', 'LZS');
    final results = searchAirportRecords([name, prefix, exact], ' lzs ');

    expect(results.map((airport) => airport.name), [
      'Exact Airport',
      'Prefix Airport',
      'LŽŠ Airport',
    ]);
  });

  test('reads coordinates from a GeoJSON point in older offline records', () {
    final results = searchAirportRecords([
      {'name': 'Martin without coordinates', 'icaoCode': 'LZMA'},
      {
        'name': 'Martin',
        'icaoCode': 'LZMA',
        'geometry': {
          'type': 'Point',
          'coordinates': [18.95, 49.06],
        },
      },
    ], 'lzma');

    expect(results.single.name, 'Martin');
    expect(results.single.latitude, 49.06);
    expect(results.single.longitude, 18.95);
  });

  testWidgets('reads updated offline airport data when reopened', (
    tester,
  ) async {
    final airports = [_airport('Old Martin', 'LZMA')];
    await _openSearch(
      tester,
      airports: airports,
      client: MockClient((_) async => http.Response('{"features":[]}', 200)),
    );
    await _type(tester, 'lzma');
    expect(
      find.textContaining('Old Martin', findRichText: true),
      findsOneWidget,
    );

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    airports[0] = _airport('Updated Martin', 'LZMA');
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await _type(tester, 'lzma');
    expect(
      find.textContaining('Updated Martin', findRichText: true),
      findsOneWidget,
    );
    expect(find.textContaining('Old Martin', findRichText: true), findsNothing);
    await tester.pump(const Duration(milliseconds: 350));
  });

  for (final (airportCount, favorites) in [
    (19, const [_favorite]),
    (20, const <FavoritePoint>[]),
  ]) {
    testWidgets(
      'skips Photon when $airportCount airports fill the list with favourites',
      (tester) async {
        var calls = 0;
        await _openSearch(
          tester,
          airports: List.generate(
            airportCount,
            (i) => _airport('Martovce airfield $i'),
          ),
          favorites: favorites,
          client: MockClient((_) async {
            calls++;
            return _municipalityResponse('Martovce');
          }),
        );

        await _type(tester, 'martov');
        await tester.pumpAndSettle(const Duration(milliseconds: 500));

        expect(calls, 0);
        expect(find.text('Airports'), findsOneWidget);
        expect(find.text('Searching for towns and villages…'), findsNothing);
        final list = tester.widget<ListView>(find.byType(ListView));
        expect(
          list.childrenDelegate.estimatedChildCount,
          20 + (favorites.isEmpty ? 1 : 2),
        );
      },
    );
  }

  testWidgets(
    'requests the remaining municipality, shows loading and returns the selected point',
    (tester) async {
      final response = Completer<http.Response>();
      http.Request? photonRequest;
      MapSearchResult? selected;
      await _openSearch(
        tester,
        airports: List.generate(19, (i) => _airport('Martovce airfield $i')),
        client: MockClient((request) {
          photonRequest = request;
          return response.future;
        }),
        onSelected: (result) => selected = result,
      );

      await _type(tester, 'martov');
      expect(photonRequest, isNull);
      await tester.pump(const Duration(milliseconds: 350));
      expect(
        photonRequest!.headers['user-agent'],
        'Stork Navigation (https://www.stork-nav.app/)',
      );
      final uri = photonRequest!.url;
      expect(uri.host, 'photon.komoot.io');
      expect(uri.queryParameters, {
        'q': 'martov',
        'layer': 'city',
        'lat': '48.15',
        'lon': '17.11',
        'limit': '1',
      });
      expect(
        find.text('Searching for towns and villages…').hitTestable(),
        findsOneWidget,
      );
      final scrollable = find.byType(Scrollable).last;

      response.complete(_municipalityResponse('Martovce'));
      await tester.pumpAndSettle();
      final town = find.text('Martovce');
      await tester.scrollUntilVisible(town, 250, scrollable: scrollable);
      await tester.pumpAndSettle();
      await tester.tap(town);
      await tester.pumpAndSettle();

      expect(selected?.type, MapSearchResultType.municipality);
      expect(selected?.latitude, 47.8566);
      expect(selected?.longitude, 18.1257);
      expect(find.byType(TextField), findsNothing);
    },
  );

  testWidgets(
    'keeps local results usable on failure and ignores an older Photon response',
    (tester) async {
      final older = Completer<http.Response>();
      final newer = Completer<http.Response>();
      await _openSearch(
        tester,
        airports: [_airport('Martovce airfield')],
        favorites: const [_favorite],
        client: MockClient(
          (request) => request.url.queryParameters['q'] == 'mar'
              ? older.future
              : newer.future,
        ),
      );

      await _type(tester, 'mar');
      await tester.pump(const Duration(milliseconds: 350));
      await _type(tester, 'martov');
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('Searching for towns and villages…'), findsOneWidget);
      expect(find.text(_favorite.name).hitTestable(), findsOneWidget);

      newer.complete(http.Response('', 503));
      await tester.pumpAndSettle();
      older.complete(_municipalityResponse('Old result'));
      await tester.pumpAndSettle();

      expect(find.text('Old result'), findsNothing);
      expect(find.text('Searching for towns and villages…'), findsNothing);
      expect(find.text('Could not load towns and villages.'), findsOneWidget);
      expect(find.text(_favorite.name).hitTestable(), findsOneWidget);
    },
  );
}
