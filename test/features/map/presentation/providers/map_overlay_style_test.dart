import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stork/features/map/presentation/providers/map_overlay_style.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('initial style contains inline data and every overlay source', () async {
    final base = await rootBundle.loadString('assets/openaip/styles.json');
    final data = {
      for (final id in [
        'course-line-source',
        'navigation-route-source',
        'notams-source',
        'aircraft-source',
        'traffic-source',
        'favorites-source',
        forecastSource,
      ])
        id: '{"type":"FeatureCollection","features":[]}',
    };
    data['aircraft-source'] = jsonEncode({
      'type': 'FeatureCollection',
      'features': [
        {
          'type': 'Feature',
          'geometry': {
            'type': 'Point',
            'coordinates': [17.1, 48.2],
          },
          'properties': {'heading': 90},
        },
      ],
    });
    final overlays = MapOverlayStyle.build(
      data: data,
      fontScale: 1.5,
      palette: forecastDark,
    );
    final result = jsonDecode(overlays.embedIn(base));
    final sources = result['sources'] as Map;
    expect(sources['aircraft-source']['data'], isA<Map>());
    expect(
      sources['aircraft-source']['data']['features'][0]['geometry']['coordinates'],
      [17.1, 48.2],
    );
    final layers = result['layers'] as List;
    final ids = layers.map((layer) => layer['id']).toList();
    expect(ids.toSet().length, ids.length);
    for (final layer in layers) {
      if (layer['source'] != null) expect(sources, contains(layer['source']));
    }
    final favorites = layers.singleWhere(
      (layer) => layer['id'] == 'favorites-layer',
    );
    expect(favorites['layout']['text-size'], 27);
    final weather = layers.singleWhere(
      (layer) => layer['id'] == forecastWindLayer,
    );
    expect(weather['paint']['text-color'], forecastDark.text);
    expect(result['terrain'], jsonDecode(base)['terrain']);
  });
}
