part of 'vhf_radio_dialog.dart';
// ignore_for_file: invalid_use_of_protected_member

extension _VhfRadioDialogQuickExt on _VhfRadioDialogState {
  Widget _buildQuickContent(BuildContext context) {
    final favoritesAsync = ref.watch(favoriteFrequenciesProvider);

    return BaseDetailsDialog(
        titleText: "Radio COM${widget.radioInstance + 1}",
        icon: Icons.radio,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              key: const ValueKey('vhf_dialog_quick_content'),
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

                  // Header showing Active & Standby
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        // Active
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "AKTÍVNA",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green.shade600,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _activeController.text.isEmpty ? "---.---" : "${_activeController.text} MHz",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                ),
                              ),
                              Text(
                                _activeNameController.text.isEmpty ? "Bez názvu" : _activeNameController.text,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        // Swap
                        IconButton(
                          icon: const Icon(Icons.swap_horiz, size: 28, color: Colors.blueAccent),
                          onPressed: _isSaving ? null : _flipFrequencies,
                          tooltip: "Prehodiť frekvencie",
                        ),
                        // Standby
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "STANDBY",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue.shade600,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _standbyController.text.isEmpty ? "---.---" : "${_standbyController.text} MHz",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                ),
                              ),
                              Text(
                                _standbyNameController.text.isEmpty ? "Bez názvu" : _standbyNameController.text,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Advanced Mode Button & Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Frekvencie v okolí",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      TextButton.icon(
                        onPressed: () => setState(() => _showAdvancedMode = true),
                        icon: const Icon(Icons.tune, size: 16),
                        label: const Text("Pokročilé / Ručne", style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  _buildSectionHeader("Letiská v okolí"),
                  if (_loadingAirports)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  else if (_nearbyAirports.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Text(
                        "Žiadne letiská v okolí",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    ..._nearbyAirports.map((entry) {
                      final apt = entry.key;
                      final distance = entry.value;
                      final distanceStr = (distance / 1000.0).toStringAsFixed(1);
                      final displayLabel = apt.icaoCode != null && apt.icaoCode!.isNotEmpty
                          ? "${apt.icaoCode} ${apt.name} ($distanceStr km)"
                          : "${apt.name} ($distanceStr km)";
                          
                      final freqs = apt.frequencies.map((f) {
                        final val = double.tryParse(f.value) ?? 0.0;
                        return _FrequencyInfo(val, f.name.isNotEmpty ? f.name : f.type.name);
                      }).where((f) => f.mhz > 0.0).toList();

                      return _buildAirportItem(displayLabel, freqs);
                    }),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionHeader("Obľúbené"),
                      TextButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => const ManageFavoritesDialog(),
                          );
                        },
                        icon: const Icon(Icons.edit, size: 14),
                        label: const Text("Spravovať", style: TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                  favoritesAsync.when(
                    data: (list) {
                      if (list.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            "Žiadne obľúbené frekvencie",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                      return Column(
                        children: list.map((f) => _buildSimpleFrequencyRow(f.name, f.mhz, f.name)).toList(),
                      );
                    },
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                    error: (err, stack) => Text("Chyba: $err"),
                  ),
                  const Divider(height: 16),
                  _buildSectionHeader("Priestory"),
                  if (_loadingAirspaces)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  else if (_nearbyAirspaces.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Text(
                        "Žiadne priestory v okolí",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    ..._nearbyAirspaces.map((entry) {
                      final asp = entry.key;
                      final distance = entry.value;
                      final distanceStr = distance == 0.0 ? "v priestore" : "${(distance / 1000.0).toStringAsFixed(1)} km";
                      final displayLabel = "${asp.name} ($distanceStr)";
                      
                      final freqs = asp.frequencies!.map((f) {
                        final val = double.tryParse(f.value) ?? 0.0;
                        return _FrequencyInfo(val, asp.name);
                      }).where((f) => f.mhz > 0.0).toList();

                      return _buildAirportItem(displayLabel, freqs);
                    }),
                  const SizedBox(height: 24),
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
