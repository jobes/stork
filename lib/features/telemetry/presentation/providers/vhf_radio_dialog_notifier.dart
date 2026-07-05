import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:stork/features/telemetry/presentation/providers/vhf_radio_controller.dart';

part 'vhf_radio_dialog_notifier.g.dart';

// ---------------------------------------------------------------------------
// Immutable state
// ---------------------------------------------------------------------------

class VhfRadioDialogUiState {
  // Displayed frequency / name values. These are the source of truth for what
  // is shown in the dialog header (quick mode) and the text fields (advanced
  // mode). The widget's TextEditingControllers are kept in sync with these via
  // ref.listenManual so that user edits made through the text fields (advanced
  // mode) are still held locally in the controllers and only pushed back here
  // on explicit save.
  final String activeFreqText;
  final String activeNameText;
  final String standbyFreqText;
  final String standbyNameText;

  // Last successfully sent values – used to compute the dirty / unsaved state
  // so the "Apply" checkmark buttons can be enabled/disabled correctly.
  final String savedActiveText;
  final String savedActiveName;
  final String savedStandbyText;
  final String savedStandbyName;

  // Audio controls
  final double volume;
  final double squelch;
  final double vox;
  final double intercom;
  final List<double> micGains;

  final int savedVolume;
  final int savedSquelch;
  final int savedVox;
  final int savedIntercom;
  final List<int> savedMicGains;

  // Radio flags
  final bool isDual;

  // UI state
  final bool isSaving;
  final String? errorMessage;
  final bool showAudioControls;
  final bool showAdvancedMode;

  const VhfRadioDialogUiState({
    required this.activeFreqText,
    required this.activeNameText,
    required this.standbyFreqText,
    required this.standbyNameText,
    required this.savedActiveText,
    required this.savedActiveName,
    required this.savedStandbyText,
    required this.savedStandbyName,
    required this.volume,
    required this.squelch,
    required this.vox,
    required this.intercom,
    required this.micGains,
    required this.savedVolume,
    required this.savedSquelch,
    required this.savedVox,
    required this.savedIntercom,
    required this.savedMicGains,
    required this.isDual,
    this.isSaving = false,
    this.errorMessage,
    this.showAudioControls = false,
    this.showAdvancedMode = false,
  });

