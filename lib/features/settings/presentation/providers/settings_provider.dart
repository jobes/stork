import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/services/mdns_service.dart';
import '../../data/repositories/settings_repository.dart';
import '../../domain/models/app_settings.dart';
import '../../domain/models/cannelloni_device.dart';
import '../../domain/models/range_thresholds.dart';
import '../../domain/models/speed_unit.dart';
import '../../domain/models/altitude_unit.dart';
import '../../domain/models/widget_position.dart';
import '../../domain/models/temperature_unit.dart';
import '../../domain/models/pressure_unit.dart';

part 'settings_provider.g.dart';

/// Sealed class representing the result of a settings update.
sealed class SettingsUpdateResult {
  const SettingsUpdateResult();
}

/// Represents a successful settings update.
class SettingsUpdateSuccess extends SettingsUpdateResult {
  const SettingsUpdateSuccess();
}

/// Represents a failed settings update.
class SettingsUpdateFailure extends SettingsUpdateResult {
  final Object error;
  final StackTrace stackTrace;

  const SettingsUpdateFailure(this.error, this.stackTrace);
}

@riverpod
class AppSettingsNotifier extends _$AppSettingsNotifier {
  static const double _defaultMaxRangeMs = 38.89;
  static const double _defaultInactiveMaxMs = 2.77;
  static const double _defaultMinErrorMs = 16.67;
  static const double _defaultMinWarningMs = 20.83;
  static const double _defaultMaxWarningMs = 30.56;
  static const double _defaultMaxErrorMs = 34.72;
  static const double _minRangeLimit = 10.0;
  static const double _maxRangeLimit = 1000.0;

  static const double _defaultRpmMaxRange = 6000.0;
  static const double _defaultRpmInactiveMax = 10.0;
  static const double _defaultRpmMinError = 1400.0;
  static const double _defaultRpmMinWarning = 1800.0;
  static const double _defaultRpmMaxWarning = 5500.0;
  static const double _defaultRpmMaxError = 5800.0;
  static const double _minRpmLimit = 100.0;
  static const double _maxRpmLimit = 10000.0;

  Future<void> _persistenceQueue = Future.value();

  @override
  FutureOr<AppSettings> build() async {
    final repository = await ref.watch(settingsRepositoryProvider.future);
    final settings = await repository.getSettings();

    // Listen to discovered devices for auto-selection
    ref.listen(discoveredDevicesProvider, (previous, next) {
      final devices = next.asData?.value ?? [];
      final currentSettings = state.asData?.value;

      if (currentSettings != null && currentSettings.autoSelectDevice) {
        // [_tryAutoSelectDevice] returns a Future, which is run in the background here.
        unawaited(_tryAutoSelectDevice(devices, currentSettings));
      }
    });

    return settings;
  }

  /// Tries to automatically select an available device.
  ///
  /// References [updateSelectedDevice] which internally invokes [_updateSettings].
  Future<SettingsUpdateResult?> _tryAutoSelectDevice(
    List<CannelloniDevice> devices,
    AppSettings currentSettings,
  ) async {
    if (devices.isEmpty) return null;

    final currentDevice = currentSettings.selectedDevice;
    final isCurrentStillAvailable =
        currentDevice != null && devices.contains(currentDevice);

    if (!isCurrentStillAvailable) {
      // Only switch to the first device if the current one is gone or if none was selected
      return await updateSelectedDevice(devices.first);
    }
    return null;
  }

