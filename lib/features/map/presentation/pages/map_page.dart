import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre/maplibre.dart';
import 'package:go_router/go_router.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../core/services/style_provider.dart';
import '../../../../core/services/location_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  MapController? _mapController;
  bool _isDrawerOpen = false;

  @override
  Widget build(BuildContext context) {
    final styleAsync = ref.watch(mapStyleProvider);
    final settingsAsync = ref.watch(appSettingsProvider);
    final l10n = AppLocalizations.of(context)!;
    final settings = settingsAsync.value;

    // Enable immersive mode on the map page
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    ref.listen(currentLocationProvider, (previous, next) {
      next.whenData((location) {
        if (location != null && _mapController != null && settings != null) {
          _mapController!.animateCamera(
            center: location,
            zoom: settings.mapDefaultZoom,
          );
        }
      });
    });

    return Scaffold(
      onDrawerChanged: (isOpen) {
        if (isOpen) {
          setState(() {
            _isDrawerOpen = true;
          });
        } else {
          // Delay before setting _isDrawerOpen to false
          // to prevent the map from intercepting clicks while the drawer is closing.
          Future.delayed(const Duration(milliseconds: 0), () {
            if (mounted) {
              setState(() {
                _isDrawerOpen = false;
              });
            }
          });
        }
      },
      drawer: Drawer(
        child: PointerInterceptor(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.appTitle,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _StatItem(
                          icon: Icons.timer_outlined,
                          value: '---h --m',
                          label: l10n.pilotTotalHours,
                        ),
                        const SizedBox(width: 16),
                        _StatItem(
                          icon: Icons.airplanemode_active,
                          value: '---h --m',
                          label: l10n.aircraftTotalHours,
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.anonymousPilot,
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimary,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                l10n.unknownAircraft,
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimary.withAlpha(204),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.settings),
                          color: Theme.of(context).colorScheme.onPrimary,
                          onPressed: () {
                            context.pop();
                            context.push('/settings');
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!kIsWeb)
                ListTile(
                  leading: const Icon(Icons.map),
                  title: Text(l10n.offlineMaps),
                  onTap: () {
                    context.pop(); // Close drawer
                    context.push('/offline-maps');
                  },
                ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.settings),
                title: Text(l10n.editSettings),
                onTap: () {
                  context.pop();
                  context.push('/settings');
                },
              ),
            ],
          ),
        ),
      ),
      body: AbsorbPointer(
        absorbing: _isDrawerOpen,
        child: Stack(
          children: [
            styleAsync.when(
              data: (style) {
                return MapLibreMap(
                  options: MapOptions(
                    initCenter: Geographic(lon: 0, lat: 0),
                    initZoom: 2,
                    maxZoom: 14,
                    initStyle: style,
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
                    // If location is already available, move the map immediately
                    ref.read(currentLocationProvider).whenData((location) {
                      if (location != null && settings != null) {
                        controller.animateCamera(
                          center: location,
                          zoom: settings.mapDefaultZoom,
                        );
                      }
                    });
                  },
                  onStyleLoaded: (style) {
                    debugPrint('Map loaded 😎');
                  },
                  onEvent: (event) async {
                    if (_isDrawerOpen) return;
                    if (event is MapEventClick) {
                      debugPrint('Map clicked at ${event.point}');
                      if (_mapController != null) {
                        final features = _mapController!.featuresAtPoint(
                          event.screenPoint,
                        );
                        for (var feature in features) {
                          final properties = feature.properties;
                          final featureType = properties['feature_type'];
                          final country = properties['country'];
                          final sourceId = properties['source_id'];
                          if (featureType != null ||
                              country != null ||
                              sourceId != null) {
                            debugPrint(
                              'Feature Clicked: info: $featureType, $country, $sourceId',
                            );
                          } else {
                            debugPrint('Feature Clicked: $feature');
                          }
                        }
                      }
                    }
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) {
                return Center(child: Text('${l10n.mapLoadingError}: $error'));
              },
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Builder(
                  builder: (context) => PointerInterceptor(
                    child: IconButton.filled(
                      style: IconButton.styleFrom(
                        elevation: 4,
                        shadowColor: Colors.black.withAlpha(76), // ~0.3 opacity
                      ),
                      icon: const Icon(Icons.menu),
                      tooltip: l10n.menu,
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onPrimary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color.withAlpha(178)),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: TextStyle(color: color.withAlpha(128), fontSize: 10),
        ),
      ],
    );
  }
}
