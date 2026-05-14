import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/models/telemetry_state.dart';
import '../../domain/models/map_view_state.dart';

part 'telemetry_provider.g.dart';

@Riverpod(keepAlive: true)
class TelemetryNotifier extends _$TelemetryNotifier {
  @override
  TelemetryState build() {
    return const TelemetryState();
  }

  void updateGPS({
    double? latitude,
    double? longitude,
    double? heading,
    double? speed,
  }) {
    final oldState = state;
    state = state.copyWith(
      latitude: latitude,
      longitude: longitude,
      heading: heading,
      speed: speed,
    );

    // Auto-transition to overview if GPS is filled and we are in init/waiting state
    if ((oldState.mapViewState == MapViewState.init ||
            oldState.mapViewState == MapViewState.waitingForGps) &&
        latitude != null &&
        longitude != null &&
        (latitude != 0.0 || longitude != 0.0)) {
      state = state.copyWith(mapViewState: MapViewState.overview);
    }
  }

  void updateEngineRPM(double rpm) {
    state = state.copyWith(engineRPM: rpm);
  }

  void updatePressure(double pressure) {
    state = state.copyWith(airPressure: pressure);
  }

  void updateAltitude({double? altitude, double? heightAboveGround}) {
    state = state.copyWith(
      altitude: altitude,
      heightAboveGround: heightAboveGround,
    );
  }

  void setMapViewState(MapViewState viewState) {
    state = state.copyWith(mapViewState: viewState);
  }

  void updateAll(TelemetryState newState) {
    state = newState;
  }
}
