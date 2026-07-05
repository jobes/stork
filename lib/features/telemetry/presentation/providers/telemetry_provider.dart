import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/models/telemetry_state.dart';
import '../../domain/models/map_view_state.dart';
export '../../domain/models/telemetry_state.dart';
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
  late final DecayableField<int> _engineRPM = DecayableField<int>(
    onChanged: (val) {
      state = val == null
          ? state.resetField(TelemetryField.engineRPM)
          : state.copyWith(
              engineRPM: TelemetryValue(val),
              isEngineRpmSupported: true,
            );
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
  late final DecayableField<double> _coolantTemperature =
      DecayableField<double>(
        onChanged: (val) {
          state = val == null
              ? state.resetField(TelemetryField.coolantTemperature)
              : state.copyWith(coolantTemperature: TelemetryValue(val));
        },
      );
  late final DecayableField<double> _oilPressure = DecayableField<double>(
    onChanged: (val) {
      state = val == null
          ? state.resetField(TelemetryField.oilPressure)
          : state.copyWith(
              oilPressure: TelemetryValue(val),
              isOilPressureSupported: true,
            );
    },
  );
  late final DecayableField<double> _oilTemperature = DecayableField<double>(
    onChanged: (val) {
      state = val == null
          ? state.resetField(TelemetryField.oilTemperature)
          : state.copyWith(
              oilTemperature: TelemetryValue(val),
              isOilTempSupported: true,
            );
    },
  );
  late final DecayableField<List<double?>> _cylinderHeadTemperatures =
      DecayableField<List<double?>>(
        onChanged: (val) {
          state = val == null
              ? state.resetField(TelemetryField.cylinderHeadTemperature)
              : state.copyWith(cylinderHeadTemperatures: TelemetryValue(val));
        },
      );
  late final DecayableField<List<double?>> _exhaustGasTemperatures =
      DecayableField<List<double?>>(
        onChanged: (val) {
          state = val == null
              ? state.resetField(TelemetryField.exhaustGasTemperature)
              : state.copyWith(exhaustGasTemperatures: TelemetryValue(val));
        },
      );
  late final DecayableField<double> _fuelLevelPercent = DecayableField<double>(
    onChanged: (val) {
      state = val == null
          ? state.resetField(TelemetryField.fuelLevelPercent)
          : state.copyWith(
              fuelLevelPercent: TelemetryValue(val),
              isFuelSupported: true,
            );
    },
  );
  late final DecayableField<double> _fuelVolumeLiters = DecayableField<double>(
    onChanged: (val) {
      state = val == null
          ? state.resetField(TelemetryField.fuelVolumeLiters)
          : state.copyWith(
              fuelVolumeLiters: TelemetryValue(val),
              isFuelSupported: true,
            );
    },
  );

  // Radio fields
  late final DecayableField<int> _radioActiveFrequency = DecayableField<int>(
    timeout: const Duration(seconds: 30),
    onChanged: (val) {
      state = val == null
          ? state.resetField(TelemetryField.radioActiveFrequency)
          : state.copyWith(radioActiveFrequency: TelemetryValue(val));
    },
  );
  late final DecayableField<int> _radioStandbyFrequency = DecayableField<int>(
    timeout: const Duration(seconds: 30),
    onChanged: (val) {
      state = val == null
          ? state.resetField(TelemetryField.radioStandbyFrequency)
          : state.copyWith(radioStandbyFrequency: TelemetryValue(val));
    },
  );
  late final DecayableField<String> _radioActiveStationName =
      DecayableField<String>(
        timeout: const Duration(seconds: 30),
        onChanged: (val) {
          state = val == null
              ? state.resetField(TelemetryField.radioActiveStationName)
              : state.copyWith(radioActiveStationName: TelemetryValue(val));
        },
      );
  late final DecayableField<String> _radioStandbyStationName =
      DecayableField<String>(
        timeout: const Duration(seconds: 30),
        onChanged: (val) {
          state = val == null
              ? state.resetField(TelemetryField.radioStandbyStationName)
              : state.copyWith(radioStandbyStationName: TelemetryValue(val));
        },
      );
  late final DecayableField<int> _radioFlags = DecayableField<int>(
    timeout: const Duration(seconds: 30),
    onChanged: (val) {
      state = val == null
          ? state.resetField(TelemetryField.radioFlags)
          : state.copyWith(radioFlags: TelemetryValue(val));
    },
  );
  late final DecayableField<int> _radioInstance = DecayableField<int>(
    timeout: const Duration(seconds: 30),
    onChanged: (val) {
      state = val == null
          ? state.resetField(TelemetryField.radioInstance)
          : state.copyWith(radioInstance: TelemetryValue(val));
    },
  );
  late final DecayableField<int> _radioNodeId = DecayableField<int>(
    timeout: const Duration(seconds: 30),
    onChanged: (val) {
      state = val == null
          ? state.resetField(TelemetryField.radioNodeId)
          : state.copyWith(radioNodeId: TelemetryValue(val));
    },
  );
  late final DecayableField<int> _radioVolume = DecayableField<int>(
    timeout: const Duration(seconds: 30),
    onChanged: (val) {
      state = val == null
          ? state.resetField(TelemetryField.radioVolume)
          : state.copyWith(radioVolume: TelemetryValue(val));
    },
  );
  late final DecayableField<int> _radioSquelch = DecayableField<int>(
    timeout: const Duration(seconds: 30),
    onChanged: (val) {
      state = val == null
          ? state.resetField(TelemetryField.radioSquelch)
          : state.copyWith(radioSquelch: TelemetryValue(val));
    },
  );
  late final DecayableField<int> _radioVox = DecayableField<int>(
    timeout: const Duration(seconds: 30),
    onChanged: (val) {
      state = val == null
          ? state.resetField(TelemetryField.radioVox)
          : state.copyWith(radioVox: TelemetryValue(val));
    },
  );
  late final DecayableField<int> _radioIntercom = DecayableField<int>(
    timeout: const Duration(seconds: 30),
    onChanged: (val) {
      state = val == null
          ? state.resetField(TelemetryField.radioIntercom)
          : state.copyWith(radioIntercom: TelemetryValue(val));
    },
  );
  late final DecayableField<List<int>> _radioMicGain =
      DecayableField<List<int>>(
        timeout: const Duration(seconds: 30),
        onChanged: (val) {
          state = val == null
              ? state.resetField(TelemetryField.radioMicGain)
              : state.copyWith(radioMicGain: TelemetryValue(val));
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
      _coolantTemperature.cancel();
      _oilPressure.cancel();
      _oilTemperature.cancel();
      _cylinderHeadTemperatures.cancel();
      _exhaustGasTemperatures.cancel();
      _fuelLevelPercent.cancel();
      _fuelVolumeLiters.cancel();

      // Cancel radio timers
      _radioActiveFrequency.cancel();
      _radioStandbyFrequency.cancel();
      _radioActiveStationName.cancel();
      _radioStandbyStationName.cancel();
      _radioFlags.cancel();
      _radioInstance.cancel();
      _radioNodeId.cancel();
      _radioVolume.cancel();
      _radioSquelch.cancel();
      _radioVox.cancel();
      _radioIntercom.cancel();
      _radioMicGain.cancel();
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
      latitude: latitude == _sentinel
          ? null
          : TelemetryValue(latitude as double?),
      longitude: longitude == _sentinel
          ? null
          : TelemetryValue(longitude as double?),
      heading: heading == _sentinel ? null : TelemetryValue(heading as double?),
      groundSpeed: groundSpeed == _sentinel
          ? null
          : TelemetryValue(groundSpeed as double?),
      gpsSatelliteCount: gpsSatelliteCount == _sentinel
          ? null
          : TelemetryValue(gpsSatelliteCount as int?),
      gpsHorizontalAccuracy: gpsHorizontalAccuracy == _sentinel
          ? null
          : TelemetryValue(gpsHorizontalAccuracy as double?),
      gpsVerticalAccuracy: gpsVerticalAccuracy == _sentinel
          ? null
          : TelemetryValue(gpsVerticalAccuracy as double?),
      gpsAltitude: gpsAltitude == _sentinel
          ? null
          : TelemetryValue(gpsAltitude as double?),
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

  void updateEngineRPM(int? rpm) {
    _engineRPM.update(rpm);
  }

  void updateIceStatus({
    required int engineSpeedRpm,
    double? coolantTemperature,
    double? oilPressure,
    double? oilTemperature,
    List<double?> cylinderHeadTemperatures = const [],
    List<double?> exhaustGasTemperatures = const [],
  }) {
    _engineRPM.sync(engineSpeedRpm);
    _coolantTemperature.sync(coolantTemperature);
    _oilPressure.sync(oilPressure);
    _oilTemperature.sync(oilTemperature);
    _cylinderHeadTemperatures.sync(cylinderHeadTemperatures);
    _exhaustGasTemperatures.sync(exhaustGasTemperatures);

    state = state.copyWith(
      engineRPM: TelemetryValue(engineSpeedRpm),
      coolantTemperature: TelemetryValue(coolantTemperature),
      oilPressure: TelemetryValue(oilPressure),
      oilTemperature: TelemetryValue(oilTemperature),
      isOilTempSupported: state.isOilTempSupported || oilTemperature != null,
      isOilPressureSupported:
          state.isOilPressureSupported || oilPressure != null,
      isEngineRpmSupported: true,
      cylinderHeadTemperatures: TelemetryValue(cylinderHeadTemperatures),
      exhaustGasTemperatures: TelemetryValue(exhaustGasTemperatures),
    );
  }

  void updateFuelStatus({required double percent, double? volumeLiters}) {
    _fuelLevelPercent.sync(percent);
    _fuelVolumeLiters.sync(volumeLiters);
    state = state.copyWith(
      fuelLevelPercent: TelemetryValue(percent),
      fuelVolumeLiters: TelemetryValue(volumeLiters),
      isFuelSupported: true,
    );
  }

  void updatePressure(double? pressure) {
    _airPressure.update(pressure);
  }

  void updateVhfRadioFull({
    required int radioInstance,
    required int activeFrequencyKhz,
    required int standbyFrequencyKhz,
    required int flags,
    required String activeStationName,
    required String standbyStationName,
    required int nodeId,
    required int volume,
    required int squelch,
    required int vox,
    required int intercom,
    required List<int> micGain,
  }) {
    _radioActiveFrequency.sync(activeFrequencyKhz);
    _radioStandbyFrequency.sync(standbyFrequencyKhz);
    _radioActiveStationName.sync(activeStationName);
    _radioStandbyStationName.sync(standbyStationName);
    _radioFlags.sync(flags);
    _radioInstance.sync(radioInstance);
    _radioNodeId.sync(nodeId);
    _radioVolume.sync(volume);
    _radioSquelch.sync(squelch);
    _radioVox.sync(vox);
    _radioIntercom.sync(intercom);
    _radioMicGain.sync(micGain);

    state = state.copyWith(
      radioActiveFrequency: TelemetryValue(activeFrequencyKhz),
      radioStandbyFrequency: TelemetryValue(standbyFrequencyKhz),
      radioActiveStationName: TelemetryValue(activeStationName),
      radioStandbyStationName: TelemetryValue(standbyStationName),
      radioFlags: TelemetryValue(flags),
      radioInstance: TelemetryValue(radioInstance),
      radioNodeId: TelemetryValue(nodeId),
      radioVolume: TelemetryValue(volume),
      radioSquelch: TelemetryValue(squelch),
      radioVox: TelemetryValue(vox),
      radioIntercom: TelemetryValue(intercom),
      radioMicGain: TelemetryValue(micGain),
      isRadioSupported: true,
    );
  }

  void updateVhfRadioFast({
    required int radioInstance,
    required int flags,
    required int nodeId,
  }) {
    _radioFlags.sync(flags);
    _radioInstance.sync(radioInstance);
    _radioNodeId.sync(nodeId);

    state = state.copyWith(
      radioFlags: TelemetryValue(flags),
      radioInstance: TelemetryValue(radioInstance),
      radioNodeId: TelemetryValue(nodeId),
      isRadioSupported: true,
    );
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
    _coolantTemperature.sync(newState.coolantTemperature);
    _oilPressure.sync(newState.oilPressure);
    _oilTemperature.sync(newState.oilTemperature);
    _cylinderHeadTemperatures.sync(newState.cylinderHeadTemperatures);
    _exhaustGasTemperatures.sync(newState.exhaustGasTemperatures);
    _fuelLevelPercent.sync(newState.fuelLevelPercent);
    _fuelVolumeLiters.sync(newState.fuelVolumeLiters);

    // Sync radio fields
    _radioActiveFrequency.sync(newState.radioActiveFrequency);
    _radioStandbyFrequency.sync(newState.radioStandbyFrequency);
    _radioActiveStationName.sync(newState.radioActiveStationName);
    _radioStandbyStationName.sync(newState.radioStandbyStationName);
    _radioFlags.sync(newState.radioFlags);
    _radioInstance.sync(newState.radioInstance);
    _radioNodeId.sync(newState.radioNodeId);
    _radioVolume.sync(newState.radioVolume);
    _radioSquelch.sync(newState.radioSquelch);
    _radioVox.sync(newState.radioVox);
    _radioIntercom.sync(newState.radioIntercom);
    _radioMicGain.sync(newState.radioMicGain);

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

@Riverpod(keepAlive: true)
class DisableTelemetryAnimations extends _$DisableTelemetryAnimations {
  final Map<TelemetryField, DateTime> _lastUpdateTimes = {};
  final Map<TelemetryField, bool> _disableAnimations = {};

  @override
  Map<TelemetryField, bool> build() {
    ref.listen<TelemetryState>(telemetryProvider, (previous, next) {
      final now = DateTime.now();
      bool stateChanged = false;

      for (final field in TelemetryField.values) {
        bool changed = false;
        if (field == TelemetryField.cylinderHeadTemperature) {
          changed = !_areListsEqual(
            previous?.cylinderHeadTemperatures,
            next.cylinderHeadTemperatures,
          );
        } else if (field == TelemetryField.exhaustGasTemperature) {
          changed = !_areListsEqual(
            previous?.exhaustGasTemperatures,
            next.exhaustGasTemperatures,
          );
        } else {
          final prevVal = previous?.getFieldValue(field);
          final nextVal = next.getFieldValue(field);
          changed = prevVal != nextVal;
        }

        if (changed) {
          final lastUpdate = _lastUpdateTimes[field];
          _lastUpdateTimes[field] = now;
          if (lastUpdate != null) {
            final diff = now.difference(lastUpdate);
            // More than 4x per second means interval < 250 milliseconds
            final highFreq = diff.inMilliseconds < 250;
            if (_disableAnimations[field] != highFreq) {
              _disableAnimations[field] = highFreq;
              stateChanged = true;
            }
          }
        }
      }

      if (stateChanged) {
        state = Map.from(_disableAnimations);
      }
    });

    return const {};
  }

  bool _areListsEqual(List<double?>? a, List<double?>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
