import 'dart:convert';
import 'dart:io';

/// The 1× app sprite sheet and its JSON index
/// (see `documentation/architecture/map-sprite.md`).
const String kSpriteIndexPath = 'assets/map_sprites/sprite.json';
const String kSpriteSheetPath = 'assets/map_sprites/sprite.png';

/// Loads and decodes the 1× app sprite index.
Map<String, dynamic> loadSpriteIndex() =>
    jsonDecode(File(kSpriteIndexPath).readAsStringSync())
        as Map<String, dynamic>;

/// Reads the width/height of a PNG from its IHDR header (bytes 16–23).
(int, int) pngSize(String path) {
  final bytes = File(path).readAsBytesSync();
  int u32(int offset) =>
      (bytes[offset] << 24) |
      (bytes[offset + 1] << 16) |
      (bytes[offset + 2] << 8) |
      bytes[offset + 3];
  return (u32(16), u32(20));
}

/// Returns the ids of frames in [index] whose bounding box does not fit
/// within the 1× sheet ([sheetPath]). A regenerated sprite with a broken
/// layout (frames past the sheet edge) is caught here.
List<String> overflowingFrames(
  Map<String, dynamic> index, {
  String sheetPath = kSpriteSheetPath,
}) {
  final (sheetWidth, sheetHeight) = pngSize(sheetPath);
  final problems = <String>[];
  for (final entry in index.entries) {
    final frame = entry.value as Map<String, dynamic>;
    final x = (frame['x'] as num).toDouble();
    final y = (frame['y'] as num).toDouble();
    final width = (frame['width'] as num).toDouble();
    final height = (frame['height'] as num).toDouble();
    if (x < 0 || y < 0 || x + width > sheetWidth || y + height > sheetHeight) {
      problems.add(entry.key);
    }
  }
  return problems;
}
