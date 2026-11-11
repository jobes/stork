import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../core/services/style_provider.dart';
import '../../../../core/services/location_provider.dart';

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
import '../../../telemetry/presentation/widgets/vhf_radio_telemetry_widget.dart';
import '../../../telemetry/presentation/widgets/vario_telemetry_widget.dart';
import '../../../telemetry/presentation/widgets/collision_warning_banner.dart';
import '../components/controls/map_widget_wrapper.dart';
import '../providers/map_camera_provider.dart';
import '../../../navigation/presentation/providers/navigation_provider.dart';
import '../../../navigation/presentation/widgets/navigation_telemetry_widget.dart';
import '../components/controls/map_features_bottom_sheet.dart';
import '../../../settings/presentation/providers/settings_provider.dart';

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> with WidgetsBindingObserver {
  bool _isDrawerOpen = false;
  final _mapStackKey = GlobalKey();
  final _compassKey = GlobalKey();
  final _menuButtonKey = GlobalKey();
  final _gpsButtonKey = GlobalKey();
  final _doneButtonKey = GlobalKey();
  final _alertIndicatorKey = GlobalKey();
  final _widgetKeys = <String, GlobalKey>{};

  Iterable<Rect> _dragObstacles(String widgetId) sync* {
    final stack = _mapStackKey.currentContext?.findRenderObject();
    if (stack is! RenderBox) return;

    for (final key in [
      _compassKey,
      _menuButtonKey,
      _gpsButtonKey,
      _doneButtonKey,
      _alertIndicatorKey,
      for (final entry in _widgetKeys.entries)
        if (entry.key != widgetId) entry.value,
    ]) {
      final box = key.currentContext?.findRenderObject();
      if (box is RenderBox && box.attached && box.hasSize) {
        yield box.localToGlobal(Offset.zero, ancestor: stack) & box.size;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Enable immersive mode on the map page
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Auto-trigger GPS waiting state on start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mapCameraProvider.notifier).autoStartGps();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Restore normal system UI mode when leaving the map page
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    ref.read(compassOrientationOffsetProvider.notifier).onMetricsChanged();
  }

  void _finishEditing() {
    unawaited(
      ref.read(appSettingsProvider.notifier).updateAreWidgetsDraggable(false),
    );
  }

  @override
  Widget build(BuildContext context) {
    final styleAsync = ref.watch(mapStyleProvider);
    ref.listen(mapStyleProvider, (_, next) {
      if (next case AsyncError(:final error, :final stackTrace)) {
        debugPrint('MapPage: failed to load map style: $error\n$stackTrace');
      }
    });
    final mapViewState = ref.watch(
      telemetryProvider.select((t) => t.mapViewState),
    );
    final isOilTempSupported = ref.watch(
      telemetryProvider.select((t) => t.isOilTempSupported),
    );
    final isOilPressureSupported = ref.watch(
      telemetryProvider.select((t) => t.isOilPressureSupported),
    );
    final hasCylinderTemp = ref.watch(
      telemetryProvider.select((t) => t.isChtSupported),
    );
    final hasEgt = ref.watch(telemetryProvider.select((t) => t.isEgtSupported));
    final isFuelSupported = ref.watch(
      telemetryProvider.select((t) => t.isFuelSupported),
    );
    final isEngineRpmSupported = ref.watch(
      telemetryProvider.select((t) => t.isEngineRpmSupported),
    );
    final isRadioSupported = ref.watch(
      telemetryProvider.select((t) => t.isRadioSupported),
    );
    final l10n = AppLocalizations.of(context)!;
    final cameraController = ref.watch(mapCameraProvider.notifier);
    final navigationAsync = ref.watch(navigationProvider);
    final fontScale = ref.watch(
      appSettingsProvider.select(
        (s) => (s.value?.mapFontSize ?? 1.0).toDouble(),
      ),
    );
    final compassBarHeight = 40.0 * fontScale;
    final isEditingWidgets = ref.watch(
      appSettingsProvider.select((s) => s.value?.areWidgetsDraggable ?? false),
    );

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
        key: _widgetKeys.putIfAbsent(id, GlobalKey.new),
        dragObstacles: () => _dragObstacles(id),
        widgetId: id,
        defaultTop: top,
        defaultLeft: left,
        child: child,
      );
    }

    final mapScaffold = Scaffold(
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
      drawerScrimColor: Colors.black45,
      body: AbsorbPointer(
        absorbing: _isDrawerOpen,
        child: Stack(
          key: _mapStackKey,
          children: [
            styleAsync.when(
              data: (style) {
                // Keep the native MapLibre platform view inside its own
                // compositing layer, as recommended by Flutter's guidance for
                // Android hybrid-composition platform views. This gives the
                // compositor a stable, cached layer for the map's texture so
                // page-level repaints (drawer transitions, dialogs, banner
                // toggles, layout changes) never re-composite the platform
                // view. Note: the overlay telemetry widgets are already
                // isolated by their own RepaintBoundary inside TelemetryCard,
                // so this is mostly defensive — the per-frame jank wins come
                // from throttling the platform-channel source updates instead.
                return RepaintBoundary(
                  child: AircraftMap(
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
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Center(child: Text(l10n.mapLoadingError)),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AbsorbPointer(key: _compassKey, child: const CompassBar()),
            ),
            if (mapViewState != MapViewState.init || isEditingWidgets) ...[
              buildWidget('speed_widget', 150.0, const SpeedTelemetryWidget()),
              buildWidget(
                'altitude_widget',
                150.0,
                const AltitudeTelemetryWidget(),
              ),
              buildWidget('vario_widget', 150.0, const VarioTelemetryWidget()),
              buildWidget(
                'flight_time_widget',
                150.0,
                const FlightTimeTelemetryWidget(),
              ),
              if (isOilTempSupported)
                buildWidget(
                  'oil_temp_widget',
                  50.0,
                  const OilTempTelemetryWidget(),
                ),
              if (isOilPressureSupported)
                buildWidget(
                  'oil_pressure_widget',
                  50.0,
                  const OilPressureTelemetryWidget(),
                ),
              if (hasCylinderTemp)
                buildWidget(
                  'cylinder_temp_widget',
                  50.0,
                  const CylinderTempTelemetryWidget(),
                ),
              if (hasEgt)
                buildWidget('egt_widget', 50.0, const EgtTelemetryWidget()),
              if (isFuelSupported)
                buildWidget(
                  'fuel_status_widget',
                  50.0,
                  const FuelStatusTelemetryWidget(),
                ),
              if (isEngineRpmSupported)
                buildWidget(
                  'rpm_widget',
                  150.0,
                  const RpmHorizontalTelemetryWidget(),
                ),
              if (isRadioSupported)
                buildWidget(
                  'radio_widget',
                  150.0,
                  const VhfRadioTelemetryWidget(),
                ),
              if (navigationAsync.value?.isActive == true &&
                  navigationAsync.value?.points.isNotEmpty == true)
                MapWidgetWrapper(
                  key: _widgetKeys.putIfAbsent(
                    'navigation_widget',
                    GlobalKey.new,
                  ),
                  dragObstacles: () => _dragObstacles('navigation_widget'),
                  widgetId: 'navigation_widget',
                  defaultTop: currentY + rowHeight + itemGap,
                  defaultLeft: 16.0,
                  child: const NavigationTelemetryWidget(),
                ),
            ],
            Builder(
              builder: (context) => MapControls(
                mapViewState: mapViewState,
                menuButtonKey: _menuButtonKey,
                gpsButtonKey: _gpsButtonKey,
                doneButtonKey: _doneButtonKey,
                alertIndicatorKey: _alertIndicatorKey,
                onMenuPressed: () => Scaffold.of(context).openDrawer(),
                onGpsPressed: cameraController.handleGpsToggle,
                onFinishEditing: isEditingWidgets ? _finishEditing : null,
              ),
            ),
            Positioned(
              top: isEditingWidgets
                  ? math.max(compassBarHeight, 80.0)
                  : compassBarHeight,
              left: 0,
              right: 0,
              child: const CollisionWarningBanner(),
            ),
          ],
        ),
      ),
    );

    return PopScope<void>(
      canPop: !isEditingWidgets || _isDrawerOpen,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && isEditingWidgets && !_isDrawerOpen) {
          _finishEditing();
        }
      },
      child: mapScaffold,
    );
  }
}
