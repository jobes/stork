import 'package:flutter/material.dart';
import '../controls/draggable_overlay.dart';

class BaseDetailsDialog extends StatelessWidget {
  final Widget? title;
  final String? titleText;
  final IconData? icon;
  final Widget? leading;
  final List<Widget>? actions;
  final Widget child;
  final double maxWidth;
  final double? maxHeight;

  /// Whether the default close button is shown when [actions] is `null`.
  ///
  /// Set to `false` for dialogs that require an explicit decision.
  final bool showCloseButton;

  const BaseDetailsDialog({
    super.key,
    this.title,
    this.titleText,
    this.icon,
    this.leading,
    this.actions,
    required this.child,
    this.maxWidth = 450,
    this.maxHeight,
    this.showCloseButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final Widget? leadingWidget =
        leading ??
        (icon != null
            ? Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: colors.primary, size: 24),
              )
            : null);

    final Widget titleWidget =
        title ??
        Text(
          titleText ?? '',
          style: theme.textTheme.titleLarge?.copyWith(color: colors.onSurface),
        );

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: DraggableOverlay(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth,
            maxHeight: maxHeight ?? double.infinity,
          ),
          child: Material(
            color: colors.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: colors.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DraggableOverlayGestureDetector(
                          child: Row(
                            children: [
                              if (leadingWidget != null) ...[
                                leadingWidget,
                                const SizedBox(width: 12),
                              ],
                              Expanded(child: titleWidget),
                            ],
                          ),
                        ),
                      ),
                      if (actions != null)
                        ...actions!
                      else if (showCloseButton)
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                          color: colors.onSurfaceVariant,
                        ),
                    ],
                  ),
                  const Divider(height: 24),
                  Flexible(child: SingleChildScrollView(child: child)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
