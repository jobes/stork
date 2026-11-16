import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import '../../../../telemetry/domain/models/map_view_state.dart';
import '../../../../../l10n/app_localizations.dart';
import 'map_alert_indicator.dart';

class MapControls extends StatelessWidget {
  final MapViewState mapViewState;
  final VoidCallback onMenuPressed;
  final VoidCallback onSearchPressed;
  final VoidCallback onGpsPressed;
  final VoidCallback? onFinishEditing;
  final double buttonScale;
  final Key? menuButtonKey;
  final Key? searchButtonKey;
  final Key? gpsButtonKey;
  final Key? doneButtonKey;
  final Key? alertIndicatorKey;

  const MapControls({
    super.key,
    required this.mapViewState,
    required this.onMenuPressed,
    required this.onSearchPressed,
    required this.onGpsPressed,
    this.onFinishEditing,
    this.buttonScale = 1.0,
    this.menuButtonKey,
    this.searchButtonKey,
    this.gpsButtonKey,
    this.doneButtonKey,
    this.alertIndicatorKey,
  });

  static const padding = 16.0;
  static const buttonExtent = 48.0;
  static const _buttonGap = 8.0;

  static double fitButtonScale(
    double scale, {
    required double safeWidth,
    required bool isEditing,
  }) {
    // Leave space for all four controls and the edit-mode action on phones.
    final rowWidth = 4 * buttonExtent + (isEditing ? 112 : 0);
    final availableWidth = safeWidth - 2 * padding - 2 * _buttonGap;
    return (availableWidth / rowWidth).clamp(0.0, scale);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final iconSize = 24.0 * buttonScale;
    final buttonSize = Size.square(40.0 * buttonScale);
    final iconPadding = EdgeInsets.all(8.0 * buttonScale);

    final leftButtonStyle = IconButton.styleFrom(
      elevation: 4,
      shadowColor: Colors.black.withAlpha(76),
      minimumSize: buttonSize,
      iconSize: iconSize,
      padding: iconPadding,
    );

    final gpsTooltip = mapViewState == MapViewState.waitingForGps
        ? l10n.gpsWaiting
        : mapViewState == MapViewState.init
        ? l10n.gpsEnable
        : mapViewState == MapViewState.follow
        ? l10n.gpsStopFollow
        : l10n.gpsFollow;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(padding),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                PointerInterceptor(
                  child: IconButton.filled(
                    key: menuButtonKey,
                    style: leftButtonStyle,
                    icon: const Icon(Icons.menu),
                    tooltip: l10n.menu,
                    onPressed: onMenuPressed,
                  ),
                ),
                const SizedBox(width: _buttonGap),
                PointerInterceptor(
                  child: IconButton.filled(
                    key: searchButtonKey,
                    style: leftButtonStyle,
                    icon: const Icon(Icons.search),
                    tooltip: l10n.mapSearch,
                    onPressed: onSearchPressed,
                  ),
                ),
              ],
            ),
            if (onFinishEditing != null)
              Flexible(
                child: PointerInterceptor(
                  child: FilledButton.icon(
                    key: doneButtonKey,
                    style: FilledButton.styleFrom(
                      minimumSize: Size(64, buttonSize.height),
                      textStyle: theme.textTheme.labelLarge?.copyWith(
                        fontSize:
                            (theme.textTheme.labelLarge?.fontSize ?? 14) *
                            buttonScale,
                      ),
                    ),
                    icon: Icon(Icons.check, size: 18 * buttonScale),
                    label: Text(l10n.menuDone, maxLines: 1),
                    onPressed: onFinishEditing,
                  ),
                ),
              ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox.square(
                  key: alertIndicatorKey,
                  dimension: buttonExtent * buttonScale,
                  child: const FittedBox(child: MapAlertIndicator()),
                ),
                const SizedBox(width: _buttonGap),
                PointerInterceptor(
                  child: IconButton.filled(
                    key: gpsButtonKey,
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.tertiary,
                      foregroundColor: Theme.of(context).colorScheme.onTertiary,
                      elevation: 4,
                      shadowColor: Colors.black.withAlpha(76),
                      minimumSize: buttonSize,
                      iconSize: iconSize,
                      padding: iconPadding,
                    ),
                    tooltip: gpsTooltip,
                    icon: mapViewState == MapViewState.waitingForGps
                        ? SizedBox(
                            width: 18 * buttonScale,
                            height: 18 * buttonScale,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).colorScheme.onTertiary,
                            ),
                          )
                        : Icon(
                            mapViewState == MapViewState.init
                                ? Icons.gps_not_fixed
                                : mapViewState == MapViewState.follow
                                ? Icons.navigation
                                : Icons.gps_fixed,
                          ),
                    onPressed: onGpsPressed,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
