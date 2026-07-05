import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/favorite_frequencies_provider.dart';
import '../../../map/presentation/components/dialogs/base_details_dialog.dart';

class ManageFavoritesDialog extends ConsumerStatefulWidget {
  const ManageFavoritesDialog({super.key});

  @override
  ConsumerState<ManageFavoritesDialog> createState() =>
      _ManageFavoritesDialogState();
}

class _ManageFavoritesDialogState extends ConsumerState<ManageFavoritesDialog> {
  final _formKey = GlobalKey<FormState>();
  final _freqController = TextEditingController();
  final _nameController = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _freqController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  double? _parseAndValidateFrequency(String text) {
    final trimmed = text.trim();
    if (!RegExp(r'^\d{3}\.\d{3}$').hasMatch(trimmed)) return null;

    final double? mhz = double.tryParse(trimmed);
    if (mhz == null) return null;
    if (mhz < 118.000 || mhz > 136.995) return null;

    final int totalKhzRounded = (mhz * 1000).round();
    final int offset = totalKhzRounded % 100;

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

    if (!validAviationOffsets.contains(offset)) {
      return null;
    }

    return mhz;
  }

  void _addFavorite() {
    setState(() {
      _errorText = null;
    });

    final freqVal = _parseAndValidateFrequency(_freqController.text);
    if (freqVal == null) {
      setState(() {
        _errorText = AppLocalizations.of(context)!.manageFavoritesInvalidFreq;
      });
      return;
    }

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _errorText = AppLocalizations.of(context)!.manageFavoritesNameRequired;
      });
      return;
    }

    ref.read(favoriteFrequenciesProvider.notifier).addFavorite(freqVal, name);
    _freqController.clear();
    _nameController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final favoritesAsync = ref.watch(favoriteFrequenciesProvider);

    final l10n = AppLocalizations.of(context)!;
    return BaseDetailsDialog(
      titleText: l10n.manageFavoritesTitle,
      icon: Icons.star,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section to add new favorite
          Text(
            l10n.manageFavoritesAddNew,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Form(
            key: _formKey,
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 4,
                      child: TextField(
                        controller: _freqController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: l10n.manageFavoritesFreqLabel,
                          hintText: l10n.manageFavoritesFreqHint,
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                        ),
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 6,
                      child: TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: l10n.manageFavoritesNameLabel,
                          hintText: l10n.manageFavoritesNameHint,
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                        ),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
                if (_errorText != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _errorText!,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _addFavorite,
                  icon: const Icon(Icons.add, size: 16),
                  label: Text(l10n.manageFavoritesAddToList),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(36),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 24),

          Text(
            l10n.manageFavoritesListTitle,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),

          favoritesAsync.when(
            data: (list) {
              if (list.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Text(
                    l10n.manageFavoritesEmpty,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                );
              }

              return ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: list.length,
                onReorderItem: (oldIndex, newIndex) {
                  ref
                      .read(favoriteFrequenciesProvider.notifier)
                      .reorderFavorites(oldIndex, newIndex);
                },
                itemBuilder: (context, index) {
                  final item = list[index];
                  return Card(
                    key: ValueKey(
                      item.mhz.toString() + item.name + index.toString(),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: Theme.of(
                          context,
                        ).dividerColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.only(left: 12, right: 4),
                      title: Text(
                        item.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      subtitle: Text(
                        '${item.mhz.toStringAsFixed(3)} MHz',
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: Colors.grey,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ReorderableDragStartListener(
                            index: index,
                            child: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Icon(
                                Icons.drag_handle,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                            ),
                            onPressed: () {
                              ref
                                  .read(favoriteFrequenciesProvider.notifier)
                                  .removeFavorite(index);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (err, stack) =>
                Text(l10n.manageFavoritesLoadError(err.toString())),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
