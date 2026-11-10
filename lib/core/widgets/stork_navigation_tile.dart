import 'package:flutter/material.dart';

/// A destination with a consistent icon, type and touch target.
class StorkNavigationTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool highlighted;

  const StorkNavigationTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.onTap,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final foreground = highlighted
        ? colors.onPrimaryContainer
        : colors.onSurface;
    final secondary = highlighted
        ? colors.onPrimaryContainer.withValues(alpha: 0.75)
        : colors.onSurfaceVariant;

    return ListTile(
      minTileHeight: 52,
      minLeadingWidth: 24,
      minVerticalPadding: 8,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      tileColor: highlighted ? colors.primaryContainer : null,
      iconColor: secondary,
      leading: Icon(icon, size: 22),
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(color: foreground),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(color: secondary),
            ),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
