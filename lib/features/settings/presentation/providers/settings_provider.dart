import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/services/mdns_service.dart';
import '../../data/repositories/settings_repository.dart';
import '../../domain/app_settings.dart';
import '../../domain/cannelloni_device.dart';

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
    final settings = repository.getSettings();

    // Listen to discovered devices for auto-selection
    ref.listen(discoveredDevicesProvider, (previous, next) {
      final devices = next.asData?.value ?? [];
      final currentSettings = state.asData?.value;

      if (currentSettings != null && currentSettings.autoSelectDevice) {
        _tryAutoSelectDevice(devices, currentSettings);
      }
    });

    return settings;
  }

  void _tryAutoSelectDevice(
    List<CannelloniDevice> devices,
    AppSettings currentSettings,
  ) {
    if (devices.isEmpty) return;

    final currentDevice = currentSettings.selectedDevice;
    final isCurrentStillAvailable =
        currentDevice != null && devices.contains(currentDevice);

    if (!isCurrentStillAvailable) {
      // Only switch to the first device if the current one is gone or if none was selected
      updateSelectedDevice(devices.first);
    }
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
      final repoSettings = repository.getSettings();

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

  Future<SettingsUpdateResult> updateFollowZoom(double zoom) =>
      _updateSettings((s) => s.copyWith(mapFollowZoom: zoom));

  Future<SettingsUpdateResult> updateAutoSelectDevice(bool autoSelect) async {
    final result = await _updateSettings((s) => s.copyWith(autoSelectDevice: autoSelect));

    // If turned on, try to auto-select immediately
    if (autoSelect) {
      final devices = ref.read(discoveredDevicesProvider).asData?.value ?? [];
      final currentSettings = state.hasValue ? state.value : state.asData?.value;
      if (currentSettings != null) {
        _tryAutoSelectDevice(devices, currentSettings);
      }
    }
    return result;
  }

  Future<SettingsUpdateResult> updateSelectedDevice(CannelloniDevice? device) =>
      _updateSettings((s) => s.copyWith(selectedDevice: device));
}
