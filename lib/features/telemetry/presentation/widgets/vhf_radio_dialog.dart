import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stork/core/utils/number_formatter.dart';
import 'package:stork/features/telemetry/presentation/providers/favorite_frequencies_provider.dart';
import 'package:stork/features/telemetry/presentation/providers/nearby_frequencies_provider.dart';
import 'package:stork/features/telemetry/presentation/providers/vhf_radio_dialog_notifier.dart';
import 'package:stork/features/telemetry/presentation/utils/radio_popup_util.dart';
import 'package:stork/features/telemetry/presentation/widgets/manage_favorites_dialog.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../map/presentation/components/dialogs/base_details_dialog.dart';

part 'vhf_radio_dialog_quick_ext.dart';
part 'vhf_radio_dialog_advanced_ext.dart';
part 'vhf_radio_dialog_lists_ext.dart';
part 'vhf_radio_dialog_audio_ext.dart';

class VhfRadioDialog extends ConsumerStatefulWidget {
  final int radioInstance;
  final int nodeId;

  // Performance optimisation: the dialog state is an intentional snapshot of values
  // captured at open time and is not reactively bound to telemetryProvider. This avoids
  // unnecessary widget rebuilds on every incoming telemetry frame (~100 ms cadence).
  // The user does not need to see live changes while the dialog is open –
  // reopening the dialog will pick up the latest values.
  // Note: NearbyFrequencies performs a one-shot DB lookup on dialog open, which is a
  // computationally expensive operation; reactive updates would re-trigger it on every
  // GPS position change.
  final int initialActiveKhz;
  final int initialStandbyKhz;
  final String initialActiveName;
  final String initialStandbyName;
  final int initialVolume;
  final int initialSquelch;
  final int initialVox;
  final int initialIntercom;
  final List<int> initialMicGain;
  final bool initialIsDual;

  const VhfRadioDialog({
    super.key,
    required this.radioInstance,
    required this.nodeId,
    required this.initialActiveKhz,
    required this.initialStandbyKhz,
    required this.initialActiveName,
    required this.initialStandbyName,
    required this.initialVolume,
    required this.initialSquelch,
    required this.initialVox,
    required this.initialIntercom,
    required this.initialMicGain,
    required this.initialIsDual,
  });

  @override
  ConsumerState<VhfRadioDialog> createState() => _VhfRadioDialogState();
}

class _VhfRadioDialogState extends ConsumerState<VhfRadioDialog> {
  // TextEditingControllers must remain in widget state because they hold
  // Flutter-lifecycle-bound resources that require explicit dispose().
  // The notifier (VhfRadioDialogNotifier) is the source of truth for all other
  // state; controllers are kept in sync with the notifier via ref.listenManual
  // so that notifier-driven changes (e.g. flip, quick-set) are reflected in the
  // text fields.
  late final TextEditingController _activeController;
  late final TextEditingController _activeNameController;
  late final TextEditingController _standbyController;
  late final TextEditingController _standbyNameController;
  late final ProviderSubscription<VhfRadioDialogUiState> _providerSubscription;

  // Cached provider instance — avoids reconstructing the named-parameter record
  // (i.e. the family argument tuple) on every _notifier access, ref.watch call,
  // and ref.listenManual registration.
  late final VhfRadioDialogNotifierProvider _provider;

  VhfRadioDialogNotifier get _notifier => ref.read(_provider.notifier);

  String? _resolveErrorMessage(
    BuildContext context,
    VhfRadioDialogUiState uiState,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final code = uiState.errorCode;
    if (code == null) {
      return null;
    }

    return switch (code) {
      VhfRadioDialogErrorCode.invalidActiveFrequency =>
        l10n.vhfRadioErrorActiveFreq,
      VhfRadioDialogErrorCode.invalidStandbyFrequency =>
        l10n.vhfRadioErrorStandbyFreq,
      VhfRadioDialogErrorCode.invalidQuickFrequency =>
        l10n.vhfRadioErrorInvalidFreq(uiState.invalidFrequencyText ?? ''),
      VhfRadioDialogErrorCode.timeout => l10n.vhfRadioErrorTimeout(
        _localizedErrorAction(l10n, uiState.errorAction),
      ),
      VhfRadioDialogErrorCode.generic => l10n.vhfRadioErrorGeneric(
        _localizedErrorAction(l10n, uiState.errorAction),
        uiState.errorDetails ?? '',
      ),
      VhfRadioDialogErrorCode.genericFlip => l10n.vhfRadioErrorFlip(
        uiState.errorDetails ?? '',
      ),
    };
  }