  VhfRadioDialogUiState copyWith({
    String? activeFreqText,
    String? activeNameText,
    String? standbyFreqText,
    String? standbyNameText,
    String? savedActiveText,
    String? savedActiveName,
    String? savedStandbyText,
    String? savedStandbyName,
    double? volume,
    double? squelch,
    double? vox,
    double? intercom,
    List<double>? micGains,
    int? savedVolume,
    int? savedSquelch,
    int? savedVox,
    int? savedIntercom,
    List<int>? savedMicGains,
    bool? isDual,
    bool? isSaving,
    String? Function()? errorMessage,
    bool? showAudioControls,
    bool? showAdvancedMode,
  }) {
    return VhfRadioDialogUiState(
      activeFreqText: activeFreqText ?? this.activeFreqText,
      activeNameText: activeNameText ?? this.activeNameText,
      standbyFreqText: standbyFreqText ?? this.standbyFreqText,
      standbyNameText: standbyNameText ?? this.standbyNameText,
      savedActiveText: savedActiveText ?? this.savedActiveText,
      savedActiveName: savedActiveName ?? this.savedActiveName,
      savedStandbyText: savedStandbyText ?? this.savedStandbyText,
      savedStandbyName: savedStandbyName ?? this.savedStandbyName,
      volume: volume ?? this.volume,
      squelch: squelch ?? this.squelch,
      vox: vox ?? this.vox,
      intercom: intercom ?? this.intercom,
      micGains: micGains ?? this.micGains,
      savedVolume: savedVolume ?? this.savedVolume,
      savedSquelch: savedSquelch ?? this.savedSquelch,
      savedVox: savedVox ?? this.savedVox,
      savedIntercom: savedIntercom ?? this.savedIntercom,
      savedMicGains: savedMicGains ?? this.savedMicGains,
      isDual: isDual ?? this.isDual,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      showAudioControls: showAudioControls ?? this.showAudioControls,
      showAdvancedMode: showAdvancedMode ?? this.showAdvancedMode,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

@riverpod
class VhfRadioDialogNotifier extends _$VhfRadioDialogNotifier {
  @override
  VhfRadioDialogUiState build(
    int nodeId,
    int radioInstance, {
    required int initialActiveKhz,
    required int initialStandbyKhz,
    required String initialActiveName,
    required String initialStandbyName,
    required int initialVolume,
    required int initialSquelch,
    required int initialVox,
    required int initialIntercom,
    required List<int> initialMicGain,
    required bool initialIsDual,
  }) {
    final activeText = (initialActiveKhz / 1000.0).toStringAsFixed(3);
    final standbyText = (initialStandbyKhz / 1000.0).toStringAsFixed(3);

    return VhfRadioDialogUiState(
      activeFreqText: activeText,
      activeNameText: initialActiveName,
      standbyFreqText: standbyText,
      standbyNameText: initialStandbyName,
      savedActiveText: activeText,
      savedActiveName: initialActiveName,
      savedStandbyText: standbyText,
      savedStandbyName: initialStandbyName,
      volume: initialVolume.toDouble(),
      squelch: initialSquelch.toDouble(),
      vox: initialVox.toDouble(),
      intercom: initialIntercom.toDouble(),
      micGains: initialMicGain.map((g) => g.toDouble()).toList(),
      savedVolume: initialVolume,
      savedSquelch: initialSquelch,
      savedVox: initialVox,
      savedIntercom: initialIntercom,
      savedMicGains: List<int>.from(initialMicGain),
      isDual: initialIsDual,
    );
  }

  // ---- Validation ----------------------------------------------------------

  static int? parseAviationFrequency(String text) {
    if (!RegExp(r'^\d{3}\.\d{3}$').hasMatch(text.trim())) return null;
    final double? mhz = double.tryParse(text.trim());
    if (mhz == null) return null;
    if (mhz < 118.000 || mhz > 136.995) return null;
    final int totalKhzRounded = (mhz * 1000).round();
    const Set<int> validAviationOffsets = {
      0,
      5,
      10,
      15,
      25,
      30,
      35,
      40,
      50,
      55,
      60,
      65,
      75,
      80,
      85,
      90,
    };
    if (!validAviationOffsets.contains(totalKhzRounded % 100)) return null;
    return totalKhzRounded;
  }

  // ---- UI toggles ----------------------------------------------------------

  void toggleAudioControls() {
    state = state.copyWith(showAudioControls: !state.showAudioControls);
  }

  void toggleAdvancedMode() {
    state = state.copyWith(showAdvancedMode: !state.showAdvancedMode);
  }

  void setAdvancedMode(bool value) {
    state = state.copyWith(showAdvancedMode: value);
  }

  // ---- Slider staging (before save) ----------------------------------------
  // These update the local slider position only; no DroneCAN request is sent
  // until the user taps the "Apply" checkmark.

  void updateVolume(double val) => state = state.copyWith(volume: val);
  void updateSquelch(double val) => state = state.copyWith(squelch: val);
  void updateVox(double val) => state = state.copyWith(vox: val);
  void updateIntercom(double val) => state = state.copyWith(intercom: val);
  void updateMicGain(int index, double val) {
    final updated = List<double>.from(state.micGains);
    updated[index] = val;
    state = state.copyWith(micGains: updated);
  }

  // ---- DroneCAN save operations --------------------------------------------

  Future<void> saveActiveFrequency(String freqText, String nameText) async {
    final freqKhz = parseAviationFrequency(freqText);
    if (freqKhz == null) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: () =>
            'Active frequency must be a valid aviation frequency (118.000 – 136.975 MHz).',
      );
      return;
    }
    state = state.copyWith(isSaving: true, errorMessage: () => null);
    try {
      await ref
          .read(vhfRadioControllerProvider.notifier)
          .setActiveFrequency(
            nodeId: nodeId,
            radioInstance: radioInstance,
            frequencyKhz: freqKhz,
            name: nameText,
          );
      state = state.copyWith(
        activeFreqText: freqText.trim(),
        activeNameText: nameText,
        savedActiveText: freqText.trim(),
        savedActiveName: nameText,
        isSaving: false,
      );
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: () => e is TimeoutException
            ? 'DroneCAN did not respond to active frequency request (timeout 1 s).'
            : 'Failed to set active frequency: ${e.toString()}',
      );
    }
  }

