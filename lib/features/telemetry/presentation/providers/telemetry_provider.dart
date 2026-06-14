import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/models/telemetry_state.dart';
import '../../domain/models/map_view_state.dart';
import 'package:stork/features/settings/presentation/providers/settings_provider.dart';
import 'package:stork/core/services/location_provider.dart';
import 'decayable_field.dart';

part 'telemetry_provider.g.dart';

@Riverpod(keepAlive: true)
class TelemetryNotifier extends _$TelemetryNotifier {
  late final DecayableField<double> _latitude = DecayableField<double>(
    timeout: Duration.zero,
    onChanged: (val) {
      state = val == null
          ? state.resetField(TelemetryField.latitude)
          : state.copyWith(latitude: val);
    },
  );
  late final DecayableField<double> _longitude = DecayableField<double>(
    timeout: Duration.zero,
    onChanged: (val) {
      state = val == null
          ? state.resetField(TelemetryField.longitude)
          : state.copyWith(longitude: val);
    },
  );
  late final DecayableField<double> _heading = DecayableField<double>(
    timeout: const Duration(seconds: 2),
    onChanged: (val) {
      state = val == null
          ? state.resetField(TelemetryField.heading)
          : state.copyWith(heading: val);
    },
  );
  late final DecayableField<double> _groundSpeed = DecayableField<double>(
    timeout: const Duration(seconds: 2),
    onChanged: (val) {
      state = val == null
          ? state.resetField(TelemetryField.groundSpeed)
          : state.copyWith(groundSpeed: val);
      _updateIsFlying();
    },
  );
  late final DecayableField<double> _indicatedAirSpeed = DecayableField<double>(
    onChanged: (val) {
      state = val == null
          ? state.resetField(TelemetryField.indicatedAirSpeed)
          : state.copyWith(indicatedAirSpeed: val);
      _updateIsFlying();
    },
  );
  late final DecayableField<double> _engineRPM = DecayableField<double>(
    onChanged: (val) {
      state = val == null
          ? state.resetField(TelemetryField.engineRPM)
          : state.copyWith(engineRPM: val);
    },
  );
  late final DecayableField<double> _airPressure = DecayableField<double>(
    onChanged: (val) {
      state = val == null
          ? state.resetField(TelemetryField.airPressure)
          : state.copyWith(airPressure: val);
    },
  );
  late final DecayableField<double> _gpsAltitude = DecayableField<double>(
    timeout: const Duration(seconds: 2),
    onChanged: (val) {
      state = val == null
          ? state.resetField(TelemetryField.gpsAltitude)
          : state.copyWith(gpsAltitude: val);
    },
  );

  late final DecayableField<int> _gpsSatelliteCount = DecayableField<int>(
    timeout: const Duration(seconds: 1),
    onChanged: (val) {
      state = val == null
          ? state.resetField(TelemetryField.gpsSatelliteCount)
          : state.copyWith(gpsSatelliteCount: val);
    },
  );
  late final DecayableField<double> _gpsHorizontalAccuracy =
      DecayableField<double>(
        timeout: const Duration(seconds: 2),
        onChanged: (val) {
          state = val == null
              ? state.resetField(TelemetryField.gpsHorizontalAccuracy)
              : state.copyWith(gpsHorizontalAccuracy: val);
        },
      );
  late final DecayableField<double> _gpsVerticalAccuracy =
      DecayableField<double>(
        timeout: const Duration(seconds: 2),
        onChanged: (val) {
          state = val == null
              ? state.resetField(TelemetryField.gpsVerticalAccuracy)
              : state.copyWith(gpsVerticalAccuracy: val);
        },
      );

  DateTime? _lastDroneCanFixTime;

  @override
  TelemetryState build() {
    ref.onDispose(() {
      _latitude.cancel();
      _longitude.cancel();
      _heading.cancel();
      _groundSpeed.cancel();
      _indicatedAirSpeed.cancel();
      _engineRPM.cancel();
      _airPressure.cancel();
      _gpsAltitude.cancel();
      _gpsSatelliteCount.cancel();
      _gpsHorizontalAccuracy.cancel();
      _gpsVerticalAccuracy.cancel();
    });

    return const TelemetryState();
  }

