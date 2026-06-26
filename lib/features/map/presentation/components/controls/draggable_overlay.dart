import 'package:flutter/material.dart';

class DraggableOverlay extends StatefulWidget {
  final Widget child;
  final bool barrierDismissible;

  const DraggableOverlay({
    super.key,
    required this.child,
    this.barrierDismissible = true,
  });

  static DraggableOverlayState? of(BuildContext context) {
    return context.findAncestorStateOfType<DraggableOverlayState>();
  }

  @override
  State<DraggableOverlay> createState() => DraggableOverlayState();
}

class DraggableOverlayState extends State<DraggableOverlay> {
  Offset _offset = Offset.zero;
  final GlobalKey _childKey = GlobalKey();

  void addOffset(Offset delta) {
    setState(() {
      _offset += delta;
      _constrainOffsetDirectly();
    });
  }

  void _constrainOffsetDirectly() {
    final context = _childKey.currentContext;
    if (context == null) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    final overlaySize = box.size;
    final screenSize = MediaQuery.sizeOf(context);

    final maxDx = ((screenSize.width - overlaySize.width) / 2).clamp(
      0.0,
      double.infinity,
    );
    final maxDy = ((screenSize.height - overlaySize.height) / 2).clamp(
      0.0,
      double.infinity,
    );

    _offset = Offset(
      _offset.dx.clamp(-maxDx, maxDx),
      _offset.dy.clamp(-maxDy, maxDy),
    );
  }

  void _constrainOffsetPostFrame() {
    final oldOffset = _offset;
    _constrainOffsetDirectly();
    if (_offset != oldOffset) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _constrainOffsetPostFrame();
      }
    });

    return SizedBox.expand(
      child: Stack(
        children: [
          if (widget.barrierDismissible)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).pop(),
              child: const SizedBox.expand(),
            ),
          Transform.translate(
            offset: _offset,
            child: Center(
              child: Container(key: _childKey, child: widget.child),
            ),
          ),
        ],
      ),
    );
  }
}

class DraggableOverlayGestureDetector extends StatefulWidget {
  final Widget child;

  const DraggableOverlayGestureDetector({super.key, required this.child});

  @override
  State<DraggableOverlayGestureDetector> createState() =>
      _DraggableOverlayGestureDetectorState();
}

class _DraggableOverlayGestureDetectorState
    extends State<DraggableOverlayGestureDetector> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanStart: (_) => setState(() => _isDragging = true),
      onPanUpdate: (details) {
        DraggableOverlay.of(context)?.addOffset(details.delta);
      },
      onPanEnd: (_) => setState(() => _isDragging = false),
      onPanCancel: () => setState(() => _isDragging = false),
      child: MouseRegion(
        cursor: _isDragging
            ? SystemMouseCursors.grabbing
            : SystemMouseCursors.grab,
        child: widget.child,
      ),
    );
  }
}
