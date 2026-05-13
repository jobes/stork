import 'dart:math';

class TileCoord {
  final int z;
  final int x;
  final int y;
  final String kind;

  TileCoord(this.z, this.x, this.y, this.kind);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TileCoord &&
          runtimeType == other.runtimeType &&
          z == other.z &&
          x == other.x &&
          y == other.y &&
          kind == other.kind;

  @override
  int get hashCode => z.hashCode ^ x.hashCode ^ y.hashCode ^ kind.hashCode;

  @override
  String toString() => 'TileCoord(z: $z, x: $x, y: $y, kind: $kind)';
}

/// Returns all tiles that intersect the given bounding box for zoom levels [minZ] to [maxZ].
Set<TileCoord> getTilesForRegion({
  required double minLat,
  required double minLon,
  required double maxLat,
  required double maxLon,
  required int minZ,
  required int maxZ,
  required String kind,
}) {
  final tiles = <TileCoord>{};

  for (int z = minZ; z <= maxZ; z++) {
    final n = pow(2, z).toInt();

    // Longitude to x
    int x1 = ((minLon + 180) / 360 * n).floor();
    int x2 = ((maxLon + 180) / 360 * n).floor();

    // Latitude to y (Web Mercator projection)
    int y1 = _latToY(maxLat, n);
    int y2 = _latToY(minLat, n);

    // Ensure bounds and correct order
    int startX = max(0, min(x1, x2));
    int endX = min(n - 1, max(x1, x2));
    int startY = max(0, min(y1, y2));
    int endY = min(n - 1, max(y1, y2));

    for (int x = startX; x <= endX; x++) {
      for (int y = startY; y <= endY; y++) {
        tiles.add(TileCoord(z, x, y, kind));
      }
    }
  }

  return tiles;
}

int _latToY(double lat, int n) {
  // Clamp lat to avoid infinity at poles
  lat = max(-85.0511, min(85.0511, lat));
  double latRad = lat * pi / 180;
  return ((1 - log(tan(latRad) + 1 / cos(latRad)) / pi) / 2 * n).floor();
}