  Future<SettingsUpdateResult> _updateSettings(
    AppSettings Function(AppSettings) updater,
  ) async {
    final currentState = state.hasValue ? state.value : state.asData?.value;
    if (currentState == null) {
      return SettingsUpdateFailure(
        StateError('Cannot update settings when state is not loaded.'),
        StackTrace.current,
      );
    }

    final newSettings = updater(currentState);
    state = AsyncData(newSettings);

    final completer = Completer<void>();
    final previous = _persistenceQueue;
    _persistenceQueue = completer.future;

    try {
      try {
        await previous;
      } catch (_) {
        // Safe fallback: ignore failures in previous writes to avoid cascading deadlocks/failures
      }

      if (!ref.mounted) {
        return SettingsUpdateFailure(
          StateError('Provider was disposed before settings could be saved.'),
          StackTrace.current,
        );
      }

      final repository = await ref.read(settingsRepositoryProvider.future);
      await repository.saveSettings(newSettings);

      // Transition the state back to a successful AsyncData if no newer update has modified it
      if (ref.mounted && state.hasValue && state.value == newSettings) {
        state = AsyncData(newSettings);
      }

      return const SettingsUpdateSuccess();
    } catch (e, stackTrace) {
      if (!ref.mounted) {
        return SettingsUpdateFailure(e, stackTrace);
      }

      final repository = await ref.read(settingsRepositoryProvider.future);
      final repoSettings = await repository.getSettings();

      if (state.asData?.value == newSettings) {
        state = AsyncData(repoSettings);
        state = AsyncError<AppSettings>(e, stackTrace);
      } else {
        final currentLatest = state.asData?.value ?? repoSettings;
        state = AsyncData(currentLatest);
        state = AsyncError<AppSettings>(e, stackTrace);
      }

      return SettingsUpdateFailure(e, stackTrace);
    } finally {
      completer.complete();
    }
  }

  Future<SettingsUpdateResult> updateFontSize(double fontSize) =>
      _updateSettings((s) => s.copyWith(mapFontSize: fontSize));

  Future<SettingsUpdateResult> updateDefaultZoom(double zoom) =>
      _updateSettings((s) => s.copyWith(mapDefaultZoom: zoom));

  Future<SettingsUpdateResult> updateOverviewZoom(double zoom) =>
      _updateSettings((s) => s.copyWith(mapOverviewZoom: zoom));

  Future<SettingsUpdateResult> updateCourseLineSegmentsCount(int count) {
    if (count <= 0) {
      return Future.value(
        SettingsUpdateFailure(
          ArgumentError('Count must be positive'),
          StackTrace.current,
        ),
      );
    }
    return _updateSettings((s) => s.copyWith(courseLineSegmentsCount: count));
  }

  Future<SettingsUpdateResult> updateCourseLineSegmentDuration(int duration) {
    if (duration <= 0) {
      return Future.value(
        SettingsUpdateFailure(
          ArgumentError('Duration must be positive'),
          StackTrace.current,
        ),
      );
    }
    return _updateSettings(
      (s) => s.copyWith(courseLineSegmentDuration: duration),
    );
  }

  Future<SettingsUpdateResult> updateFollowZoom(double zoom) =>
      _updateSettings((s) => s.copyWith(mapFollowZoom: zoom));

  Future<SettingsUpdateResult> updateSpeedUnit(SpeedUnit newUnit) {
    return _updateSettings((s) => s.copyWith(speedUnit: newUnit));
  }

  Future<SettingsUpdateResult> updateFlightSpeedThresholds(
    RangeThresholds thresholds,
  ) {
    return _updateSettings((s) {
      final speedUnit = s.speedUnit;
      final thresholdsInMs = RangeThresholds(
        inactiveMax: thresholds.inactiveMax != null
            ? speedUnit.convertToMs(thresholds.inactiveMax!)
            : null,
        minError: thresholds.minError != null
            ? speedUnit.convertToMs(thresholds.minError!)
            : null,
        minWarning: thresholds.minWarning != null
            ? speedUnit.convertToMs(thresholds.minWarning!)
            : null,
        maxWarning: thresholds.maxWarning != null
            ? speedUnit.convertToMs(thresholds.maxWarning!)
            : null,
        maxError: thresholds.maxError != null
            ? speedUnit.convertToMs(thresholds.maxError!)
            : null,
      );
      return s.copyWith(flightSpeedThresholds: thresholdsInMs);
    });
  }

