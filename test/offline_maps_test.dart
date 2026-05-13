import 'package:test/test.dart';
import 'package:stork/features/offline_maps/domain/tile_utils.dart';

void main() {
  group('TileUtils', () {
    test('getTilesForRegion should return zoom 0 tile', () {
      final tiles = getTilesForRegion(
        minLat: -90,
        minLon: -180,
        maxLat: 90,
        maxLon: 180,
        minZ: 0,
        maxZ: 0,
        kind: 'protomaps',
      );
      expect(tiles.length, 1);
      expect(tiles.first, TileCoord(0, 0, 0, 'protomaps'));
    });

    test('getTilesForRegion should return correct tiles for zoom 1', () {
      final tiles = getTilesForRegion(
        minLat: -90,
        minLon: -180,
        maxLat: 90,
        maxLon: 180,
        minZ: 1,
        maxZ: 1,
        kind: 'protomaps',
      );
      expect(tiles.length, 4);
      expect(
        tiles,
        containsAll([
          TileCoord(1, 0, 0, 'protomaps'),
          TileCoord(1, 1, 0, 'protomaps'),
          TileCoord(1, 0, 1, 'protomaps'),
          TileCoord(1, 1, 1, 'protomaps'),
        ]),
      );
    });

    test('getTilesForRegion should return tiles for a small area', () {
      // Bratislava area
      final tiles = getTilesForRegion(
        minLat: 48.0,
        minLon: 17.0,
        maxLat: 48.2,
        maxLon: 17.2,
        minZ: 10,
        maxZ: 10,
        kind: 'protomaps',
      );
      // At zoom 10, 1 degree is ~2.8 tiles. 0.2 degrees should be 1 tile.
      expect(tiles.isNotEmpty, true);
      for (final tile in tiles) {
        expect(tile.z, 10);
      }
    });
  });
}
