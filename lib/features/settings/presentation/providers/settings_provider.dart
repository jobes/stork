import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/services/mdns_service.dart';
import '../../data/repositories/settings_repository.dart';
import '../../domain/app_settings.dart';
import '../../domain/cannelloni_device.dart';
import '../../domain/range_thresholds.dart';
import '../../domain/widget_position.dart';

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
    if (count <= 0) return Future.value(SettingsUpdateFailure(ArgumentError('Count must be positive'), StackTrace.current));
    return _updateSettings((s) => s.copyWith(courseLineSegmentsCount: count));
  }

  Future<SettingsUpdateResult> updateCourseLineSegmentDuration(int duration) {
    if (duration <= 0) return Future.value(SettingsUpdateFailure(ArgumentError('Duration must be positive'), StackTrace.current));
    return _updateSettings((s) => s.copyWith(courseLineSegmentDuration: duration));
  }

  Future<SettingsUpdateResult> updateFollowZoom(double zoom) =>
      _updateSettings((s) => s.copyWith(mapFollowZoom: zoom));

  Future<SettingsUpdateResult> updateFlightSpeedThresholds(
          RangeThresholds thresholds) =>
      _updateSettings((s) => s.copyWith(flightSpeedThresholds: thresholds));

  Future<SettingsUpdateResult> updateFlightSpeedMaxRange(double maxRange) {
    double normalizedMaxRange = maxRange;
    if (!normalizedMaxRange.isFinite || normalizedMaxRange <= 0.0) {
      normalizedMaxRange = 140.0;
    } else {
      normalizedMaxRange = normalizedMaxRange.clamp(10.0, 1000.0);
    }

    return _updateSettings((s) {
      final thresholds = s.flightSpeedThresholds;
      final newMaxError = (thresholds.maxError ?? 125.0).clamp(0.0, normalizedMaxRange).roundToDouble();
      final newMaxWarning = (thresholds.maxWarning ?? 110.0).clamp(0.0, newMaxError).roundToDouble();
      final newMinWarning = (thresholds.minWarning ?? 75.0).clamp(0.0, newMaxWarning).roundToDouble();
      final newMinError = (thresholds.minError ?? 60.0).clamp(0.0, newMinWarning).roundToDouble();
      final newInactiveMax = (thresholds.inactiveMax ?? 10.0).clamp(0.0, newMinError).roundToDouble();

      return s.copyWith(
        flightSpeedMaxRange: normalizedMaxRange,
        flightSpeedThresholds: thresholds.copyWith(
           inactiveMax: newInactiveMax,
           minError: newMinError,
           minWarning: newMinWarning,
           maxWarning: newMaxWarning,
           maxError: newMaxError,
        ),
      );
    });
  }

  /// Updates the auto-select device setting and, if enabled, performs auto-selection immediately.
  ///
  /// Invokes [_updateSettings] to update the setting, then awaits [_tryAutoSelectDevice] which
  /// may in turn invoke [updateSelectedDevice] (which also uses [_updateSettings]).
  /// If the auto-selection step fails, that failure is surfaced as the result.
  Future<SettingsUpdateResult> updateAutoSelectDevice(bool autoSelect) async {
    final result = await _updateSettings((s) => s.copyWith(autoSelectDevice: autoSelect));

    if (result is SettingsUpdateFailure) {
      return result;
    }

    // If turned on, try to auto-select immediately
    if (autoSelect) {
      final devices = ref.read(discoveredDevicesProvider).asData?.value ?? [];
      final currentSettings = state.hasValue ? state.value : state.asData?.value;
      if (currentSettings != null) {
        final autoSelectResult = await _tryAutoSelectDevice(devices, currentSettings);
        if (autoSelectResult is SettingsUpdateFailure) {
          return autoSelectResult;
        }
      }
    }
    return result;
  }

  Future<SettingsUpdateResult> updateAreWidgetsDraggable(bool areDraggable) =>
      _updateSettings((s) => s.copyWith(areWidgetsDraggable: areDraggable));

  Future<SettingsUpdateResult> updateWidgetPosition(String widgetId, double top, double left) {
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
}
