import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/models/telemetry_state.dart';
import '../../domain/models/map_view_state.dart';
import 'package:stork/features/settings/presentation/providers/settings_provider.dart';
import 'package:stork/core/services/location_provider.dart';
import 'decayable_field.dart';

part 'telemetry_provider.g.dart';

// A unique sentinel object used in updateGPS to distinguish between:
// - Omit: Parameter is omitted (defaults to _sentinel), keeping the existing value.
// - Clear: Parameter is explicitly passed as null, resetting the value.
const Object _sentinel = Object();

@Riverpod(keepAlive: true)
class TelemetryNotifier extends _$TelemetryNotifier {
  late final DecayableField<double> _latitude = DecayableField<double>(
    timeout: Duration.zero,
    onChanged: (val) {
      state = val == null
          ? state.resetField(TelemetryField.latitude)
          : state.copyWith(latitude: TelemetryValue(val));
    },
  );
  late final DecayableField<double> _longitude = DecayableField<double>(
    timeout: Duration.zero,
    onChanged: (val) {
      state = val == null
          ? state.resetField(TelemetryField.longitude)
          : state.copyWith(longitude: TelemetryValue(val));
    },
  );
  late final DecayableField<double> _heading = DecayableField<double>(
    timeout: const Duration(seconds: 2),
    onChanged: (val) {
      state = val == null
          ? state.resetField(TelemetryField.heading)
          : state.copyWith(heading: TelemetryValue(val));
    },
  );
  late final DecayableField<double> _groundSpeed = DecayableField<double>(
    timeout: const Duration(seconds: 2),
    onChanged: (val) {
      state = val == null
          ? state.resetField(TelemetryField.groundSpeed)
          : state.copyWith(groundSpeed: TelemetryValue(val));
      _updateIsFlying();
    },
  );
  late final DecayableField<double> _indicatedAirSpeed = DecayableField<double>(
    onChanged: (val) {
      state = val == null
          ? state.resetField(TelemetryField.indicatedAirSpeed)
          : state.copyWith(indicatedAirSpeed: TelemetryValue(val));
      _updateIsFlying();
    },
  );
  late final DecayableField<double> _engineRPM = DecayableField<double>(
    onChanged: (val) {
      state = val == null
          ? state.resetField(TelemetryField.engineRPM)
          : state.copyWith(engineRPM: TelemetryValue(val));
    },
  );
  late final DecayableField<double> _airPressure = DecayableField<double>(
    onChanged: (val) {
      state = val == null
          ? state.resetField(TelemetryField.airPressure)
          : state.copyWith(airPressure: TelemetryValue(val));
    },
  );
  late final DecayableField<double> _gpsAltitude = DecayableField<double>(
    timeout: const Duration(seconds: 2),
    onChanged: (val) {
      state = val == null
          ? state.resetField(TelemetryField.gpsAltitude)
          : state.copyWith(gpsAltitude: TelemetryValue(val));
    },
  );

  late final DecayableField<int> _gpsSatelliteCount = DecayableField<int>(
    timeout: const Duration(seconds: 2),
    onChanged: (val) {
      state = val == null
          ? state.resetField(TelemetryField.gpsSatelliteCount)
          : state.copyWith(gpsSatelliteCount: TelemetryValue(val));
    },
  );
  late final DecayableField<double> _gpsHorizontalAccuracy =
      DecayableField<double>(
        timeout: const Duration(seconds: 2),
        onChanged: (val) {
          state = val == null
              ? state.resetField(TelemetryField.gpsHorizontalAccuracy)
              : state.copyWith(gpsHorizontalAccuracy: TelemetryValue(val));
        },
      );
  late final DecayableField<double> _gpsVerticalAccuracy =
      DecayableField<double>(
        timeout: const Duration(seconds: 2),
        onChanged: (val) {
          state = val == null
              ? state.resetField(TelemetryField.gpsVerticalAccuracy)
              : state.copyWith(gpsVerticalAccuracy: TelemetryValue(val));
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
    Object? latitude = _sentinel,
    Object? longitude = _sentinel,
    Object? heading = _sentinel,
    Object? groundSpeed = _sentinel,
    Object? gpsSatelliteCount = _sentinel,
    Object? gpsHorizontalAccuracy = _sentinel,
    Object? gpsVerticalAccuracy = _sentinel,
    Object? gpsAltitude = _sentinel,
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

    if (latitude != _sentinel) _latitude.sync(latitude as double?);
    if (longitude != _sentinel) _longitude.sync(longitude as double?);
    if (heading != _sentinel) _heading.sync(heading as double?);
    if (groundSpeed != _sentinel) _groundSpeed.sync(groundSpeed as double?);
    if (gpsSatelliteCount != _sentinel) {
      _gpsSatelliteCount.sync(gpsSatelliteCount as int?);
    }
    if (gpsHorizontalAccuracy != _sentinel) {
      _gpsHorizontalAccuracy.sync(gpsHorizontalAccuracy as double?);
    }
    if (gpsVerticalAccuracy != _sentinel) {
      _gpsVerticalAccuracy.sync(gpsVerticalAccuracy as double?);
    }
    if (gpsAltitude != _sentinel) _gpsAltitude.sync(gpsAltitude as double?);

    var newState = state.copyWith(
      isGpsDroneCan: isDroneCan,
      latitude: latitude == _sentinel ? null : TelemetryValue(latitude as double?),
      longitude: longitude == _sentinel ? null : TelemetryValue(longitude as double?),
      heading: heading == _sentinel ? null : TelemetryValue(heading as double?),
      groundSpeed: groundSpeed == _sentinel ? null : TelemetryValue(groundSpeed as double?),
      gpsSatelliteCount: gpsSatelliteCount == _sentinel ? null : TelemetryValue(gpsSatelliteCount as int?),
      gpsHorizontalAccuracy: gpsHorizontalAccuracy == _sentinel ? null : TelemetryValue(gpsHorizontalAccuracy as double?),
      gpsVerticalAccuracy: gpsVerticalAccuracy == _sentinel ? null : TelemetryValue(gpsVerticalAccuracy as double?),
      gpsAltitude: gpsAltitude == _sentinel ? null : TelemetryValue(gpsAltitude as double?),
    );

    // Auto-transition to overview if GPS is filled and we are in init/waiting state
    if ((oldState.mapViewState == MapViewState.init ||
            oldState.mapViewState == MapViewState.waitingForGps) &&
        newState.latitude != null &&
        newState.longitude != null &&
        (newState.latitude != 0.0 && newState.longitude != 0.0)) {
      newState = newState.copyWith(mapViewState: MapViewState.overview);
    }

    state = newState;

    if (groundSpeed != _sentinel && groundSpeed != null) {
      _updateIsFlying();
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
        ref
            .read(telemetryProvider.notifier)
            .updateGPS(
              latitude: location.lat,
              longitude: location.lon,
              groundSpeed: location.groundSpeed,
              gpsHorizontalAccuracy: location.horizontalAccuracy,
              gpsVerticalAccuracy: location.verticalAccuracy,
              gpsAltitude: location.altitude,
            );

        if (telemetry.isFlying) {
          ref
              .read(telemetryProvider.notifier)
              .updateGPS(heading: location.heading);
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