  String _localizedErrorAction(
    AppLocalizations l10n,
    VhfRadioDialogErrorAction? action,
  ) {
    return switch (action) {
      VhfRadioDialogErrorAction.activeFrequency => l10n.vhfRadioActiveFreqLabel,
      VhfRadioDialogErrorAction.standbyFrequency =>
        l10n.vhfRadioStandbyFreqLabel,
      VhfRadioDialogErrorAction.flipFrequencies => l10n.vhfRadioSwapTooltip,
      VhfRadioDialogErrorAction.dualWatch => l10n.vhfRadioDualWatch,
      VhfRadioDialogErrorAction.volume => l10n.vhfRadioVolume,
      VhfRadioDialogErrorAction.squelch => l10n.vhfRadioSquelch,
      VhfRadioDialogErrorAction.vox => l10n.vhfRadioVox,
      VhfRadioDialogErrorAction.intercom => l10n.vhfRadioIntercom,
      VhfRadioDialogErrorAction.micGain => l10n.vhfRadioMicrophonesGain,
      VhfRadioDialogErrorAction.frequency => l10n.vhfRadioNearbyFrequencies,
      null => l10n.errorPrefix,
    };
  }

  @override
  void initState() {
    super.initState();

    _provider = vhfRadioDialogProvider(
      widget.nodeId,
      widget.radioInstance,
      initialActiveKhz: widget.initialActiveKhz,
      initialStandbyKhz: widget.initialStandbyKhz,
      initialActiveName: widget.initialActiveName,
      initialStandbyName: widget.initialStandbyName,
      initialVolume: widget.initialVolume,
      initialSquelch: widget.initialSquelch,
      initialVox: widget.initialVox,
      initialIntercom: widget.initialIntercom,
      initialMicGain: widget.initialMicGain,
      initialIsDual: widget.initialIsDual,
    );

    final initialActiveText = (widget.initialActiveKhz / 1000.0)
        .toStringAsFixed(3);
    final initialStandbyText = (widget.initialStandbyKhz / 1000.0)
        .toStringAsFixed(3);

    _activeController = TextEditingController(text: initialActiveText);
    _activeNameController = TextEditingController(
      text: widget.initialActiveName,
    );
    _standbyController = TextEditingController(text: initialStandbyText);
    _standbyNameController = TextEditingController(
      text: widget.initialStandbyName,
    );

    // Rebuild on every text change so the "Apply" checkmark dirty state updates.
    _activeController.addListener(_onTextChanged);
    _activeNameController.addListener(_onTextChanged);
    _standbyController.addListener(_onTextChanged);
    _standbyNameController.addListener(_onTextChanged);

    // Sync TextEditingControllers whenever the notifier pushes a change to the
    // freq/name fields (flip, quick-set from the list). Only update when the
    // value actually differs to avoid disrupting cursor position during typing.
    // Registered once in initState — never re-registered on subsequent rebuilds.
    _providerSubscription = ref.listenManual(_provider, (previous, next) {
      if (_activeController.text != next.activeFreqText) {
        _activeController.text = next.activeFreqText;
      }
      if (_activeNameController.text != next.activeNameText) {
        _activeNameController.text = next.activeNameText;
      }
      if (_standbyController.text != next.standbyFreqText) {
        _standbyController.text = next.standbyFreqText;
      }
      if (_standbyNameController.text != next.standbyNameText) {
        _standbyNameController.text = next.standbyNameText;
      }
    });
  }

  void _onTextChanged() => setState(() {});

  @override
  void dispose() {
    _activeController.removeListener(_onTextChanged);
    _activeNameController.removeListener(_onTextChanged);
    _standbyController.removeListener(_onTextChanged);
    _standbyNameController.removeListener(_onTextChanged);
    _providerSubscription.close();
    _activeController.dispose();
    _activeNameController.dispose();
    _standbyController.dispose();
    _standbyNameController.dispose();
    super.dispose();
  }

  // Delegates the frequency selection menu to RadioPopupUtil, which reads the current
  // radio state directly from telemetryProvider. After the user picks an option,
  // the notifier's quickSetFrequency is called to keep the dialog snapshot consistent.
  void _showFrequencyMenu(Offset globalPosition, double mhz, String name) {
    RadioPopupUtil.showRadioMenu(
      context: context,
      ref: ref,
      globalPosition: globalPosition,
      mhz: mhz,
      radioName: name,
      onFrequencySet: (isActive) =>
          _notifier.quickSetFrequency(mhz, name, isActive),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uiState = ref.watch(_provider);
    if (!uiState.showAdvancedMode) {
      return _buildQuickContent(context, uiState);
    }
    return _buildAdvancedContent(context, uiState);
  }
}

class _FrequencyInfo {
  final double mhz;
  final String name;
  const _FrequencyInfo(this.mhz, this.name);
}
