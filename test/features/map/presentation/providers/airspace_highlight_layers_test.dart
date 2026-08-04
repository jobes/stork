import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre/maplibre.dart';
import 'package:stork/features/map/presentation/providers/airspace_highlight_layers.dart';

/// Style JSON with the hit-test layer and all four AUP highlight layers
/// (mirrors the definitions in `assets/openaip/styles.json`).
Map<String, dynamic> _styleWithHitTest() {
  return jsonDecode('''
{
  "layers": [
    {"id": "airspace_clicktarget", "type": "fill"},
    {"id": "active-airspaces-fill", "type": "fill", "paint": {"fill-color": "#9C27B0", "fill-opacity": 0.35}},
    {"id": "active-airspaces-line", "type": "line", "paint": {"line-color": "#FF1744", "line-width": 3.0}},
    {"id": "inactive-airspaces-fill", "type": "fill", "paint": {"fill-color": "#4CAF50", "fill-opacity": 0.15}},
    {"id": "inactive-airspaces-line", "type": "line", "paint": {"line-color": "#2E7D32", "line-width": 1.5}}
  ]
}
''')
      as Map<String, dynamic>;
}

/// Style JSON without the `airspace_clicktarget` hit-test layer.
Map<String, dynamic> _styleWithoutHitTest() {
  final style = _styleWithHitTest();
  (style['layers'] as List).removeWhere(
    (layer) => (layer as Map)['id'] == 'airspace_clicktarget',
  );
  return style;
}

/// Records every style mutation so tests can assert what was applied.
class FakeStyleController extends StyleController {
  final List<String> removedLayerIds = [];
  final List<({StyleLayer layer, String? belowLayerId})> addedLayers = [];

  @override
  Future<void> addLayer(
    StyleLayer layer, {
    String? belowLayerId,
    String? aboveLayerId,
    int? atIndex,
  }) async {
    addedLayers.add((layer: layer, belowLayerId: belowLayerId));
  }

  @override
  Future<void> removeLayer(String id) async {
    removedLayerIds.add(id);
  }

  @override
  Future<void> addSource(Source source) async {}

  @override
  Future<void> updateGeoJsonSource({
    required String id,
    required String data,
  }) async {}

  @override
  Future<void> removeSource(String id) async {}

  @override
  Future<List<String>> getAttributions() async => const [];

  @override
  List<String> getAttributionsSync() => const [];

  @override
  List<String> getLayerIds() => [...removedLayerIds];

  @override
  Future<void> addImage(String id, Uint8List bytes) async {}

  @override
  Future<void> removeImage(String id) async {}

  @override
  void setProjection(MapProjection projection) {}

  @override
  void dispose() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('airspaceSourceIdFilter', () {
    test('matches only the given openAIP ids', () {
      expect(airspaceSourceIdFilter(['a1', 'a2']), [
        'all',
        [
          'in',
          ['get', 'source_id'],
          [
            'literal',
            ['a1', 'a2'],
          ],
        ],
      ]);
    });

    test('an empty id list matches nothing', () {
      expect(airspaceSourceIdFilter(const []), [
        'all',
        [
          'in',
          ['get', 'source_id'],
          ['literal', <String>[]],
        ],
      ]);
    });
  });

