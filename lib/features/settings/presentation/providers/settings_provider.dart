import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/services/mdns_service.dart';
import '../../data/repositories/settings_repository.dart';
import '../../domain/app_settings.dart';
import '../../domain/cannelloni_device.dart';

part 'settings_provider.g.dart';

@riverpod
class AppSettingsNotifier extends _$AppSettingsNotifier {
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

  Future<void> _updateSettings(
    AppSettings Function(AppSettings) updater,
  ) async {
    final currentState = state.asData?.value;
    if (currentState == null) return;

    final newSettings = updater(currentState);
    state = AsyncData(newSettings);

    final repository = await ref.read(settingsRepositoryProvider.future);
    await repository.saveSettings(newSettings);
  }

  Future<void> updateFontSize(double fontSize) =>
      _updateSettings((s) => s.copyWith(mapFontSize: fontSize));

  Future<void> updateDefaultZoom(double zoom) =>
      _updateSettings((s) => s.copyWith(mapDefaultZoom: zoom));

  Future<void> updateOverviewZoom(double zoom) =>
      _updateSettings((s) => s.copyWith(mapOverviewZoom: zoom));

  Future<void> updateFollowZoom(double zoom) =>
      _updateSettings((s) => s.copyWith(mapFollowZoom: zoom));

  Future<void> updateAutoSelectDevice(bool autoSelect) async {
    await _updateSettings((s) => s.copyWith(autoSelectDevice: autoSelect));

    // If turned on, try to auto-select immediately
    if (autoSelect) {
      final devices = ref.read(discoveredDevicesProvider).asData?.value ?? [];
      final currentSettings = state.asData?.value;
      if (currentSettings != null) {
        _tryAutoSelectDevice(devices, currentSettings);
      }
    }
  }

  Future<void> updateSelectedDevice(CannelloniDevice? device) =>
      _updateSettings((s) => s.copyWith(selectedDevice: device));
}