  Future<void> saveStandbyFrequency(String freqText, String nameText) async {
    final freqKhz = parseAviationFrequency(freqText);
    if (freqKhz == null) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: () =>
            'Standby frequency must be a valid aviation frequency (118.000 – 136.975 MHz).',
      );
      return;
    }
    state = state.copyWith(isSaving: true, errorMessage: () => null);
    try {
      await ref
          .read(vhfRadioControllerProvider.notifier)
          .setStandbyFrequency(
            nodeId: nodeId,
            radioInstance: radioInstance,
            frequencyKhz: freqKhz,
            name: nameText,
          );
      state = state.copyWith(
        standbyFreqText: freqText.trim(),
        standbyNameText: nameText,
        savedStandbyText: freqText.trim(),
        savedStandbyName: nameText,
        isSaving: false,
      );
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: () => e is TimeoutException
            ? 'DroneCAN did not respond to standby frequency request (timeout 1 s).'
            : 'Failed to set standby frequency: ${e.toString()}',
      );
    }
  }

  Future<void> flipFrequencies({
    required String currentActiveText,
    required String currentActiveName,
    required String currentStandbyText,
    required String currentStandbyName,
  }) async {
    state = state.copyWith(isSaving: true, errorMessage: () => null);
    try {
      await ref
          .read(vhfRadioControllerProvider.notifier)
          .flipFrequencies(nodeId: nodeId, radioInstance: radioInstance);

      state = state.copyWith(
        activeFreqText: currentStandbyText,
        activeNameText: currentStandbyName,
        standbyFreqText: currentActiveText,
        standbyNameText: currentActiveName,
        savedActiveText: currentStandbyText,
        savedActiveName: currentStandbyName,
        savedStandbyText: currentActiveText,
        savedStandbyName: currentActiveName,
        isSaving: false,
      );
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: () => e is TimeoutException
            ? 'DroneCAN did not respond to flip request (timeout 1 s).'
            : 'Flip failed: ${e.toString()}',
      );
    }
  }

  Future<void> toggleDualWatch(bool val) async {
    state = state.copyWith(isSaving: true, errorMessage: () => null);
    try {
      await ref
          .read(vhfRadioControllerProvider.notifier)
          .toggleDualWatch(nodeId: nodeId, radioInstance: radioInstance);
      state = state.copyWith(isDual: val, isSaving: false);
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: () => e is TimeoutException
            ? 'DroneCAN did not respond to Dual Watch request (timeout 1 s).'
            : 'Dual Watch failed: ${e.toString()}',
      );
    }
  }

  Future<void> saveVolume() async {
    final target = state.volume.round();
    state = state.copyWith(isSaving: true, errorMessage: () => null);
    try {
      await ref
          .read(vhfRadioControllerProvider.notifier)
          .setVolume(nodeId, radioInstance, target);
      state = state.copyWith(savedVolume: target, isSaving: false);
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: () => e is TimeoutException
            ? 'DroneCAN did not respond to volume change (timeout 1 s).'
            : 'Failed to save volume: ${e.toString()}',
      );
    }
  }

  Future<void> saveSquelch() async {
    final target = state.squelch.round();
    state = state.copyWith(isSaving: true, errorMessage: () => null);
    try {
      await ref
          .read(vhfRadioControllerProvider.notifier)
          .setSquelch(nodeId, radioInstance, target);
      state = state.copyWith(savedSquelch: target, isSaving: false);
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: () => e is TimeoutException
            ? 'DroneCAN did not respond to squelch change (timeout 1 s).'
            : 'Failed to save squelch: ${e.toString()}',
      );
    }
  }

  Future<void> saveVox() async {
    final target = state.vox.round();
    state = state.copyWith(isSaving: true, errorMessage: () => null);
    try {
      await ref
          .read(vhfRadioControllerProvider.notifier)
          .setVox(nodeId, radioInstance, target);
      state = state.copyWith(savedVox: target, isSaving: false);
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: () => e is TimeoutException
            ? 'DroneCAN did not respond to VOX change (timeout 1 s).'
            : 'Failed to save VOX: ${e.toString()}',
      );
    }
  }

  Future<void> saveIntercom() async {
    final target = state.intercom.round();
    state = state.copyWith(isSaving: true, errorMessage: () => null);
    try {
      await ref
          .read(vhfRadioControllerProvider.notifier)
          .setIntercom(nodeId, radioInstance, target);
      state = state.copyWith(savedIntercom: target, isSaving: false);
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: () => e is TimeoutException
            ? 'DroneCAN did not respond to intercom change (timeout 1 s).'
            : 'Failed to save intercom: ${e.toString()}',
      );
    }
  }

  Future<void> saveMicGain(int index) async {
    final target = state.micGains[index].round();
    state = state.copyWith(isSaving: true, errorMessage: () => null);
    try {
      await ref
          .read(vhfRadioControllerProvider.notifier)
          .setMicGain(nodeId, radioInstance, index, target);
      final updated = List<int>.from(state.savedMicGains);
      updated[index] = target;
      state = state.copyWith(savedMicGains: updated, isSaving: false);
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: () => e is TimeoutException
            ? 'DroneCAN did not respond to mic gain change (timeout 1 s).'
            : 'Failed to save mic gain: ${e.toString()}',
      );
    }
  }

  Future<void> quickSetFrequency(double mhz, String name, bool isActive) async {
    final freqStr = mhz.toStringAsFixed(3);
    final freqKhz = parseAviationFrequency(freqStr);
    if (freqKhz == null) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: () => 'Frequency $freqStr MHz is not valid.',
      );
      return;
    }
    state = state.copyWith(isSaving: true, errorMessage: () => null);
    try {
      if (isActive) {
        await ref
            .read(vhfRadioControllerProvider.notifier)
            .setActiveFrequency(
              nodeId: nodeId,
              radioInstance: radioInstance,
              frequencyKhz: freqKhz,
              name: name,
            );
        state = state.copyWith(
          activeFreqText: freqStr,
          activeNameText: name,
          savedActiveText: freqStr,
          savedActiveName: name,
          isSaving: false,
        );
      } else {
        await ref
            .read(vhfRadioControllerProvider.notifier)
            .setStandbyFrequency(
              nodeId: nodeId,
              radioInstance: radioInstance,
              frequencyKhz: freqKhz,
              name: name,
            );
        state = state.copyWith(
          standbyFreqText: freqStr,
          standbyNameText: name,
          savedStandbyText: freqStr,
          savedStandbyName: name,
          isSaving: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: () => e is TimeoutException
            ? 'DroneCAN did not respond (timeout 1 s).'
            : 'Failed to set frequency: ${e.toString()}',
      );
    }
  }
}
