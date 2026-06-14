import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import '../../../../telemetry/domain/models/map_view_state.dart';
import '../../../../../l10n/app_localizations.dart';

class MapControls extends StatelessWidget {
  final MapViewState mapViewState;
  final VoidCallback onMenuPressed;
  final VoidCallback onGpsPressed;

  const MapControls({
    super.key,
    required this.mapViewState,
    required this.onMenuPressed,
    required this.onGpsPressed,
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
                style: IconButton.styleFrom(
                  elevation: 4,
                  shadowColor: Colors.black.withAlpha(76),
                ),
                icon: const Icon(Icons.menu),
                tooltip: l10n.menu,
                onPressed: onMenuPressed,
              ),
            ),
            PointerInterceptor(
              child: IconButton.filled(
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