  void updateGPS({
    double? latitude,
    double? longitude,
    double? heading,
    double? groundSpeed,
    int? gpsSatelliteCount,
    double? gpsHorizontalAccuracy,
    double? gpsVerticalAccuracy,
    double? gpsAltitude,
    bool isDroneCan = false,
  }) {
    if (isDroneCan) {
      _lastDroneCanFixTime = DateTime.now();
    } else if (_lastDroneCanFixTime != null &&
        DateTime.now().difference(_lastDroneCanFixTime!) <=
            const Duration(seconds: 2)) {
      // Discard/ignore phone's GPS data to avoid conflict with active DroneCAN Fix2 data
      return;
    }

    final oldState = state;
    state = state.copyWith(isGpsDroneCan: isDroneCan);

    if (latitude != null) _latitude.update(latitude);
    if (longitude != null) _longitude.update(longitude);
    if (heading != null) _heading.update(heading);
    if (groundSpeed != null) _groundSpeed.update(groundSpeed);

    if (gpsSatelliteCount != null) _gpsSatelliteCount.update(gpsSatelliteCount);

    if (gpsHorizontalAccuracy != null) {
      _gpsHorizontalAccuracy.update(gpsHorizontalAccuracy);
    }
    if (gpsVerticalAccuracy != null) {
      _gpsVerticalAccuracy.update(gpsVerticalAccuracy);
    }

    if (gpsAltitude != null) _gpsAltitude.update(gpsAltitude);

    // Auto-transition to overview if GPS is filled and we are in init/waiting state
    if ((oldState.mapViewState == MapViewState.init ||
            oldState.mapViewState == MapViewState.waitingForGps) &&
        state.latitude != null &&
        state.longitude != null &&
        (state.latitude != 0.0 && state.longitude != 0.0)) {
      state = state.copyWith(mapViewState: MapViewState.overview);
    }
  }

  void updateAirSpeed(double? ias) {
    _indicatedAirSpeed.update(ias);
  }

  void updateEngineRPM(double? rpm) {
    _engineRPM.update(rpm);
  }

  void updatePressure(double? pressure) {
    _airPressure.update(pressure);
  }

  void setMapViewState(MapViewState viewState) {
    state = state.copyWith(mapViewState: viewState);
  }

  void updateAll(TelemetryState newState) {
    state = newState;

    _latitude.sync(newState.latitude);
    _longitude.sync(newState.longitude);
    _heading.sync(newState.heading);
    _groundSpeed.sync(newState.groundSpeed);
    _indicatedAirSpeed.sync(newState.indicatedAirSpeed);
    _engineRPM.sync(newState.engineRPM);
    _airPressure.sync(newState.airPressure);
    _gpsAltitude.sync(newState.gpsAltitude);
    _gpsSatelliteCount.sync(newState.gpsSatelliteCount);
    _gpsHorizontalAccuracy.sync(newState.gpsHorizontalAccuracy);
    _gpsVerticalAccuracy.sync(newState.gpsVerticalAccuracy);

    _updateIsFlying();
  }

  void _updateIsFlying() {
    final settings = ref.read(appSettingsProvider).value;
    final threshold = settings?.flightSpeedThresholds.inactiveMax ?? 2.77;

    final currentSpeedMS = state.indicatedAirSpeed ?? state.groundSpeed;
    final isFlying = currentSpeedMS != null && currentSpeedMS > threshold;

    if (state.isFlying != isFlying) {
      state = state.copyWith(isFlying: isFlying);
    }
  }
}

@riverpod
void gpsListener(Ref ref) {
  // Listen to high-frequency GPS stream
  ref.listen(positionStreamProvider, (previous, next) {
    next.whenData((location) {
      final telemetry = ref.read(telemetryProvider);
      if (telemetry.mapViewState != MapViewState.init) {
        ref.read(telemetryProvider.notifier).updateGPS(
              latitude: location.lat,
              longitude: location.lon,
              groundSpeed: location.groundSpeed,
              gpsSatelliteCount: null,
              gpsHorizontalAccuracy: location.horizontalAccuracy,
              gpsVerticalAccuracy: location.verticalAccuracy,
              gpsAltitude: location.altitude,
            );

        if (telemetry.isFlying) {
          ref.read(telemetryProvider.notifier).updateGPS(heading: location.heading);
        }
      }
    });
  });

  // Listen to device compass for low-speed heading
  ref.listen(compassStreamProvider, (previous, next) {
    next.whenData((heading) {
      if (heading == null) return;
      final telemetry = ref.read(telemetryProvider);
      if (telemetry.mapViewState != MapViewState.init && !telemetry.isFlying) {
        ref.read(telemetryProvider.notifier).updateGPS(heading: heading);
      }
    });
  });
}
