import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import '../../features/map/presentation/pages/map_page.dart';
import '../../features/offline_maps/presentation/pages/offline_maps_page_web.dart'
    if (dart.library.io) '../../features/offline_maps/presentation/pages/offline_maps_page.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const MapPage()),
    if (!kIsWeb)
      GoRoute(
        path: '/offline-maps',
        builder: (context, state) => const OfflineMapsPage(),
      ),
  ],
);
