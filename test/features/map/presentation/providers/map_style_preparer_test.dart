import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stork/features/map/presentation/providers/airspace_highlight_layers.dart';
import 'package:stork/features/map/presentation/providers/map_overlay_style.dart';
import 'package:stork/features/map/presentation/providers/map_style_preparer.dart';

const empty = '{"type":"FeatureCollection","features":[]}';

void main() {
  test('prepares matching style and snapshot without a provider or map', () {
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
        id: empty,
    };
    final base = jsonEncode({
      'version': 8,
      'sprite': 'http://127.0.0.1:8080/map_sprites/sprite',
      'glyphs': 'http://127.0.0.1:8080/fonts/{fontstack}/{range}.pbf',
      'terrain': {'source': 'terrain', 'exaggeration': 1},
      'sources': {
        'terrain': {
          'type': 'raster-dem',
          'tiles': ['http://127.0.0.1:8080/pmtiles/terrain/{z}/{x}/{y}.png'],
        },
      },
      'layers': [
        for (final id in airspaceHighlightLayerIds)
          {'id': id, 'type': 'fill', 'source': 'openaip-data'},
      ],
    });
    final active = ['active'];
    final inactive = ['inactive'];
    final notices = <NotamMapFeature>[
      (key: 'key', id: 'id', title: 'Notice', lat: 48, lon: 17, radius: 1000),
    ];
    data['notams-source'] = buildNotamGeoJson(notices);
    final result = const MapStylePreparer().prepare(
      baseStyle: base,
      data: data,
      fontScale: 1.5,
      palette: forecastDark,
      inputs: (revision: 1),
      notams: notices,
      activeIds: active,
      inactiveIds: inactive,
    );
    final document = jsonDecode(result.json) as Map;
    final original = jsonDecode(base) as Map;
    for (final key in ['sprite', 'glyphs', 'terrain']) {
      expect(document[key], original[key]);
    }
    expect(document['sources']['terrain'], original['sources']['terrain']);
    for (final entry in result.snapshot.sources.entries) {
      expect(document['sources'][entry.key]['data'], jsonDecode(entry.value));
    }
    for (final layer in (document['layers'] as List).take(4)) {
      expect(
        layer['filter'],
        airspaceSourceIdFilter(
          (layer['id'] as String).startsWith('active-') ? active : inactive,
        ),
      );
    }
    final weather = (document['layers'] as List).singleWhere(
      (layer) => layer['id'] == forecastWindLayer,
    );
    expect(weather['paint']['text-color'], forecastDark.text);
    expect(weather['layout']['text-size'], 54);

    // Caller mutations and subsequent preparations cannot alter an old result.
    data.clear();
    active.clear();
    inactive.clear();
    notices.clear();
    for (var i = 0; i < 10; i++) {
      const MapStylePreparer().prepare(
        baseStyle: base,
        data: {},
        fontScale: 1,
        palette: forecastLight,
        inputs: (revision: i + 2),
        notams: [],
        activeIds: [],
        inactiveIds: [],
      );
    }
    expect(result.snapshot.sources, hasLength(7));
    expect(result.snapshot.activeIds, ['active']);
    expect(result.snapshot.inactiveIds, ['inactive']);
    expect(result.snapshot.notams.single.title, 'Notice');
    expect(() => result.snapshot.sources.clear(), throwsUnsupportedError);
    expect(() => result.snapshot.activeIds.clear(), throwsUnsupportedError);
    expect(() => result.snapshot.inactiveIds.clear(), throwsUnsupportedError);
    expect(() => result.snapshot.notams.clear(), throwsUnsupportedError);
  });

  test('NOTAM geometry is a closed ring with stable properties', () {
    final json = jsonDecode(
      buildNotamGeoJson([
        (key: 'key', id: 'id', title: 'Notice', lat: 48, lon: 17, radius: 1000),
      ]),
    );
    final feature = json['features'].single;
    expect(feature['id'], 'key');
    expect(feature['properties'], {
      'key': 'key',
      'id': 'id',
      'title': 'Notice',
    });
    final ring = feature['geometry']['coordinates'].single as List;
    expect(ring, hasLength(33));
    expect(ring.first, ring.last);
  });
}
