import 'dart:ui';
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
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Widget? leadingWidget = leading ??
        (icon != null
            ? Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withAlpha(40),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: Colors.blueAccent,
                  size: 24,
                ),
              )
            : null);

    final Widget titleWidget = title ??
        Text(
          titleText ?? '',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        );

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: DraggableOverlay(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              constraints: BoxConstraints(
                maxWidth: maxWidth,
                maxHeight: maxHeight ?? double.infinity,
              ),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withAlpha(190)
                    : Colors.white.withAlpha(225),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? Colors.white24 : Colors.black12,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(80),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
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
                      else
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                    ],
                  ),
                  const Divider(height: 24),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
