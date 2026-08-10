import 'package:flutter/foundation.dart' show debugPrint;
import 'package:url_launcher/url_launcher.dart';

import '../domain/models/navigation_point.dart';

/// Builds a Windy route-planner URL
/// (`https://www.windy.com/route-planner/vfr/lat,lng;lat,lng;...`) for the
/// given route points, starting from the current position when available,
/// matching the format used by LAA Map.
String buildWindyRouteUrl(
  List<NavigationPoint> points, {
  double? currentLatitude,
  double? currentLongitude,
}) {
  if (points.isEmpty) return '';
  final route = <String>[
    if (currentLatitude != null &&
        currentLongitude != null &&
        !(currentLatitude == 0.0 && currentLongitude == 0.0))
      '$currentLatitude,$currentLongitude',
    ...points.map((p) => '${p.latitude},${p.longitude}'),
  ];
  return 'https://www.windy.com/route-planner/vfr/${route.join(';')}';
}

/// Opens Windy's route planner in an external app/browser for the given route
/// points, starting from the current position when available.
Future<void> openWindyRoute(
  List<NavigationPoint> points, {
  double? currentLatitude,
  double? currentLongitude,
}) async {
  final url = Uri.parse(
    buildWindyRouteUrl(
      points,
      currentLatitude: currentLatitude,
      currentLongitude: currentLongitude,
    ),
  );
  try {
    final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!launched) {
      debugPrint('Failed to open Windy route URL: $url');
    }
  } catch (e) {
    debugPrint('Failed to open Windy route URL: $e');
  }
}
