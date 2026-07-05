part of 'vhf_radio_dialog.dart';

extension _VhfRadioDialogAdvancedExt on _VhfRadioDialogState {
  Widget _buildAdvancedContent(
    BuildContext context,
    VhfRadioDialogUiState uiState,
  ) {
    final activeText = _activeController.text.trim();
    final isActiveChanged =
        (activeText != uiState.savedActiveText ||
            _activeNameController.text != uiState.savedActiveName) &&
        RegExp(r'^\d{3}\.\d{3}$').hasMatch(activeText) &&
        VhfRadioDialogNotifier.parseAviationFrequency(activeText) != null;

    final standbyText = _standbyController.text.trim();
    final isStandbyChanged =
        (standbyText != uiState.savedStandbyText ||
            _standbyNameController.text != uiState.savedStandbyName) &&
        RegExp(r'^\d{3}\.\d{3}$').hasMatch(standbyText) &&
        VhfRadioDialogNotifier.parseAviationFrequency(standbyText) != null;

    final l10n = AppLocalizations.of(context)!;
    final errorText = _resolveErrorMessage(context, uiState);
    return BaseDetailsDialog(
      titleText: l10n.vhfRadioTitle(widget.radioInstance + 1),
      icon: Icons.radio,
      actions: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _notifier.setAdvancedMode(false),
          tooltip: l10n.vhfRadioBackToList,
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            key: const ValueKey('vhf_dialog_content'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (errorText != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.red.shade400,
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      errorText,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Active Frequency block
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _activeController,
                            enabled: !uiState.isSaving,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              labelText: l10n.vhfRadioActiveFreqLabel,
                              hintText: '118.000',
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                            ),
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _activeNameController,
                            enabled: !uiState.isSaving,
                            decoration: InputDecoration(
                              labelText: l10n.vhfRadioActiveNameLabel,
                              hintText: 'COM1 ACT',
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                            ),
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: (uiState.isSaving || !isActiveChanged)
                                ? null
                                : () => _notifier.saveActiveFrequency(
                                    _activeController.text,
                                    _activeNameController.text,
                                  ),
                            icon: const Icon(Icons.check, size: 14),
                            label: Text(
                              l10n.vhfRadioApply,
                              style: const TextStyle(fontSize: 11),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.green,
                              side: BorderSide(
                                color: isActiveChanged
                                    ? Colors.green
                                    : Colors.grey.shade400,
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 6,
                                horizontal: 10,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Flip/Swap button
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 24.0,
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.swap_horiz,
                          size: 28,
                          color: Colors.blueAccent,
                        ),
                        onPressed: uiState.isSaving
                            ? null
                            : () => _notifier.flipFrequencies(
                                currentActiveText: _activeController.text,
                                currentActiveName: _activeNameController.text,
                                currentStandbyText: _standbyController.text,
                                currentStandbyName: _standbyNameController.text,
                              ),
                        tooltip: l10n.vhfRadioSwapTooltip,
                      ),
                    ),

                    // Standby Frequency block
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _standbyController,
                            enabled: !uiState.isSaving,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              labelText: l10n.vhfRadioStandbyFreqLabel,
                              hintText: '121.500',
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                            ),
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _standbyNameController,
                            enabled: !uiState.isSaving,
                            decoration: InputDecoration(
                              labelText: l10n.vhfRadioStandbyNameLabel,
                              hintText: 'COM1 STB',
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                            ),
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: (uiState.isSaving || !isStandbyChanged)
                                ? null
                                : () => _notifier.saveStandbyFrequency(
                                    _standbyController.text,
                                    _standbyNameController.text,
                                  ),
                            icon: const Icon(Icons.check, size: 14),
                            label: Text(
                              l10n.vhfRadioApply,
                              style: const TextStyle(fontSize: 11),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.green,
                              side: BorderSide(
                                color: isStandbyChanged
                                    ? Colors.green
                                    : Colors.grey.shade400,
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 6,
                                horizontal: 10,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const Divider(height: 24),

                // Dual Watch Switch
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    l10n.vhfRadioDualWatch,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  value: uiState.isDual,
                  onChanged: uiState.isSaving
                      ? null
                      : _notifier.toggleDualWatch,
                ),

                const Divider(height: 24),

                // Audio controls (collapsible)
                InkWell(
                  onTap: _notifier.toggleAudioControls,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal: 4.0,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          uiState.showAudioControls
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: Colors.blueAccent,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          uiState.showAudioControls
                              ? l10n.vhfRadioHideAudio
                              : l10n.vhfRadioShowAudio,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.blueAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (uiState.showAudioControls) ...[
                  const SizedBox(height: 12),
                  _buildLabeledSlider(
                    label: l10n.vhfRadioVolume,
                    value: uiState.volume,
                    onChanged: _notifier.updateVolume,
                    onSave: _notifier.saveVolume,
                    isSaveEnabled:
                        uiState.volume.round() != uiState.savedVolume,
                    isSaving: uiState.isSaving,
                    icon: Icons.volume_up,
                  ),
                  _buildLabeledSlider(
                    label: l10n.vhfRadioSquelch,
                    value: uiState.squelch,
                    onChanged: _notifier.updateSquelch,
                    onSave: _notifier.saveSquelch,
                    isSaveEnabled:
                        uiState.squelch.round() != uiState.savedSquelch,
                    isSaving: uiState.isSaving,
                    icon: Icons.filter_list,
                  ),
                  _buildLabeledSlider(
                    label: l10n.vhfRadioVox,
                    value: uiState.vox,
                    onChanged: _notifier.updateVox,
                    onSave: _notifier.saveVox,
                    isSaveEnabled: uiState.vox.round() != uiState.savedVox,
                    isSaving: uiState.isSaving,
                    icon: Icons.keyboard_voice,
                  ),
                  _buildLabeledSlider(
                    label: l10n.vhfRadioIntercom,
                    value: uiState.intercom,
                    onChanged: _notifier.updateIntercom,
                    onSave: _notifier.saveIntercom,
                    isSaveEnabled:
                        uiState.intercom.round() != uiState.savedIntercom,
                    isSaving: uiState.isSaving,
                    icon: Icons.people,
                  ),

                  if (uiState.micGains.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      l10n.vhfRadioMicrophonesGain,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...List.generate(uiState.micGains.length, (idx) {
                      final savedVal = idx < uiState.savedMicGains.length
                          ? uiState.savedMicGains[idx]
                          : 0;
                      return _buildLabeledSlider(
                        label: l10n.vhfRadioMicrophoneN(idx + 1),
                        value: uiState.micGains[idx],
                        onChanged: (val) => _notifier.updateMicGain(idx, val),
                        onSave: () => _notifier.saveMicGain(idx),
                        isSaveEnabled:
                            uiState.micGains[idx].round() != savedVal,
                        isSaving: uiState.isSaving,
                        icon: Icons.mic,
                      );
                    }),
                  ],
                  const SizedBox(height: 16),
                ],

                const SizedBox(height: 16),
              ],
            ),
          ),
          if (uiState.isSaving)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}
