import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:stork/features/telemetry/presentation/providers/vhf_radio_controller.dart';
import 'package:stork/features/telemetry/presentation/utils/vhf_radio_frequency.dart';

part 'vhf_radio_dialog_notifier.g.dart';

enum VhfRadioDialogErrorCode {
  invalidActiveFrequency,
  invalidStandbyFrequency,
  invalidQuickFrequency,
  timeout,
  generic,
  genericFlip,
}

enum VhfRadioDialogErrorAction {
  activeFrequency,
  standbyFrequency,
  flipFrequencies,
  dualWatch,
  volume,
  squelch,
  vox,
  intercom,
  micGain,
  frequency,
}

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
  final VhfRadioDialogErrorCode? errorCode;
  final VhfRadioDialogErrorAction? errorAction;
  final String? errorDetails;
  final String? invalidFrequencyText;
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
    this.errorCode,
    this.errorAction,
    this.errorDetails,
    this.invalidFrequencyText,
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
    VhfRadioDialogErrorCode? Function()? errorCode,
    VhfRadioDialogErrorAction? Function()? errorAction,
    String? Function()? errorDetails,
    String? Function()? invalidFrequencyText,
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
      errorCode: errorCode != null ? errorCode() : this.errorCode,
      errorAction: errorAction != null ? errorAction() : this.errorAction,
      errorDetails: errorDetails != null ? errorDetails() : this.errorDetails,
      invalidFrequencyText: invalidFrequencyText != null
          ? invalidFrequencyText()
          : this.invalidFrequencyText,
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
  void _clearErrorAndSetSaving() {
    state = state.copyWith(
      isSaving: true,
      errorCode: () => null,
      errorAction: () => null,
      errorDetails: () => null,
      invalidFrequencyText: () => null,
    );
  }

  void _setTimeoutError(VhfRadioDialogErrorAction action) {
    state = state.copyWith(
      isSaving: false,
      errorCode: () => VhfRadioDialogErrorCode.timeout,
      errorAction: () => action,
      errorDetails: () => null,
      invalidFrequencyText: () => null,
    );
  }

  void _setGenericError(VhfRadioDialogErrorAction action, Object error) {
    state = state.copyWith(
      isSaving: false,
      errorCode: () => VhfRadioDialogErrorCode.generic,
      errorAction: () => action,
      errorDetails: () => error.toString(),
      invalidFrequencyText: () => null,
    );
  }

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
    return parseVhfRadioFrequency(text);
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
        errorCode: () => VhfRadioDialogErrorCode.invalidActiveFrequency,
        errorAction: () => null,
        errorDetails: () => null,
        invalidFrequencyText: () => null,
      );
      return;
    }
    _clearErrorAndSetSaving();
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
      if (e is TimeoutException) {
        _setTimeoutError(VhfRadioDialogErrorAction.activeFrequency);
      } else {
        _setGenericError(VhfRadioDialogErrorAction.activeFrequency, e);
      }
    }
  }

  Future<void> saveStandbyFrequency(String freqText, String nameText) async {
    final freqKhz = parseAviationFrequency(freqText);
    if (freqKhz == null) {
      state = state.copyWith(
        isSaving: false,
        errorCode: () => VhfRadioDialogErrorCode.invalidStandbyFrequency,
        errorAction: () => null,
        errorDetails: () => null,
        invalidFrequencyText: () => null,
      );
      return;
    }
    _clearErrorAndSetSaving();
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
      if (e is TimeoutException) {
        _setTimeoutError(VhfRadioDialogErrorAction.standbyFrequency);
      } else {
        _setGenericError(VhfRadioDialogErrorAction.standbyFrequency, e);
      }
    }
  }

  Future<void> flipFrequencies({
    required String currentActiveText,
    required String currentActiveName,
    required String currentStandbyText,
    required String currentStandbyName,
  }) async {
    _clearErrorAndSetSaving();
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
      if (e is TimeoutException) {
        _setTimeoutError(VhfRadioDialogErrorAction.flipFrequencies);
      } else {
        state = state.copyWith(
          isSaving: false,
          errorCode: () => VhfRadioDialogErrorCode.genericFlip,
          errorAction: () => null,
          errorDetails: () => e.toString(),
          invalidFrequencyText: () => null,
        );
      }
    }
  }

  Future<void> toggleDualWatch(bool val) async {
    _clearErrorAndSetSaving();
    try {
      await ref
          .read(vhfRadioControllerProvider.notifier)
          .toggleDualWatch(nodeId: nodeId, radioInstance: radioInstance);
      state = state.copyWith(isDual: val, isSaving: false);
    } catch (e) {
      if (e is TimeoutException) {
        _setTimeoutError(VhfRadioDialogErrorAction.dualWatch);
      } else {
        _setGenericError(VhfRadioDialogErrorAction.dualWatch, e);
      }
    }
  }

  Future<void> saveVolume() async {
    final target = state.volume.round();
    _clearErrorAndSetSaving();
    try {
      await ref
          .read(vhfRadioControllerProvider.notifier)
          .setVolume(nodeId, radioInstance, target);
      state = state.copyWith(savedVolume: target, isSaving: false);
    } catch (e) {
      if (e is TimeoutException) {
        _setTimeoutError(VhfRadioDialogErrorAction.volume);
      } else {
        _setGenericError(VhfRadioDialogErrorAction.volume, e);
      }
    }
  }

  Future<void> saveSquelch() async {
    final target = state.squelch.round();
    _clearErrorAndSetSaving();
    try {
      await ref
          .read(vhfRadioControllerProvider.notifier)
          .setSquelch(nodeId, radioInstance, target);
      state = state.copyWith(savedSquelch: target, isSaving: false);
    } catch (e) {
      if (e is TimeoutException) {
        _setTimeoutError(VhfRadioDialogErrorAction.squelch);
      } else {
        _setGenericError(VhfRadioDialogErrorAction.squelch, e);
      }
    }
  }

  Future<void> saveVox() async {
    final target = state.vox.round();
    _clearErrorAndSetSaving();
    try {
      await ref
          .read(vhfRadioControllerProvider.notifier)
          .setVox(nodeId, radioInstance, target);
      state = state.copyWith(savedVox: target, isSaving: false);
    } catch (e) {
      if (e is TimeoutException) {
        _setTimeoutError(VhfRadioDialogErrorAction.vox);
      } else {
        _setGenericError(VhfRadioDialogErrorAction.vox, e);
      }
    }
  }

  Future<void> saveIntercom() async {
    final target = state.intercom.round();
    _clearErrorAndSetSaving();
    try {
      await ref
          .read(vhfRadioControllerProvider.notifier)
          .setIntercom(nodeId, radioInstance, target);
      state = state.copyWith(savedIntercom: target, isSaving: false);
    } catch (e) {
      if (e is TimeoutException) {
        _setTimeoutError(VhfRadioDialogErrorAction.intercom);
      } else {
        _setGenericError(VhfRadioDialogErrorAction.intercom, e);
      }
    }
  }

  Future<void> saveMicGain(int index) async {
    final target = state.micGains[index].round();
    _clearErrorAndSetSaving();
    try {
      await ref
          .read(vhfRadioControllerProvider.notifier)
          .setMicGain(nodeId, radioInstance, index, target);
      final updated = List<int>.from(state.savedMicGains);
      updated[index] = target;
      state = state.copyWith(savedMicGains: updated, isSaving: false);
    } catch (e) {
      if (e is TimeoutException) {
        _setTimeoutError(VhfRadioDialogErrorAction.micGain);
      } else {
        _setGenericError(VhfRadioDialogErrorAction.micGain, e);
      }
    }
  }

  Future<void> quickSetFrequency(double mhz, String name, bool isActive) async {
    final freqStr = mhz.toStringAsFixed(3);
    final freqKhz = parseAviationFrequency(freqStr);
    if (freqKhz == null) {
      state = state.copyWith(
        isSaving: false,
        errorCode: () => VhfRadioDialogErrorCode.invalidQuickFrequency,
        errorAction: () => null,
        errorDetails: () => null,
        invalidFrequencyText: () => freqStr,
      );
      return;
    }
    _clearErrorAndSetSaving();
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
      if (e is TimeoutException) {
        _setTimeoutError(VhfRadioDialogErrorAction.frequency);
      } else {
        _setGenericError(VhfRadioDialogErrorAction.frequency, e);
      }
    }
  }
}
