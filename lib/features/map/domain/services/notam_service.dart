import 'package:maplibre/maplibre.dart';

import '../models/notam_catalog.dart';
import '../utils/notam_search_area.dart';

Set<String> selectNotamLocations(
  NotamCatalog catalog,
  List<Geographic> points,
) {
  if (points.isEmpty) return const {};
  final searchAreas = [
    if (points.length == 1) NotamSearchArea.circle(points.single),
    for (var i = 1; i < points.length; i++)
      if (points[i - 1].lat != points[i].lat ||
          points[i - 1].lon != points[i].lon)
        NotamSearchArea.leg(points[i - 1], points[i]),
  ];
  if (searchAreas.isEmpty) {
    searchAreas.add(NotamSearchArea.circle(points.first));
  }

  return {
    for (final area in catalog.areas)
      if (searchAreas.any((search) => area.polygons.any(search.intersects)))
        area.icao,
    for (final airport in catalog.airports)
      if (searchAreas.any((search) => search.contains(airport.position)))
        airport.icao,
  };
}
