import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre/maplibre.dart';
import 'package:stork/core/utils/geo_utils.dart';
import 'package:stork/features/map/domain/models/notam_catalog.dart';
import 'package:stork/features/map/domain/services/notam_service.dart';

NotamPolygon _rectangle(double west, double south, double east, double north) =>
    [
      [
        [west, south],
        [east, south],
        [east, north],
        [west, north],
        [west, south],
      ],
    ];

void main() {
  const start = Geographic(lat: 0, lon: 0);
  final end = GeoUtils.calculateDestination(start, 90, 100000);
  final midpoint = GeoUtils.calculateDestination(start, 90, 50000);

  Geographic offset(Geographic origin, double bearing, double meters) =>
      GeoUtils.calculateDestination(origin, bearing, meters);

  final catalog = NotamCatalog(
    [
      (icao: 'SIDE', position: offset(midpoint, 0, 20 * 1852)),
      (icao: 'ENDS', position: offset(start, 270, 20 * 1852)),
      (icao: 'CORN', position: const Geographic(lat: .31, lon: -.31)),
      (icao: 'FARR', position: const Geographic(lat: .34, lon: .4)),
      (icao: 'NEAR', position: const Geographic(lat: .1, lon: .1)),
    ],
    [
      (icao: 'CROS', polygons: [_rectangle(.4, -1, .5, 1)]),
      (icao: 'EDGE', polygons: [_rectangle(.4, .32, .5, .5)]),
      (icao: 'FARR', polygons: [_rectangle(.4, .34, .5, .5)]),
      (icao: 'NEAR', polygons: [_rectangle(.09, .09, .11, .11)]),
      (icao: 'CIRC', polygons: [_rectangle(.32, -.5, .5, .5)]),
      (
        icao: 'HOLE',
        polygons: [
          [..._rectangle(-1, -1, 1, 1), ..._rectangle(-.8, -.8, .8, .8)],
        ],
      ),
    ],
  );

  test('selects rectangle corners and crossing areas', () {
    expect(selectNotamLocations(catalog, [start, end]), {
      'SIDE',
      'ENDS',
      'CORN',
      'NEAR',
      'CROS',
      'EDGE',
      'CIRC',
      'HOLE',
    });
  });

  test('uses a 20 NM circle without a route and respects polygon holes', () {
    expect(selectNotamLocations(catalog, [start]), {'ENDS', 'NEAR', 'CIRC'});
  });

  test('uses the union of the rectangles and handles the date line', () {
    final catalog = NotamCatalog(
      [
        (icao: 'DATE', position: const Geographic(lat: .1, lon: -179.99)),
        (icao: 'NEXT', position: const Geographic(lat: .9, lon: -179.7)),
        (icao: 'SKIP', position: const Geographic(lat: .9, lon: 179.7)),
      ],
      [
        (icao: 'AREA', polygons: [_rectangle(-179.98, -.8, -179.95, .8)]),
      ],
    );
    expect(
      selectNotamLocations(catalog, const [
        Geographic(lat: 0, lon: 179.7),
        Geographic(lat: 0, lon: -179.7),
        Geographic(lat: 1, lon: -179.7),
      ]),
      {'AREA', 'DATE', 'NEXT'},
    );
  });
  test(
    'keeps selected ICAO codes when another leg has no matching airspace',
    () {
      final result = selectNotamLocations(catalog, [
        start,
        end,
        const Geographic(lat: 3, lon: .9),
        const Geographic(lat: 4, lon: .9),
      ]);
      expect(result, contains('CROS'));
    },
  );

  test('selects airports when there is no matching airspace', () {
    final result = selectNotamLocations(NotamCatalog(catalog.airports, []), [
      start,
    ]);
    expect(result, contains('NEAR'));
  });
}
