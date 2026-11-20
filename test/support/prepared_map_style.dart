import 'package:stork/features/map/presentation/providers/map_style_preparer.dart';
import 'package:stork/features/map/presentation/providers/map_overlay_style.dart';

export 'package:stork/features/map/presentation/providers/map_style_preparer.dart'
    show PreparedMapStyle;

PreparedMapStyle testPreparedStyle(String json) => PreparedMapStyle(
  json: json,
  snapshot: PreparedOverlaySnapshot(
    inputs: (),
    sources: {},
    palette: forecastLight,
    notams: [],
    activeIds: [],
    inactiveIds: [],
  ),
);