  group('AirspaceHighlightLayers.updateLayers', () {
    test('applies active/inactive layers with paints from the style below the '
        'hit-test layer', () async {
      final fake = FakeStyleController();
      final applier = AirspaceHighlightLayers(
        styleLoader: () async => _styleWithHitTest(),
      );

      await applier.updateLayers(
        fake,
        activeIds: ['asp1', 'asp2'],
        inactiveIds: ['asp3'],
      );

      // The previous highlight layers are always removed first.
      expect(fake.removedLayerIds, airspaceHighlightLayerIds);
      expect(fake.addedLayers, hasLength(4));

      // Active fill: filter + paint from styles.json, below the hit-test layer.
      final activeFill = fake.addedLayers[0].layer as FillStyleLayer;
      expect(activeFill.id, 'active-airspaces-fill');
      expect(activeFill.sourceId, 'openaip-data');
      expect(activeFill.sourceLayerId, 'airspaces');
      expect(activeFill.filter, airspaceSourceIdFilter(['asp1', 'asp2']));
      expect(activeFill.paint, {'fill-color': '#9C27B0', 'fill-opacity': 0.35});
      expect(fake.addedLayers[0].belowLayerId, 'airspace_clicktarget');

      final activeLine = fake.addedLayers[1].layer as LineStyleLayer;
      expect(activeLine.id, 'active-airspaces-line');
      expect(activeLine.filter, airspaceSourceIdFilter(['asp1', 'asp2']));
      expect(activeLine.paint, {'line-color': '#FF1744', 'line-width': 3.0});

      final inactiveFill = fake.addedLayers[2].layer as FillStyleLayer;
      expect(inactiveFill.id, 'inactive-airspaces-fill');
      expect(inactiveFill.filter, airspaceSourceIdFilter(['asp3']));
      expect(inactiveFill.paint, {
        'fill-color': '#4CAF50',
        'fill-opacity': 0.15,
      });

      final inactiveLine = fake.addedLayers[3].layer as LineStyleLayer;
      expect(inactiveLine.id, 'inactive-airspaces-line');
      expect(inactiveLine.filter, airspaceSourceIdFilter(['asp3']));
      expect(inactiveLine.paint, {'line-color': '#2E7D32', 'line-width': 1.5});
    });

    test(
      'removes all highlight layers when there is nothing to highlight',
      () async {
        final fake = FakeStyleController();
        final applier = AirspaceHighlightLayers(
          styleLoader: () async => _styleWithHitTest(),
        );

        await applier.updateLayers(
          fake,
          activeIds: const [],
          inactiveIds: const [],
        );

        expect(fake.removedLayerIds, airspaceHighlightLayerIds);
        expect(fake.addedLayers, isEmpty);
      },
    );

    test('appends at the end of the layer stack when the hit-test layer is '
        'missing from the style', () async {
      final fake = FakeStyleController();
      final applier = AirspaceHighlightLayers(
        styleLoader: () async => _styleWithoutHitTest(),
      );

      await applier.updateLayers(
        fake,
        activeIds: ['asp1'],
        inactiveIds: const [],
      );

      expect(fake.addedLayers, hasLength(4));
      for (final added in fake.addedLayers) {
        expect(added.belowLayerId, isNull);
      }
    });

    test('falls back to the MapLibre default paints when a layer is not '
        'defined in the style', () async {
      final fake = FakeStyleController();
      final applier = AirspaceHighlightLayers(
        styleLoader: () async => {
          'layers': [
            {'id': 'airspace_clicktarget', 'type': 'fill'},
          ],
        },
      );

      await applier.updateLayers(
        fake,
        activeIds: ['asp1'],
        inactiveIds: ['asp2'],
      );

      expect(fake.addedLayers, hasLength(4));
      for (final added in fake.addedLayers) {
        expect(added.layer.paint, isEmpty);
        expect(added.belowLayerId, 'airspace_clicktarget');
      }
    });

    test(
      're-applying replaces the previously applied highlight layers',
      () async {
        final fake = FakeStyleController();
        final applier = AirspaceHighlightLayers(
          styleLoader: () async => _styleWithHitTest(),
        );

        await applier.updateLayers(
          fake,
          activeIds: ['asp1'],
          inactiveIds: const [],
        );
        await applier.updateLayers(
          fake,
          activeIds: ['asp1', 'asp2'],
          inactiveIds: ['asp3'],
        );

        // Both applications remove the previous layers before re-adding.
        expect(fake.removedLayerIds, [
          ...airspaceHighlightLayerIds,
          ...airspaceHighlightLayerIds,
        ]);
        expect(fake.addedLayers, hasLength(8));

        // The second application carries the new filters.
        final secondActiveFill = fake.addedLayers[4].layer as FillStyleLayer;
        expect(
          secondActiveFill.filter,
          airspaceSourceIdFilter(['asp1', 'asp2']),
        );
      },
    );
  });

  group('real styles.json asset', () {
    test('defines the AUP highlight layers and the hit-test layer', () async {
      final raw = await rootBundle.loadString('assets/openaip/styles.json');
      final style = jsonDecode(raw) as Map<String, dynamic>;

      for (final id in airspaceHighlightLayerIds) {
        expect(
          AirspaceHighlightLayers.styleHasLayer(style, id),
          isTrue,
          reason: 'missing layer $id in assets/openaip/styles.json',
        );
      }
      expect(
        AirspaceHighlightLayers.styleHasLayer(style, 'airspace_clicktarget'),
        isTrue,
      );
    });
  });
}
