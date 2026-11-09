import 'dart:math' as math;

import 'package:flutter/material.dart';

class DraggableWidget extends StatefulWidget {
  final Widget child;
  final double initialTop;
  final double initialLeft;
  final bool isDraggable;
  final Iterable<Rect> Function()? dragObstacles;
  final void Function(double top, double left) onDragEnd;

  const DraggableWidget({
    super.key,
    required this.child,
    required this.initialTop,
    required this.initialLeft,
    required this.isDraggable,
    required this.onDragEnd,
    this.dragObstacles,
  });

  @override
  State<DraggableWidget> createState() => _DraggableWidgetState();
}

class _DraggableWidgetState extends State<DraggableWidget>
    with WidgetsBindingObserver {
  late double _top;
  late double _left;
  bool _isDragging = false;
  Size? _lastScreenSize;
  final GlobalKey _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    _top = widget.initialTop;
    _left = widget.initialLeft;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didUpdateWidget(DraggableWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Listen to external resets (e.g. initial positions changed from default settings)
    if (widget.initialTop != oldWidget.initialTop ||
        widget.initialLeft != oldWidget.initialLeft) {
      setState(() {
        _top = widget.initialTop;
        _left = widget.initialLeft;
        _lastScreenSize = null; // Force re-constrain bounds on the next build
      });
    } else if (oldWidget.isDraggable && !widget.isDraggable) {
      // Snaps the widget back to settings position when dragging gets disabled
      setState(() {
        _top = widget.initialTop;
        _left = widget.initialLeft;
        _lastScreenSize = null;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    if (!widget.isDraggable) {
      if (_top != widget.initialTop || _left != widget.initialLeft) {
        setState(() {
          _top = widget.initialTop;
          _left = widget.initialLeft;
        });
      }
    }
    // Force re-constrain bounds since physical viewport dimensions changed
    _lastScreenSize = null;
    _constrainToBounds();
  }

  Offset _boundedPosition(Offset position, Size size, Size screenSize) {
    return Offset(
      position.dx.clamp(0.0, math.max(0.0, screenSize.width - size.width)),
      position.dy.clamp(0.0, math.max(0.0, screenSize.height - size.height)),
    );
  }

  void _move(Offset delta) {
    final context = _key.currentContext;
    final box = context?.findRenderObject();
    if (context == null || box is! RenderBox || !box.hasSize) return;

    final current = Offset(_left, _top);
    final screen = MediaQuery.sizeOf(context);
    final target = _boundedPosition(current + delta, box.size, screen);
    final obstacles = widget.dragObstacles?.call().toList() ?? const <Rect>[];
    final rect = current & box.size;

    // Resolve each axis separately so a diagonal drag can slide along an edge.
    final dx = _limitMovement(
      rect,
      target.dx - current.dx,
      obstacles,
      horizontal: true,
      extent: screen.width,
    );
    final dy = _limitMovement(
      rect.shift(Offset(dx, 0)),
      target.dy - current.dy,
      obstacles,
      horizontal: false,
      extent: screen.height,
    );
    _left += dx;
    _top += dy;
  }

  double _limitMovement(
    Rect rect,
    double delta,
    List<Rect> obstacles, {
    required bool horizontal,
    required double extent,
  }) {
    if (delta == 0) return 0;
    final (start, end) = horizontal
        ? (rect.left, rect.right)
        : (rect.top, rect.bottom);
    for (final obstacle in obstacles) {
      final sharesLane = horizontal
          ? rect.top < obstacle.bottom && rect.bottom > obstacle.top
          : rect.left < obstacle.right && rect.right > obstacle.left;
      if (!sharesLane) continue;

      final (near, far) = horizontal
          ? (obstacle.left, obstacle.right)
          : (obstacle.top, obstacle.bottom);
      if (delta > 0 && end <= near) {
        delta = math.min(delta, near - end);
      } else if (delta < 0 && start >= far) {
        delta = math.max(delta, far - start);
      } else if (start < far && end > near) {
        // A saved layout or a resize can start with an overlap. Let it exit
        // along the nearer edge without allowing it to move farther in.
        final exitForward = far - start;
        final exitBackward = end - near;
        final canExitForward = end + exitForward <= extent;
        final canExitBackward = start - exitBackward >= 0;
        if ((delta > 0 &&
                canExitBackward &&
                (!canExitForward || exitForward > exitBackward)) ||
            (delta < 0 &&
                canExitForward &&
                (!canExitBackward || exitBackward > exitForward))) {
          return 0;
        }
      }
    }
    return delta;
  }

  /// Resolves screen bounds after layout, when the widget has its final size.
  void _constrainToBounds({bool saveAfterConstrain = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final context = _key.currentContext;
      final box = context?.findRenderObject();
      if (context == null || box is! RenderBox || !box.hasSize) return;

      final current = Offset(_left, _top);
      final bounded = _boundedPosition(
        current,
        box.size,
        MediaQuery.sizeOf(context),
      );
      final changed = bounded != current;
      if (changed) {
        setState(() {
          _top = bounded.dy;
          _left = bounded.dx;
        });
      }

      if (widget.isDraggable && (saveAfterConstrain || changed)) {
        widget.onDragEnd(_top, _left);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    // Check bounds only when screen dimensions/orientation actually change to protect CPU & frames
    if (_lastScreenSize != screenSize) {
      _lastScreenSize = screenSize;
      _constrainToBounds();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    const editBorderWidth = 1.5;
    const editOutset = 4.0 + editBorderWidth;
    final content = Stack(
      clipBehavior: Clip.none,
      children: [
        Container(key: _key, child: widget.child),
        // Keep the edit decoration outside the widget's layout and drag bounds.
        if (widget.isDraggable) ...[
          Positioned(
            top: -editOutset,
            left: -editOutset,
            right: -editOutset,
            bottom: -editOutset,
            child: IgnorePointer(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isDragging
                        ? (isDark ? Colors.blueAccent : Colors.blue)
                        : (isDark ? Colors.white24 : Colors.black12),
                    width: editBorderWidth,
                  ),
                  color: _isDragging
                      ? (isDark
                            ? Colors.blue.withAlpha(25)
                            : Colors.blue.withAlpha(15))
                      : Colors.transparent,
                ),
              ),
            ),
          ),
          Positioned(
            top: -editOutset - 6,
            right: -editOutset - 6,
            child: AnimatedScale(
              scale: _isDragging ? 1.25 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: _isDragging
                      ? (isDark ? Colors.blueAccent : Colors.blue)
                      : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(40),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.open_with,
                  size: 12,
                  color: _isDragging
                      ? Colors.white
                      : (isDark ? Colors.white70 : Colors.black87),
                ),
              ),
            ),
          ),
        ],
      ],
    );

    return Positioned(
      top: _top,
      left: _left,
      child: GestureDetector(
        onPanStart: widget.isDraggable
            ? (details) {
                setState(() {
                  _isDragging = true;
                });
              }
            : null,
        onPanUpdate: widget.isDraggable
            ? (details) {
                setState(() => _move(details.delta));
              }
            : null,
        onPanEnd: widget.isDraggable
            ? (details) {
                setState(() {
                  _isDragging = false;
                });
                _constrainToBounds(saveAfterConstrain: true);
              }
            : null,
        onPanCancel: widget.isDraggable
            ? () {
                setState(() {
                  _isDragging = false;
                });
                _constrainToBounds();
              }
            : null,
        child: content,
      ),
    );
  }
}
