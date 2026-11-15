import 'package:flutter_test/flutter_test.dart';
import 'package:stork/features/map/domain/models/notam_catalog.dart';

void main() {
  test('validates all feature entries before parsing their geometry', () {
    final airports = {
      'type': 'FeatureCollection',
      'features': [
        {
          'properties': {'icao': 'LZIB'},
        },
        null,
      ],
    };
    final areas = {'type': 'FeatureCollection', 'features': []};

    expect(
      () => NotamCatalog.fromGeoJson(airports, areas),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          'Invalid GeoJSON feature',
        ),
      ),
    );
  });
}
