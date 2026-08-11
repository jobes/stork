import 'dart:ui' show Color;

/// Canonical traffic state colours.
///
/// Shared by the MapLibre style (`icon-color` on `traffic-layer`, see
/// `map_camera_style.dart`) and the Flutter UI (`SpriteIcon` tinting in
/// `traffic_details_dialog.dart`) so the two always stay in sync.
const Color kTrafficThreatColor = Color(0xFFFF3333);
const Color kTrafficFlyingColor = Color(0xFF2196F3);
const Color kTrafficInactiveColor = Color(0xFF9E9E9E);

/// Formats [color] as a `#RRGGBB` hex string for MapLibre style expressions.
String mapColorHex(Color color) =>
    '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
