import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import '../../../../telemetry/domain/models/map_view_state.dart';
import '../../../../../l10n/app_localizations.dart';

class MapControls extends StatelessWidget {
  final MapViewState mapViewState;
  final VoidCallback onMenuPressed;
  final VoidCallback onGpsPressed;
  final VoidCallback? onFinishEditing;
  final Key? menuButtonKey;
  final Key? gpsButtonKey;
  final Key? doneButtonKey;

  const MapControls({
    super.key,
    required this.mapViewState,
    required this.onMenuPressed,
    required this.onGpsPressed,
    this.onFinishEditing,
    this.menuButtonKey,
    this.gpsButtonKey,
    this.doneButtonKey,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final gpsTooltip = mapViewState == MapViewState.waitingForGps
        ? l10n.gpsWaiting
        : mapViewState == MapViewState.init
        ? l10n.gpsEnable
        : mapViewState == MapViewState.follow
        ? l10n.gpsStopFollow
        : l10n.gpsFollow;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            PointerInterceptor(
              child: IconButton.filled(
                key: menuButtonKey,
                style: IconButton.styleFrom(
                  elevation: 4,
                  shadowColor: Colors.black.withAlpha(76),
                ),
                icon: const Icon(Icons.menu),
                tooltip: l10n.menu,
                onPressed: onMenuPressed,
              ),
            ),
            if (onFinishEditing != null)
              Flexible(
                child: PointerInterceptor(
                  child: FilledButton.icon(
                    key: doneButtonKey,
                    icon: const Icon(Icons.check),
                    label: Text(l10n.menuDone),
                    onPressed: onFinishEditing,
                  ),
                ),
              ),
            PointerInterceptor(
              child: IconButton.filled(
                key: gpsButtonKey,
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.tertiary,
                  foregroundColor: Theme.of(context).colorScheme.onTertiary,
                  elevation: 4,
                  shadowColor: Colors.black.withAlpha(76),
                ),
                tooltip: gpsTooltip,
                icon: mapViewState == MapViewState.waitingForGps
                    ? SizedBox(
                        width: 18,
                        height: 18,
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
      ),
    );
  }
}
