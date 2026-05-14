import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre/maplibre.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../core/services/style_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../telemetry/presentation/providers/telemetry_provider.dart';
import '../components/map_drawer.dart';
import '../components/map_controls.dart';
import '../components/aircraft_map.dart';
import '../providers/map_camera_provider.dart';

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  bool _isDrawerOpen = false;

  @override
  void initState() {
    super.initState();
    // Auto-trigger GPS waiting state on start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mapCameraProvider.notifier).autoStartGps();
    });
  }

  @override
  Widget build(BuildContext context) {
    final styleAsync = ref.watch(mapStyleProvider);
    final telemetry = ref.watch(telemetryProvider);
    final l10n = AppLocalizations.of(context)!;
    final cameraController = ref.watch(mapCameraProvider.notifier);

    // Enable immersive mode on the map page
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    return Scaffold(
      onDrawerChanged: (isOpen) {
        if (isOpen) {
          setState(() {
            _isDrawerOpen = true;
          });
        } else {
          // Delay before setting _isDrawerOpen to false
          Future.delayed(const Duration(milliseconds: 0), () {
            if (mounted) {
              setState(() {
                _isDrawerOpen = false;
              });
            }
          });
        }
      },
      drawer: const MapDrawer(),
      body: AbsorbPointer(
        absorbing: _isDrawerOpen,
        child: Stack(
          children: [
            styleAsync.when(
              data: (style) {
                return AircraftMap(
                  style: style,
                  telemetry: telemetry,
                  onUserInteraction: cameraController.handleUserInteraction,
                  onMapCreated: (controller) {
                    cameraController.attachController(controller);
                  },
                  onStyleLoaded: (style) {
                    debugPrint('Map loaded 😎');
                  },
                  onEvent: (event) async {
                    if (_isDrawerOpen) return;

                    // If camera is moving and it's not triggered by our code,
                    // it must be the user interacting with the map.
                    if (event is MapEventMoveCamera) {
                      cameraController.handleUserInteraction(
                        isExplicitInteraction: false,
                      );
                    }

                    if (event is MapEventClick) {
                      debugPrint('Map clicked at ${event.point}');
                      // Optional: handle clicks in controller if needed
                    }
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) {
                return Center(child: Text('${l10n.mapLoadingError}: $error'));
              },
            ),
            Builder(
              builder: (context) => MapControls(
                mapViewState: telemetry.mapViewState,
                onMenuPressed: () => Scaffold.of(context).openDrawer(),
                onGpsPressed: cameraController.handleGpsToggle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


