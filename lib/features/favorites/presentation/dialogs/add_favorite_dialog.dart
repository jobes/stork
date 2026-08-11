import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textf/textf.dart';
import 'package:uuid/uuid.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../map/domain/models/poi_type.dart';
import '../../../map/presentation/components/dialogs/base_details_dialog.dart';
import '../providers/favorites_provider.dart';

/// Dialog for creating a new favourite point.
///
/// Lets the user pick a POI icon, enter a name and a multi-line description
/// with live formatting (**bold**, *italic*) via `TextfEditingController`.
class AddFavoriteDialog extends ConsumerStatefulWidget {
  final double latitude;
  final double longitude;
  final String suggestedName;

  /// When provided the dialog edits this point instead of creating a new one.
  final FavoritePoint? initialPoint;

  const AddFavoriteDialog({
    super.key,
    required this.latitude,
    required this.longitude,
    this.suggestedName = '',
    this.initialPoint,
  });

  @override
  ConsumerState<AddFavoriteDialog> createState() => _AddFavoriteDialogState();
}

class _AddFavoriteDialogState extends ConsumerState<AddFavoriteDialog> {
  late PoiType _selectedIcon;
  late final TextEditingController _nameController;
  late final TextfEditingController _descriptionController;
  bool _nameError = false;
  bool _saving = false;

  bool get _isEditing => widget.initialPoint != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialPoint;
    _selectedIcon = initial?.icon ?? PoiType.viewpoint;
    _nameController = TextEditingController(
      text: initial?.name ?? widget.suggestedName,
    );
    _descriptionController = TextfEditingController(
      text: initial?.description ?? '',
      markerVisibility: MarkerVisibility.whenActive,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Wraps the current selection with [marker] (or inserts an empty pair when
  /// the selection is collapsed).
  void _applyFormatting(String marker) {
    final text = _descriptionController.text;
    final selection = _descriptionController.selection;
    setState(() {
      if (!selection.isValid || selection.isCollapsed) {
        final offset = selection.isValid ? selection.start : text.length;
        final updated = text.replaceRange(offset, offset, '$marker$marker');
        _descriptionController.value = TextEditingValue(
          text: updated,
          selection: TextSelection.collapsed(offset: offset + marker.length),
        );
        return;
      }
      final selected = selection.textInside(text);
      final updated = text.replaceRange(
        selection.start,
        selection.end,
        '$marker$selected$marker',
      );
      _descriptionController.value = TextEditingValue(
        text: updated,
        selection: TextSelection(
          baseOffset: selection.start + marker.length,
          extentOffset: selection.start + marker.length + selected.length,
        ),
      );
    });
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = true);
      return;
    }

    final initial = widget.initialPoint;
    final point = initial != null
        ? initial.copyWith(
            icon: _selectedIcon,
            name: name,
            description: _descriptionController.text.trim(),
          )
        : FavoritePoint(
            id: const Uuid().v4(),
            latitude: widget.latitude,
            longitude: widget.longitude,
            icon: _selectedIcon,
            name: name,
            description: _descriptionController.text.trim(),
          );

    setState(() => _saving = true);
    try {
      if (initial != null) {
        await ref.read(favoritesProvider.notifier).updateFavorite(point);
      } else {
        await ref.read(favoritesProvider.notifier).addFavorite(point);
      }
      if (!mounted) return;
      Navigator.of(context).pop(point);
    } catch (e) {
      debugPrint('Failed to add favourite point: $e');
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.favoriteFailedToSave),
        ),
      );
    }
  }

  Widget _buildIconChooser(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: PoiType.values.map((type) {
        final selected = type == _selectedIcon;
        return InkWell(
          onTap: () => setState(() => _selectedIcon = type),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? scheme.primary
                    : (isDark ? Colors.white24 : Colors.black12),
                width: selected ? 2 : 1,
              ),
              color: selected
                  ? scheme.primary.withAlpha(32)
                  : Colors.transparent,
            ),
            child: Image.asset(type.assetPath, width: 36, height: 36),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFormattingToolbar(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.format_bold),
          iconSize: 20,
          tooltip: AppLocalizations.of(context)!.favoriteFormatBold,
          onPressed: () => _applyFormatting('**'),
        ),
        IconButton(
          icon: const Icon(Icons.format_italic),
          iconSize: 20,
          tooltip: AppLocalizations.of(context)!.favoriteFormatItalic,
          onPressed: () => _applyFormatting('*'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final labelStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: scheme.onSurfaceVariant,
    );

    return BaseDetailsDialog(
      titleText: _isEditing ? l10n.favoriteEditTitle : l10n.favoritePointTitle,
      icon: Icons.star_border,
      maxHeight: 640,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.favoriteIconLabel, style: labelStyle),
          const SizedBox(height: 8),
          _buildIconChooser(context),
          const SizedBox(height: 16),
          Text(l10n.favoriteNameLabel, style: labelStyle),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            onChanged: (_) {
              if (_nameError) setState(() => _nameError = false);
            },
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: l10n.favoriteNameHint,
              errorText: _nameError ? l10n.pleaseEnterName : null,
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(l10n.favoriteDescriptionLabel, style: labelStyle),
          const SizedBox(height: 8),
          _buildFormattingToolbar(context),
          const SizedBox(height: 8),
          TextField(
            controller: _descriptionController,
            minLines: 3,
            maxLines: 6,
            maxLength: 500,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: l10n.favoriteDescriptionHint,
              alignLabelWithHint: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.favoriteFormattingHelp,
            style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.star),
            label: Text(l10n.save),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

/// Shows the add favourite point dialog and returns the created point when the
/// user saves it, or `null` when cancelled.
///
/// When [initialPoint] is provided the dialog edits that point instead of
/// creating a new one.
Future<FavoritePoint?> showAddFavoriteDialog(
  BuildContext context, {
  required double latitude,
  required double longitude,
  String suggestedName = '',
  FavoritePoint? initialPoint,
}) {
  return showDialog<FavoritePoint>(
    context: context,
    builder: (_) => AddFavoriteDialog(
      latitude: latitude,
      longitude: longitude,
      suggestedName: suggestedName,
      initialPoint: initialPoint,
    ),
  );
}
