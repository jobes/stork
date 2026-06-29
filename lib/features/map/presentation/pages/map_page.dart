import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../core/services/style_provider.dart';

import '../../../telemetry/presentation/providers/telemetry_provider.dart';
import '../../../telemetry/domain/models/map_view_state.dart';
import '../components/controls/map_drawer.dart';
import '../components/controls/map_controls.dart';
import '../components/controls/aircraft_map.dart';
import '../components/controls/compass_bar.dart';
import '../../../telemetry/presentation/widgets/speed_telemetry_widget.dart';
import '../../../telemetry/presentation/widgets/altitude_telemetry_widget.dart';
import '../../../telemetry/presentation/widgets/flight_time_telemetry_widget.dart';
import '../../../telemetry/presentation/widgets/oil_temp_telemetry_widget.dart';
import '../../../telemetry/presentation/widgets/oil_pressure_telemetry_widget.dart';
import '../components/controls/map_widget_wrapper.dart';
import '../providers/map_camera_provider.dart';
import '../../../navigation/presentation/providers/navigation_provider.dart';
import '../../../navigation/presentation/widgets/navigation_telemetry_widget.dart';
import '../components/controls/map_features_bottom_sheet.dart';

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
    final navigationAsync = ref.watch(navigationProvider);

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
                    cameraController.handleMapEvent(
                      event,
                      onFeaturesTapped: (features, coordinate) {
                        if (!mounted) return;
                        showMapFeaturesBottomSheet(
                          context,
                          features,
                          coordinate,
                        );
                      },
                    );
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
            if (telemetry.mapViewState != MapViewState.init) ...[
              const MapWidgetWrapper(
                widgetId: 'speed_widget',
                defaultTop: 50.0, // Odsadenie pod kompas
                defaultLeft: 16.0,
                child: SpeedTelemetryWidget(),
              ),
              const MapWidgetWrapper(
                widgetId: 'altitude_widget',
                defaultTop: 50.0, // Odsadenie pod kompas
                defaultLeft: 175.0, // Vedľa speed widgetu
                child: AltitudeTelemetryWidget(),
              ),
              const MapWidgetWrapper(
                widgetId: 'flight_time_widget',
                defaultTop: 50.0,
                defaultLeft: 334.0, // Vedľa altitude widgetu
                child: FlightTimeTelemetryWidget(),
              ),
              if (telemetry.isOilTempSupported)
                const MapWidgetWrapper(
                  widgetId: 'oil_temp_widget',
                  defaultTop: 50.0,
                  defaultLeft: 493.0, // Vedľa flight_time widgetu
                  child: OilTempTelemetryWidget(),
                ),
              if (telemetry.isOilPressureSupported)
                const MapWidgetWrapper(
                  widgetId: 'oil_pressure_widget',
                  defaultTop: 50.0,
                  defaultLeft: 552.0, // Vedľa oil_temp widgetu
                  child: OilPressureTelemetryWidget(),
                ),
              if (navigationAsync.value?.isActive == true &&
                  navigationAsync.value?.points.isNotEmpty == true)
                const MapWidgetWrapper(
                  widgetId: 'navigation_widget',
                  defaultTop: 120.0,
                  defaultLeft: 16.0,
                  child: NavigationTelemetryWidget(),
                ),
            ],
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
