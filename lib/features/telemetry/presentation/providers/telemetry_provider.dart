import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/models/telemetry_state.dart';
import '../../domain/models/map_view_state.dart';
import 'package:stork/features/settings/presentation/providers/settings_provider.dart';
import 'package:stork/features/settings/domain/speed_unit.dart';
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
  late final DecayableField<double> _speed = DecayableField<double>(
    timeout: const Duration(seconds: 2),
    onChanged: (val) {
      state = val == null
          ? state.resetField(TelemetryField.speed)
          : state.copyWith(speed: val);
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
  late final DecayableField<double> _altitude = DecayableField<double>(
    timeout: const Duration(seconds: 2),
    onChanged: (val) {
      state = val == null
          ? state.resetField(TelemetryField.altitude)
          : state.copyWith(altitude: val);
    },
  );
  late final DecayableField<double> _heightAboveGround = DecayableField<double>(
    timeout: const Duration(seconds: 2),
    onChanged: (val) {
      state = val == null
          ? state.resetField(TelemetryField.heightAboveGround)
          : state.copyWith(heightAboveGround: val);
    },
  );

  @override
  TelemetryState build() {
    ref.onDispose(() {
      _latitude.cancel();
      _longitude.cancel();
      _heading.cancel();
      _speed.cancel();
      _indicatedAirSpeed.cancel();
      _engineRPM.cancel();
      _airPressure.cancel();
      _altitude.cancel();
      _heightAboveGround.cancel();
    });
    return const TelemetryState();
  }

  void updateGPS({
    double? latitude,
    double? longitude,
    double? heading,
    double? speed,
  }) {
    final oldState = state;

    if (latitude != null) _latitude.update(latitude);
    if (longitude != null) _longitude.update(longitude);
    if (heading != null) _heading.update(heading);
    if (speed != null) _speed.update(speed);

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

  void updateAltitude({double? altitude, double? heightAboveGround}) {
    if (altitude != null) _altitude.update(altitude);
    if (heightAboveGround != null) _heightAboveGround.update(heightAboveGround);
  }

  void setMapViewState(MapViewState viewState) {
    state = state.copyWith(mapViewState: viewState);
  }

  void updateAll(TelemetryState newState) {
    state = newState;

    _latitude.sync(newState.latitude);
    _longitude.sync(newState.longitude);
    _heading.sync(newState.heading);
    _speed.sync(newState.speed);
    _indicatedAirSpeed.sync(newState.indicatedAirSpeed);
    _engineRPM.sync(newState.engineRPM);
    _airPressure.sync(newState.airPressure);
    _altitude.sync(newState.altitude);
    _heightAboveGround.sync(newState.heightAboveGround);

    _updateIsFlying();
  }

  void _updateIsFlying() {
    final settings = ref.read(appSettingsProvider).value;
    final threshold = settings?.flightSpeedThresholds.inactiveMax ?? 2.77;

    final currentSpeedMS = state.indicatedAirSpeed ?? state.speed;
    final isFlying = currentSpeedMS != null && currentSpeedMS > threshold;

    if (state.isFlying != isFlying) {
      state = state.copyWith(isFlying: isFlying);
    }
  }
}
