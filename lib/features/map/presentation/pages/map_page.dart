import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../core/services/style_provider.dart';

import '../../../telemetry/presentation/providers/telemetry_provider.dart';
import '../components/map_drawer.dart';
import '../components/map_controls.dart';
import '../components/aircraft_map.dart';
import '../components/compass_bar.dart';
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
                  onUserInteraction: cameraController.handleUserInteraction,
                  onMapCreated: cameraController.attachController,
                  onStyleLoaded: (style) {
                    unawaited(cameraController.handleStyleLoaded(style));
                  },
                  onEvent: (event) {
                    if (_isDrawerOpen) return;
                    cameraController.handleMapEvent(event);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) {
                return Center(child: Text('${l10n.mapLoadingError}: $error'));
              },
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AbsorbPointer(
                child: CompassBar(heading: telemetry.heading),
              ),
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
