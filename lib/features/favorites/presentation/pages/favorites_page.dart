import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../map/presentation/components/dialogs/base_details_dialog.dart';
import '../../../map/presentation/providers/map_camera_provider.dart';
import '../../../navigation/presentation/providers/navigation_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../dialogs/add_favorite_dialog.dart';
import '../dialogs/favorite_details_dialog.dart';
import '../providers/favorites_provider.dart';

/// Lists all saved favourite points.
///
/// Each point can be shown on the map (centred in the map preview mode), added
/// to the navigation route, edited or deleted.
class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({super.key});

  Future<void> _showOnMap(
    BuildContext context,
    WidgetRef ref,
    FavoritePoint point,
  ) async {
    final settings = ref.read(appSettingsProvider).value;
    // The map is switched to the north-up overview state, so use the same
    // zoom as the overview map (mapOverviewZoom).
    final zoom = settings?.mapOverviewZoom ?? 10.0;
    // Return to the map page (root route) and centre the camera on the point
    // in the map preview (north-up overview) mode.
    context.go('/');
    await ref
        .read(mapCameraProvider.notifier)
        .focusOnPoint(
          latitude: point.latitude,
          longitude: point.longitude,
          zoom: zoom,
        );
  }

  Future<void> _addToNavigation(
    BuildContext context,
    WidgetRef ref,
    FavoritePoint point,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(navigationProvider.notifier)
          .addPoint(
            NavigationPoint(
              latitude: point.latitude,
              longitude: point.longitude,
              name: point.name,
            ),
          );
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.favoriteAddedToNavigation)),
      );
    } catch (e) {
      debugPrint('Failed to add favourite point to navigation: $e');
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.failedToAddNavigationPoint)),
      );
    }
  }

  Future<void> _editFavorite(
    BuildContext context,
    WidgetRef ref,
    FavoritePoint point,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final updated = await showAddFavoriteDialog(
      context,
      latitude: point.latitude,
      longitude: point.longitude,
      suggestedName: point.name,
      initialPoint: point,
    );
    if (updated != null) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.favoriteSaved)));
    }
  }

  Future<void> _deleteFavorite(
    BuildContext context,
    WidgetRef ref,
    FavoritePoint point,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => BaseDetailsDialog(
        titleText: l10n.delete,
        icon: Icons.delete_outline,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.favoriteDeleteConfirm(point.name)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(l10n.cancel),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(l10n.delete),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final result = await ref
        .read(favoritesProvider.notifier)
        .removeFavorite(point.id);
    if (result is FavoriteSaveFailure) {
      debugPrint('Failed to delete favourite point: ${result.error}');
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.favoriteFailedToSave)),
      );
    }
  }

  Widget _buildFavoriteTile(
    BuildContext context,
    WidgetRef ref,
    FavoritePoint point,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      elevation: 0,
      color: isDark
          ? scheme.surfaceContainerHighest.withAlpha(150)
          : scheme.surfaceContainerHighest.withAlpha(90),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        onTap: () => showFavoriteDetailsDialog(context, point),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: scheme.primary.withAlpha(28),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Image.asset(point.icon.assetPath, width: 30, height: 30),
        ),
        title: Text(
          point.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${point.latitude.toStringAsFixed(4)}, '
          '${point.longitude.toStringAsFixed(4)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        isThreeLine: false,
        trailing: PopupMenuButton<String>(
          tooltip: l10n.menu,
          onSelected: (value) {
            switch (value) {
              case 'show_on_map':
                _showOnMap(context, ref, point);
              case 'navigate':
                _addToNavigation(context, ref, point);
              case 'edit':
                _editFavorite(context, ref, point);
              case 'delete':
                _deleteFavorite(context, ref, point);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'show_on_map',
              child: Row(
                children: [
                  Icon(Icons.map_outlined, color: scheme.primary),
                  const SizedBox(width: 12),
                  Text(l10n.showOnMap),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'navigate',
              child: Row(
                children: [
                  Icon(Icons.navigation_outlined, color: scheme.primary),
                  const SizedBox(width: 12),
                  Text(l10n.addPointToNavigation),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit_outlined, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 12),
                  Text(l10n.edit),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, color: scheme.error),
                  const SizedBox(width: 12),
                  Text(l10n.delete),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star_outline, size: 72, color: scheme.primary),
            const SizedBox(height: 24),
            Text(
              l10n.favoritesEmptyTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.favoritesEmptyHint,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final favoritesAsync = ref.watch(favoritesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.favoritesTitle), centerTitle: true),
      body: favoritesAsync.when(
        data: (points) => points.isEmpty
            ? _buildEmptyState(context)
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: points.length,
                itemBuilder: (context, index) =>
                    _buildFavoriteTile(context, ref, points[index]),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text('${l10n.favoriteFailedToLoad}: $error')),
      ),
    );
  }
}
