import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../settings/presentation/providers/settings_provider.dart';
import 'draggable_widget.dart';

class MapWidgetWrapper extends ConsumerWidget {
  final String widgetId;
  final Widget child;
  final double defaultTop;
  final double defaultLeft;

  const MapWidgetWrapper({
    super.key,
    required this.widgetId,
    required this.child,
    this.defaultTop = 50.0,
    this.defaultLeft = 16.0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We only select the fields we care about to avoid unnecessary rebuilds
    final isDraggable = ref.watch(
      appSettingsProvider.select((s) => s.value?.areWidgetsDraggable ?? false),
    );
    final position = ref.watch(
      appSettingsProvider.select((s) => s.value?.widgetPositions[widgetId]),
    );

    return DraggableWidget(
      initialTop: position?.top ?? defaultTop,
      initialLeft: position?.left ?? defaultLeft,
      isDraggable: isDraggable,
      onDragEnd: (top, left) {
        ref
            .read(appSettingsProvider.notifier)
            .updateWidgetPosition(widgetId, top, left);
      },
      child: child,
    );
  }
}