  Future<SettingsUpdateResult> updateFlightSpeedMaxRange(double maxRange) {
    return _updateSettings(
      (s) => s.copyWithValidatedFlightSpeedMaxRange(
        maxRange,
        defaultMaxRangeMs: _defaultMaxRangeMs,
        defaultInactiveMaxMs: _defaultInactiveMaxMs,
        defaultMinErrorMs: _defaultMinErrorMs,
        defaultMinWarningMs: _defaultMinWarningMs,
        defaultMaxWarningMs: _defaultMaxWarningMs,
        defaultMaxErrorMs: _defaultMaxErrorMs,
        minRangeLimit: _minRangeLimit,
        maxRangeLimit: _maxRangeLimit,
      ),
    );
  }

  Future<SettingsUpdateResult> updateRpmThresholds(RangeThresholds thresholds) {
    return _updateSettings((s) {
      return s.copyWith(rpmThresholds: thresholds);
    });
  }

  Future<SettingsUpdateResult> updateRpmMaxRange(double maxRange) {
    return _updateSettings(
      (s) => s.copyWithValidatedRpmMaxRange(
        maxRange,
        defaultMaxRange: _defaultRpmMaxRange,
        defaultInactiveMax: _defaultRpmInactiveMax,
        defaultMinError: _defaultRpmMinError,
        defaultMinWarning: _defaultRpmMinWarning,
        defaultMaxWarning: _defaultRpmMaxWarning,
        defaultMaxError: _defaultRpmMaxError,
        minRangeLimit: _minRpmLimit,
        maxRangeLimit: _maxRpmLimit,
      ),
    );
  }

  /// Updates the auto-select device setting and, if enabled, performs auto-selection immediately.
  ///
  /// Invokes [_updateSettings] to update the setting, then awaits [_tryAutoSelectDevice] which
  /// may in turn invoke [updateSelectedDevice] (which also uses [_updateSettings]).
  /// If the auto-selection step fails, that failure is surfaced as the result.
  Future<SettingsUpdateResult> updateAutoSelectDevice(bool autoSelect) async {
    final result = await _updateSettings(
      (s) => s.copyWith(autoSelectDevice: autoSelect),
    );

    if (result is SettingsUpdateFailure) {
      return result;
    }

    // If turned on, try to auto-select immediately
    if (autoSelect) {
      final devices = ref.read(discoveredDevicesProvider).asData?.value ?? [];
      final currentSettings = state.hasValue
          ? state.value
          : state.asData?.value;
      if (currentSettings != null) {
        final autoSelectResult = await _tryAutoSelectDevice(
          devices,
          currentSettings,
        );
        if (autoSelectResult is SettingsUpdateFailure) {
          return autoSelectResult;
        }
      }
    }
    return result;
  }

  Future<SettingsUpdateResult> updateAreWidgetsDraggable(bool areDraggable) =>
      _updateSettings((s) => s.copyWith(areWidgetsDraggable: areDraggable));

  Future<SettingsUpdateResult> updateWidgetPosition(
    String widgetId,
    double top,
    double left,
  ) {
    return _updateSettings((s) {
      final newPositions = Map<String, WidgetPosition>.from(s.widgetPositions);
      newPositions[widgetId] = WidgetPosition(top: top, left: left);
      return s.copyWith(widgetPositions: newPositions);
    });
  }

  Future<SettingsUpdateResult> resetWidgetPositions() =>
      _updateSettings((s) => s.copyWith(widgetPositions: {}));

  Future<SettingsUpdateResult> updateSelectedDevice(CannelloniDevice? device) =>
      _updateSettings((s) => s.copyWith(selectedDevice: device));

  Future<SettingsUpdateResult> updateQnh(double qnh) {
    return _updateSettings((s) => s.copyWithValidatedQnh(qnh));
  }

  Future<SettingsUpdateResult> updateQfe(double qfe) =>
      _updateSettings((s) => s.copyWith(qfe: qfe));

