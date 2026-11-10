import 'package:flutter/material.dart';

/// Shared neutral surface for detail dialogs (flight, navigation and settings).
///
/// Only generic chrome belongs here. Warning and critical instrument colors
/// remain owned by the feature and are never remapped to the brand primary.
class StorkDetailSurface extends StatelessWidget {
  const StorkDetailSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.radius = 14,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: child,
    );
  }
}
