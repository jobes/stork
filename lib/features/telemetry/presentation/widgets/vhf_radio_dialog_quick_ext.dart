part of 'vhf_radio_dialog.dart';

extension _VhfRadioDialogQuickExt on _VhfRadioDialogState {
  Widget _buildQuickContent(
    BuildContext context,
    VhfRadioDialogUiState uiState,
  ) {
    final favoritesAsync = ref.watch(favoriteFrequenciesProvider);
    final nearbyAsync = ref.watch(nearbyFrequenciesProvider);

    final l10n = AppLocalizations.of(context)!;
    return BaseDetailsDialog(
      titleText: l10n.vhfRadioTitle(widget.radioInstance + 1),
      icon: Icons.radio,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            key: const ValueKey('vhf_dialog_quick_content'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (uiState.errorMessage != null)
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
                      uiState.errorMessage!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // Header showing Active & Standby
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).dividerColor.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Active
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.vhfRadioActive,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.green.shade600,
                                letterSpacing: 1.1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              uiState.activeFreqText.isEmpty
                                  ? '---.---'
                                  : '${uiState.activeFreqText} MHz',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                              ),
                            ),
                            Text(
                              uiState.activeNameText.isEmpty
                                  ? l10n.vhfRadioNoName
                                  : uiState.activeNameText,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Swap
                      IconButton(
                        icon: const Icon(
                          Icons.swap_horiz,
                          size: 28,
                          color: Colors.blueAccent,
                        ),
                        onPressed: uiState.isSaving
                            ? null
                            : () => _notifier.flipFrequencies(
                                currentActiveText: uiState.activeFreqText,
                                currentActiveName: uiState.activeNameText,
                                currentStandbyText: uiState.standbyFreqText,
                                currentStandbyName: uiState.standbyNameText,
                              ),
                        tooltip: l10n.vhfRadioSwapTooltip,
                      ),
                      // Standby
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              l10n.vhfRadioStandby,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade600,
                                letterSpacing: 1.1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              uiState.standbyFreqText.isEmpty
                                  ? '---.---'
                                  : '${uiState.standbyFreqText} MHz',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                              ),
                            ),
                            Text(
                              uiState.standbyNameText.isEmpty
                                  ? l10n.vhfRadioNoName
                                  : uiState.standbyNameText,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
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

                // Header row: Nearby Frequencies + Advanced Mode button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.vhfRadioNearbyFrequencies,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _notifier.toggleAdvancedMode(),
                      icon: const Icon(Icons.tune, size: 16),
                      label: Text(
                        l10n.vhfRadioAdvancedManual,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                _buildSectionHeader(l10n.vhfRadioNearbyAirports),
                ...nearbyAsync.when(
                  data: (nearbyState) {
                    final airports = nearbyState.nearbyAirports;
                    if (airports.isEmpty) {
                      return [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          child: Text(
                            l10n.vhfRadioNoAirportsNearby,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ];
                    }
                    return airports.map((entry) {
                      final apt = entry.key;
                      final distance = entry.value;
                      final distanceStr = (distance / 1000.0).toStringAsFixed(
                        1,
                      );
                      final displayLabel =
                          apt.icaoCode != null && apt.icaoCode!.isNotEmpty
                          ? '${apt.icaoCode} ${apt.name} ($distanceStr km)'
                          : '${apt.name} ($distanceStr km)';

                      final freqs = apt.frequencies
                          .map((f) {
                            final val = double.tryParse(f.value) ?? 0.0;
                            return _FrequencyInfo(
                              val,
                              f.name.isNotEmpty ? f.name : f.type.name,
                            );
                          })
                          .where((f) => f.mhz > 0.0)
                          .toList();

                      return _buildAirportItem(displayLabel, freqs);
                    });
                  },
                  loading: () => [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                  ],
                  error: (err, stack) => [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Text(
                        'Error: $err',
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ],
                ),

                const Divider(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSectionHeader(l10n.vhfRadioFavourites),
                    TextButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => const ManageFavoritesDialog(),
                        );
                      },
                      icon: const Icon(Icons.edit, size: 14),
                      label: Text(
                        l10n.vhfRadioManage,
                        style: const TextStyle(fontSize: 12),
                      ),
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
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          l10n.vhfRadioNoFavoriteFrequencies,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                    return Column(
                      children: list
                          .map(
                            (f) =>
                                _buildSimpleFrequencyRow(f.name, f.mhz, f.name),
                          )
                          .toList(),
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
                  error: (err, stack) => Text('Error: $err'),
                ),

                const Divider(height: 16),

                _buildSectionHeader(l10n.vhfRadioAirspaces),
                ...nearbyAsync.when(
                  data: (nearbyState) {
                    final airspaces = nearbyState.nearbyAirspaces;
                    if (airspaces.isEmpty) {
                      return [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          child: Text(
                            l10n.vhfRadioNoAirspacesNearby,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ];
                    }
                    return airspaces.map((entry) {
                      final asp = entry.key;
                      final distance = entry.value;
                      final distanceStr = distance == 0.0
                          ? l10n.vhfRadioInside
                          : '${(distance / 1000.0).toStringAsFixed(1)} km';
                      final displayLabel = '${asp.name} ($distanceStr)';

                      final freqs = asp.frequencies!
                          .map((f) {
                            final val = double.tryParse(f.value) ?? 0.0;
                            return _FrequencyInfo(val, asp.name);
                          })
                          .where((f) => f.mhz > 0.0)
                          .toList();

                      return _buildAirportItem(displayLabel, freqs);
                    });
                  },
                  loading: () => [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                  ],
                  error: (err, stack) => [],
                ),

                const SizedBox(height: 24),
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