  Future<SettingsUpdateResult> updateAutoQnh(bool autoQnh) =>
      _updateSettings((s) => s.copyWith(autoQnh: autoQnh));

  Future<SettingsUpdateResult> updateAltitudeUnit(AltitudeUnit altitudeUnit) =>
      _updateSettings((s) => s.copyWith(altitudeUnit: altitudeUnit));

  Future<SettingsUpdateResult> updateHeightUnit(AltitudeUnit heightUnit) =>
      _updateSettings((s) => s.copyWith(heightUnit: heightUnit));
  Future<SettingsUpdateResult> updateAverageSpeed(double averageSpeed) {
    return _updateSettings(
      (s) => s.copyWithValidatedAverageSpeed(averageSpeed),
    );
  }

  Future<SettingsUpdateResult> updatePilotId(String? pilotId) {
    return _updateSettings((s) => s.copyWith(pilotId: pilotId));
  }

  Future<SettingsUpdateResult> updateAirplaneId(String? airplaneId) {
    return _updateSettings((s) => s.copyWith(airplaneId: airplaneId));
  }

  Future<SettingsUpdateResult> updateTemperatureUnit(
    TemperatureUnit temperatureUnit,
  ) => _updateSettings((s) => s.copyWith(temperatureUnit: temperatureUnit));

  Future<SettingsUpdateResult> updateOilTempThresholds(
    RangeThresholds thresholds,
  ) {
    return _updateSettings((s) {
      final tempUnit = s.temperatureUnit;
      final thresholdsInKelvin = RangeThresholds(
        inactiveMax: thresholds.inactiveMax != null
            ? tempUnit.convertToKelvin(thresholds.inactiveMax!)
            : null,
        minError: thresholds.minError != null
            ? tempUnit.convertToKelvin(thresholds.minError!)
            : null,
        minWarning: thresholds.minWarning != null
            ? tempUnit.convertToKelvin(thresholds.minWarning!)
            : null,
        maxWarning: thresholds.maxWarning != null
            ? tempUnit.convertToKelvin(thresholds.maxWarning!)
            : null,
        maxError: thresholds.maxError != null
            ? tempUnit.convertToKelvin(thresholds.maxError!)
            : null,
      );
      return s.copyWith(oilTempThresholds: thresholdsInKelvin);
    });
  }

  Future<SettingsUpdateResult> updateOilTempMaxRange(double maxRange) {
    return _updateSettings(
      (s) => s.copyWithValidatedOilTempMaxRange(
        maxRange,
        defaultMaxRangeK: 413.15,
        defaultInactiveMaxK: 303.15,
        defaultMinErrorK: 323.15,
        defaultMinWarningK: 333.15,
        defaultMaxWarningK: 383.15,
        defaultMaxErrorK: 403.15,
        minRangeLimit: s.temperatureUnit.convertFromKelvin(50.0),
        maxRangeLimit: s.temperatureUnit.convertFromKelvin(1000.0),
      ),
    );
  }

  Future<SettingsUpdateResult> updatePressureUnit(PressureUnit pressureUnit) =>
      _updateSettings((s) => s.copyWith(pressureUnit: pressureUnit));

  Future<SettingsUpdateResult> updateOilPressureThresholds(
    RangeThresholds thresholds,
  ) {
    return _updateSettings((s) {
      final pressureUnit = s.pressureUnit;
      final thresholdsInKpa = RangeThresholds(
        inactiveMax: thresholds.inactiveMax != null
            ? pressureUnit.convertToKpa(thresholds.inactiveMax!)
            : null,
        minError: thresholds.minError != null
            ? pressureUnit.convertToKpa(thresholds.minError!)
            : null,
        minWarning: thresholds.minWarning != null
            ? pressureUnit.convertToKpa(thresholds.minWarning!)
            : null,
        maxWarning: thresholds.maxWarning != null
            ? pressureUnit.convertToKpa(thresholds.maxWarning!)
            : null,
        maxError: thresholds.maxError != null
            ? pressureUnit.convertToKpa(thresholds.maxError!)
            : null,
      );
      return s.copyWith(oilPressureThresholds: thresholdsInKpa);
    });
  }

