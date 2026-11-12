import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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
import '../components/controls/utc_clock_widget.dart';
import '../providers/map_camera_provider.dart';
import '../providers/map_radar.dart';
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
  late final _radar = ref.read(mapRadarProvider);
  Timer? _radarRefresh;
  bool _appInForeground = true;
  bool _mapIsCurrent = false;
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
    _radarRefresh = Timer.periodic(
      MapRadar.refreshInterval,
      (_) => _refreshRadarIfVisible(),
    );
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
    _radarRefresh?.cancel();
    // Restore normal system UI mode when leaving the map page
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appInForeground = state == AppLifecycleState.resumed;
    if (_appInForeground) {
      _refreshRadarIfVisible();
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      _radar.interruptPlayback();
    }
  }

  void _refreshRadarIfVisible() {
    if (mounted && _appInForeground && _mapIsCurrent) {
      unawaited(_radar.refresh());
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
    final isCurrent = ModalRoute.isCurrentOf(context) ?? true;
    ref.watch(mapRadarProvider);
    if (isCurrent != _mapIsCurrent) {
      _mapIsCurrent = isCurrent;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _mapIsCurrent != isCurrent) return;
        if (isCurrent) {
          _refreshRadarIfVisible();
        } else {
          _radar.interruptPlayback();
        }
      });
    }
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
    final showUtcClock = ref.watch(
      appSettingsProvider.select((s) => s.value?.showUtcClock ?? true),
    );
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
      drawer: MapDrawer(
        radar: _radar,
        onRadarPlayback: () => unawaited(_radar.play()),
      ),
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
                      _radar.attachStyle(style);
                      unawaited(cameraController.handleStyleLoaded(style));
                    },
                    onEvent: (event) {
                      _radar.onMapEvent(event);
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
            ],
            if (showUtcClock)
              buildWidget(
                'utc_clock_widget',
                120.0 * fontScale,
                const UtcClockWidget(),
              ),
            if ((mapViewState != MapViewState.init || isEditingWidgets) &&
                navigationAsync.value?.isActive == true &&
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
              left: 16,
              right: 16,
              bottom: 12,
              child: IgnorePointer(
                child: SafeArea(
                  top: false,
                  child: ValueListenableBuilder(
                    valueListenable: _radar,
                    builder: (context, radar, _) {
                      final time = radar.playing;
                      if (!radar.preparing && time == null) {
                        return const SizedBox.shrink();
                      }
                      final theme = Theme.of(context);
                      return Center(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            child: Text(
                              time == null
                                  ? l10n.radarPreparing
                                  : l10n.radarPlaybackTime(
                                      DateFormat('HH:mm').format(time),
                                    ),
                              style: theme.textTheme.labelLarge,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
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
