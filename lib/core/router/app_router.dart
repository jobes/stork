import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import '../../features/map/presentation/pages/map_page.dart';
import '../../features/offline_maps/presentation/pages/offline_maps_page_web.dart'
    if (dart.library.io) '../../features/offline_maps/presentation/pages/offline_maps_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/navigation/presentation/pages/navigation_page.dart';
import '../../features/telemetry/presentation/pages/flight_records_page.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const MapPage()),
    if (!kIsWeb)
      GoRoute(
        path: '/offline-maps',
        builder: (context, state) => const OfflineMapsPage(),
      ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsPage(),
    ),
    GoRoute(
      path: '/navigation',
      builder: (context, state) => const NavigationPage(),
    ),
    GoRoute(
      path: '/flight-records',
      builder: (context, state) => const FlightRecordsPage(),
    ),
  ],
);