  Future<SettingsUpdateResult> updateOilPressureMaxRange(double maxRange) {
    return _updateSettings(
      (s) => s.copyWithValidatedOilPressureMaxRange(
        maxRange,
        defaultMaxRangeKpa: 800.0,
        defaultInactiveMaxKpa: 50.0,
        defaultMinErrorKpa: 80.0,
        defaultMinWarningKpa: 200.0,
        defaultMaxWarningKpa: 500.0,
        defaultMaxErrorKpa: 700.0,
        minRangeLimit: s.pressureUnit.convertFromKpa(
          100.0,
        ), // 1.0 bar / 14.5 psi / 100 kPa
        maxRangeLimit: s.pressureUnit.convertFromKpa(
          2000.0,
        ), // 20.0 bar / 290 psi / 2000 kPa
      ),
    );
  }

  Future<SettingsUpdateResult> updateFuelThresholds(
    RangeThresholds thresholds,
  ) {
    return _updateSettings((s) {
      return s.copyWith(fuelThresholds: thresholds);
    });
  }

  Future<SettingsUpdateResult> updateEgtThresholds(RangeThresholds thresholds) {
    return _updateSettings((s) {
      final tempUnit = s.temperatureUnit;
      final thresholdsInKelvin = RangeThresholds(
        inactiveMax: thresholds.inactiveMax != null
            ? tempUnit.convertToKelvin(thresholds.inactiveMax!)
            : null,
        minError: thresholds.minError != null
            ? tempUnit.convertToKelvin(thresholds.minError!)
            : null,
        minWarning: thresholds.minWarning != null
            ? tempUnit.convertToKelvin(thresholds.minWarning!)
            : null,
        maxWarning: thresholds.maxWarning != null
            ? tempUnit.convertToKelvin(thresholds.maxWarning!)
            : null,
        maxError: thresholds.maxError != null
            ? tempUnit.convertToKelvin(thresholds.maxError!)
            : null,
      );
      return s.copyWith(egtThresholds: thresholdsInKelvin);
    });
  }

  Future<SettingsUpdateResult> updateEgtMaxRange(double maxRange) {
    return _updateSettings(
      (s) => s.copyWithValidatedEgtMaxRange(
        maxRange,
        defaultMaxRangeK: 1223.15,
        defaultInactiveMaxK: 423.15,
        defaultMinErrorK: 773.15,
        defaultMinWarningK: 973.15,
        defaultMaxWarningK: 1153.15,
        defaultMaxErrorK: 1173.15,
        minRangeLimit: s.temperatureUnit.convertFromKelvin(50.0),
        maxRangeLimit: s.temperatureUnit.convertFromKelvin(2000.0),
      ),
    );
  }

  Future<SettingsUpdateResult> updateChtThresholds(RangeThresholds thresholds) {
    return _updateSettings((s) {
      final tempUnit = s.temperatureUnit;
      final thresholdsInKelvin = RangeThresholds(
        inactiveMax: thresholds.inactiveMax != null
            ? tempUnit.convertToKelvin(thresholds.inactiveMax!)
            : null,
        minError: thresholds.minError != null
            ? tempUnit.convertToKelvin(thresholds.minError!)
            : null,
        minWarning: thresholds.minWarning != null
            ? tempUnit.convertToKelvin(thresholds.minWarning!)
            : null,
        maxWarning: thresholds.maxWarning != null
            ? tempUnit.convertToKelvin(thresholds.maxWarning!)
            : null,
        maxError: thresholds.maxError != null
            ? tempUnit.convertToKelvin(thresholds.maxError!)
            : null,
      );
      return s.copyWith(chtThresholds: thresholdsInKelvin);
    });
  }

