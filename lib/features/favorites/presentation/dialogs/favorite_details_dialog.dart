import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textf/textf.dart';

import '../../../../core/widgets/sprite_icon.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../map/presentation/components/dialogs/base_details_dialog.dart';
import '../providers/favorites_provider.dart';

/// Displays the details of a saved favourite point, including the rendered
/// (formatted) description.
class FavoriteDetailsDialog extends ConsumerWidget {
  final FavoritePoint point;

  const FavoriteDetailsDialog({super.key, required this.point});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    return BaseDetailsDialog(
      titleText: l10n.favoriteDetailsTitle,
      icon: Icons.star,
      actions: [
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
          color: isDark ? Colors.white70 : Colors.black54,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: scheme.primary.withAlpha(28),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: SpriteIcon(
                  frameId: point.icon.mapIconId,
                  width: 44,
                  height: 44,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      point.name,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${point.latitude.toStringAsFixed(4)}, '
                      '${point.longitude.toStringAsFixed(4)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 28),
          if (point.description.isEmpty)
            Text(
              l10n.favoriteDescriptionEmpty,
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: scheme.onSurfaceVariant,
              ),
            )
          else
            Textf(
              point.description,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
        ],
      ),
    );
  }
}

/// Shows the favourite point details dialog.
void showFavoriteDetailsDialog(BuildContext context, FavoritePoint point) {
  showDialog(
    context: context,
    builder: (_) => FavoriteDetailsDialog(point: point),
  );
}
