import 'package:flutter/material.dart';

class DraggableWidget extends StatefulWidget {
  final Widget child;
  final double initialTop;
  final double initialLeft;
  final bool isDraggable;
  final void Function(double top, double left) onDragEnd;

  const DraggableWidget({
    super.key,
    required this.child,
    required this.initialTop,
    required this.initialLeft,
    required this.isDraggable,
    required this.onDragEnd,
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

  /// Synchronously constrains positions during active user dragging
  void _constrainPositionsLocally() {
    final context = _key.currentContext;
    if (context == null) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;

    final size = box.size;
    final screenSize = MediaQuery.of(context).size;

    if (_left < 0) {
      _left = 0;
    }
    if (_top < 0) {
      _top = 0;
    }
    if (_left + size.width > screenSize.width) {
      _left = screenSize.width - size.width;
      if (_left < 0) _left = 0;
    }
    if (_top + size.height > screenSize.height) {
      _top = screenSize.height - size.height;
      if (_top < 0) _top = 0;
    }
  }

  /// Asynchronously resolves boundaries post-frame to ensure rendering completes
  void _constrainToBounds({bool saveAfterConstrain = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final context = _key.currentContext;
      if (context == null) return;
      final box = context.findRenderObject() as RenderBox?;
      if (box == null) return;

      final size = box.size;
      final screenSize = MediaQuery.of(context).size;

      bool changed = false;
      double newTop = _top;
      double newLeft = _left;

      if (newLeft < 0) {
        newLeft = 0;
        changed = true;
      }
      if (newTop < 0) {
        newTop = 0;
        changed = true;
      }
      if (newLeft + size.width > screenSize.width) {
        newLeft = screenSize.width - size.width;
        if (newLeft < 0) newLeft = 0;
        changed = true;
      }
      if (newTop + size.height > screenSize.height) {
        newTop = screenSize.height - size.height;
        if (newTop < 0) newTop = 0;
        changed = true;
      }

      if (changed) {
        setState(() {
          _top = newTop;
          _left = newLeft;
        });
      }

      if (saveAfterConstrain && widget.isDraggable) {
        widget.onDragEnd(_top, _left);
      } else if (changed && widget.isDraggable) {
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

    Widget content = Container(key: _key, child: widget.child);

    if (widget.isDraggable) {
      // Draw an elegant "edit/move mode" glow border with a small floating indicator handle
      content = Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isDragging
                    ? (isDark ? Colors.blueAccent : Colors.blue)
                    : (isDark ? Colors.white24 : Colors.black12),
                width: 1.5,
              ),
              color: _isDragging
                  ? (isDark
                        ? Colors.blue.withAlpha(25)
                        : Colors.blue.withAlpha(15))
                  : Colors.transparent,
            ),
            child: content,
          ),
          Positioned(
            top: -6,
            right: -6,
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
      );
    }

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
                setState(() {
                  _top += details.delta.dy;
                  _left += details.delta.dx;
                  _constrainPositionsLocally();
                });
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
        child: AnimatedScale(
          scale: _isDragging ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          child: AnimatedOpacity(
            opacity: _isDragging ? 0.85 : 1.0,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            child: content,
          ),
        ),
      ),
    );
  }
}