  Future<SettingsUpdateResult> updateChtMaxRange(double maxRange) {
    return _updateSettings(
      (s) => s.copyWithValidatedChtMaxRange(
        maxRange,
        defaultMaxRangeK: 433.15,
        defaultInactiveMaxK: 323.15,
        defaultMinErrorK: 333.15,
        defaultMinWarningK: 348.15,
        defaultMaxWarningK: 403.15,
        defaultMaxErrorK: 423.15,
        minRangeLimit: s.temperatureUnit.convertFromKelvin(50.0),
        maxRangeLimit: s.temperatureUnit.convertFromKelvin(1000.0),
      ),
    );
  }

  Future<SettingsUpdateResult> updateTrafficFilterMaxHorizontalDistanceEnabled(
    bool enabled,
  ) {
    return _updateSettings(
      (s) => s.copyWith(trafficFilterMaxHorizontalDistanceEnabled: enabled),
    );
  }

  Future<SettingsUpdateResult> updateTrafficMaxHorizontalDistance(
    double distanceMeters,
  ) {
    return _updateSettings(
      (s) => s.copyWith(
        trafficMaxHorizontalDistance: distanceMeters
            .clamp(1000.0, 500000.0)
            .toDouble(),
      ),
    );
  }

  Future<SettingsUpdateResult> updateTrafficFilterMaxVerticalDistanceEnabled(
    bool enabled,
  ) {
    return _updateSettings(
      (s) => s.copyWith(trafficFilterMaxVerticalDistanceEnabled: enabled),
    );
  }

  Future<SettingsUpdateResult> updateTrafficMaxVerticalDistance(
    double distanceMeters,
  ) {
    return _updateSettings(
      (s) => s.copyWith(
        trafficMaxVerticalDistance: distanceMeters
            .clamp(100.0, 20000.0)
            .toDouble(),
      ),
    );
  }

  Future<SettingsUpdateResult> updateCasEnabled(bool enabled) {
    return _updateSettings((s) => s.copyWith(casEnabled: enabled));
  }

  Future<SettingsUpdateResult> updateCasLookaheadTime(double seconds) {
    return _updateSettings(
      (s) =>
          s.copyWith(casLookaheadTime: seconds.clamp(10.0, 120.0).toDouble()),
    );
  }

  Future<SettingsUpdateResult> updateCasHorizontalThreshold(double meters) {
    return _updateSettings(
      (s) => s.copyWith(
        casHorizontalThreshold: meters.clamp(50.0, 1000.0).toDouble(),
      ),
    );
  }

  Future<SettingsUpdateResult> updateCasVerticalThreshold(double meters) {
    return _updateSettings(
      (s) => s.copyWith(
        casVerticalThreshold: meters.clamp(20.0, 1000.0).toDouble(),
      ),
    );
  }

  Future<SettingsUpdateResult> updateGdl90Enabled(bool enabled) {
    return _updateSettings((s) => s.copyWith(gdl90Enabled: enabled));
  }

  Future<SettingsUpdateResult> updateGdl90BindIp(String ip) {
    return _updateSettings((s) => s.copyWith(gdl90BindIp: ip.trim()));
  }

  Future<SettingsUpdateResult> updateGdl90UdpPort(int port) {
    return _updateSettings(
      (s) => s.copyWith(gdl90UdpPort: port.clamp(1, 65535)),
    );
  }

  Future<SettingsUpdateResult> updateGdl90TargetExpirySeconds(int seconds) {
    return _updateSettings(
      (s) => s.copyWith(gdl90TargetExpirySeconds: seconds.clamp(10, 300)),
    );
  }

  Future<SettingsUpdateResult> updateOgnEnabled(bool enabled) {
    return _updateSettings((s) => s.copyWith(ognEnabled: enabled));
  }

  Future<SettingsUpdateResult> updatePureTrackEnabled(bool enabled) {
    return _updateSettings((s) => s.copyWith(pureTrackEnabled: enabled));
  }
}
