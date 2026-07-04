part of 'vhf_radio_dialog.dart';
// ignore_for_file: invalid_use_of_protected_member

extension _VhfRadioDialogAdvancedExt on _VhfRadioDialogState {
  Widget _buildAdvancedContent(BuildContext context) {
    final activeText = _activeController.text.trim();
    final isActiveChanged = (activeText != _savedActiveText || _activeNameController.text != _savedActiveName) &&
        RegExp(r'^\d{3}\.\d{3}$').hasMatch(activeText) &&
        _parseAviationFrequency(activeText) != null;

    final standbyText = _standbyController.text.trim();
    final isStandbyChanged = (standbyText != _savedStandbyText || _standbyNameController.text != _savedStandbyName) &&
        RegExp(r'^\d{3}\.\d{3}$').hasMatch(standbyText) &&
        _parseAviationFrequency(standbyText) != null;

    return BaseDetailsDialog(
      titleText: "Radio COM${widget.radioInstance + 1}",
      icon: Icons.radio,
      actions: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() => _showAdvancedMode = false),
          tooltip: "Späť na zoznam",
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
                if (_errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade400, width: 0.5),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 13),
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
                            enabled: !_isSaving,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: "Aktívna Frekvencia (MHz)",
                              hintText: "118.000",
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                            style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _activeNameController,
                            enabled: !_isSaving,
                            decoration: const InputDecoration(
                              labelText: "Meno aktívnej stanice",
                              hintText: "COM1 ACT",
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: (_isSaving || !isActiveChanged) ? null : _saveActive,
                            icon: const Icon(Icons.check, size: 14),
                            label: const Text("Použiť", style: TextStyle(fontSize: 11)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.green,
                              side: BorderSide(color: isActiveChanged ? Colors.green : Colors.grey.shade400),
                              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Flip/Swap button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 24.0),
                      child: IconButton(
                        icon: const Icon(Icons.swap_horiz, size: 28, color: Colors.blueAccent),
                        onPressed: _isSaving ? null : _flipFrequencies,
                        tooltip: "Prehodiť frekvencie",
                      ),
                    ),

                    // Standby Frequency block
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _standbyController,
                            enabled: !_isSaving,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: "Standby Frekvencia (MHz)",
                              hintText: "121.500",
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                            style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _standbyNameController,
                            enabled: !_isSaving,
                            decoration: const InputDecoration(
                              labelText: "Meno standby stanice",
                              hintText: "COM1 STB",
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: (_isSaving || !isStandbyChanged) ? null : _saveStandby,
                            icon: const Icon(Icons.check, size: 14),
                            label: const Text("Použiť", style: TextStyle(fontSize: 11)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.green,
                              side: BorderSide(color: isStandbyChanged ? Colors.green : Colors.grey.shade400),
                              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
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

                // Dual Watch Switch (Immediate Updates)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text("Dual Watch", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  value: _isDual,
                  onChanged: _isSaving ? null : _toggleDualWatch,
                ),

                const Divider(height: 24),

                // Audio Control Sliders with save buttons (collapsible)
                InkWell(
                  onTap: () => setState(() => _showAudioControls = !_showAudioControls),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                    child: Row(
                      children: [
                        Icon(
                          _showAudioControls ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          color: Colors.blueAccent,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _showAudioControls ? "Skryť nastavenia hlasitosti" : "Zobraziť nastavenia hlasitosti",
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

                if (_showAudioControls) ...[
                  const SizedBox(height: 12),
                  _buildLabeledSlider(
                    label: "Hlasitosť",
                    value: _volume,
                    onChanged: (val) => setState(() => _volume = val),
                    onSave: _saveVolume,
                    isSaveEnabled: _volume.round() != _savedVolume,
                    icon: Icons.volume_up,
                  ),
                  _buildLabeledSlider(
                    label: "Squelch (Šumová brána)",
                    value: _squelch,
                    onChanged: (val) => setState(() => _squelch = val),
                    onSave: _saveSquelch,
                    isSaveEnabled: _squelch.round() != _savedSquelch,
                    icon: Icons.filter_list,
                  ),
                  _buildLabeledSlider(
                    label: "VOX Citlivosť",
                    value: _vox,
                    onChanged: (val) => setState(() => _vox = val),
                    onSave: _saveVox,
                    isSaveEnabled: _vox.round() != _savedVox,
                    icon: Icons.keyboard_voice,
                  ),
                  _buildLabeledSlider(
                    label: "Intercom Hlasitosť",
                    value: _intercom,
                    onChanged: (val) => setState(() => _intercom = val),
                    onSave: _saveIntercom,
                    isSaveEnabled: _intercom.round() != _savedIntercom,
                    icon: Icons.people,
                  ),

                  // Microphones Gain Section with save buttons
                  if (_micGains.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Text("Mikrofóny (Gain)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    ...List.generate(_micGains.length, (idx) {
                      final isGainChanged = _micGains[idx].round() != (idx < _savedMicGains.length ? _savedMicGains[idx] : 0);
                      return _buildLabeledSlider(
                        label: "Mikrofón ${idx + 1}",
                        value: _micGains[idx],
                        onChanged: (val) => setState(() => _micGains[idx] = val),
                        onSave: () => _saveMicGain(idx),
                        isSaveEnabled: isGainChanged,
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
          if (_isSaving)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
