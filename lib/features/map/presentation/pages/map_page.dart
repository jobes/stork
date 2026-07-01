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
import '../../../telemetry/presentation/widgets/cylinder_temp_telemetry_widget.dart';
import '../../../telemetry/presentation/widgets/egt_telemetry_widget.dart';
import '../../../telemetry/presentation/widgets/fuel_status_telemetry_widget.dart';
import '../../../telemetry/presentation/widgets/rpm_horizontal_telemetry_widget.dart';
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

    final double screenWidth = MediaQuery.sizeOf(context).width;
    double currentX = 16.0;
    double currentY = 50.0;
    const double rightMargin = 16.0;
    const double itemGap = 9.0;
    const double rowHeight = 60.0;

    Widget buildWidget(String id, double width, Widget child) {
      if (currentX > 16.0 && currentX + width > screenWidth - rightMargin) {
        currentX = 16.0;
        currentY += rowHeight + itemGap;
      }
      final double left = currentX;
      final double top = currentY;
      currentX += width + itemGap;
      return MapWidgetWrapper(
        key: ValueKey(id),
        widgetId: id,
        defaultTop: top,
        defaultLeft: left,
        child: child,
      );
    }

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
              buildWidget('speed_widget', 150.0, const SpeedTelemetryWidget()),
              buildWidget('altitude_widget', 150.0, const AltitudeTelemetryWidget()),
              buildWidget('flight_time_widget', 150.0, const FlightTimeTelemetryWidget()),
              if (telemetry.isOilTempSupported)
                buildWidget('oil_temp_widget', 50.0, const OilTempTelemetryWidget()),
              if (telemetry.isOilPressureSupported)
                buildWidget('oil_pressure_widget', 50.0, const OilPressureTelemetryWidget()),
              if (telemetry.cylinderHeadTemperatures.isNotEmpty)
                buildWidget('cylinder_temp_widget', 50.0, const CylinderTempTelemetryWidget()),
              if (telemetry.exhaustGasTemperatures.isNotEmpty)
                buildWidget('egt_widget', 50.0, const EgtTelemetryWidget()),
              if (telemetry.isFuelSupported)
                buildWidget('fuel_status_widget', 50.0, const FuelStatusTelemetryWidget()),
              if (telemetry.isEngineRpmSupported)
                buildWidget('rpm_widget', 150.0, const RpmHorizontalTelemetryWidget()),
              if (navigationAsync.value?.isActive == true &&
                  navigationAsync.value?.points.isNotEmpty == true)
                MapWidgetWrapper(
                  key: const ValueKey('navigation_widget'),
                  widgetId: 'navigation_widget',
                  defaultTop: currentY + rowHeight + itemGap,
                  defaultLeft: 16.0,
                  child: const NavigationTelemetryWidget(),
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
