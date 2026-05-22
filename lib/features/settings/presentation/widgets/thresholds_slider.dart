import 'package:flutter/material.dart';

class ThresholdsSlider extends StatefulWidget {
  final List<double> values;
  final double min;
  final double max;
  final ValueChanged<List<double>> onChanged;

  const ThresholdsSlider({
    super.key,
    required this.values,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  State<ThresholdsSlider> createState() => _ThresholdsSliderState();
}

class _ThresholdsSliderState extends State<ThresholdsSlider> {
  int? _activeThumbIndex;
  late List<double> _currentValues;

  @override
  void initState() {
    super.initState();
    _currentValues = List.from(widget.values);
  }

  @override
  void didUpdateWidget(ThresholdsSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    _currentValues = List.from(widget.values);
  }

  void _handlePanStart(DragStartDetails details, BoxConstraints constraints) {
    final double fraction = (details.localPosition.dx / constraints.maxWidth)
        .clamp(0.0, 1.0);
    final double value = widget.min + fraction * (widget.max - widget.min);

    double minDistance = double.infinity;
    int closestIndex = -1;
    for (int i = 0; i < _currentValues.length; i++) {
      final double distance = (value - _currentValues[i]).abs();
      if (distance < minDistance) {
        minDistance = distance;
        closestIndex = i;
      }
    }

    // Touch slop (e.g. only select if within some distance), but since they want to drag,
    // closest is usually fine.
    _activeThumbIndex = closestIndex;
  }

  void _handlePanUpdate(DragUpdateDetails details, BoxConstraints constraints) {
    if (_activeThumbIndex == null) return;

    final double fraction = (details.localPosition.dx / constraints.maxWidth)
        .clamp(0.0, 1.0);
    double value = widget.min + fraction * (widget.max - widget.min);

    // Enforce limits from neighbors (they can touch but not overlap/cross)
    final double minVal = _activeThumbIndex! > 0
        ? _currentValues[_activeThumbIndex! - 1]
        : widget.min;
    final double maxVal = _activeThumbIndex! < _currentValues.length - 1
        ? _currentValues[_activeThumbIndex! + 1]
        : widget.max;

    value = value.clamp(minVal, maxVal).roundToDouble();

    setState(() {
      _currentValues[_activeThumbIndex!] = value;
    });

    widget.onChanged(List.from(_currentValues));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (details) => _handlePanStart(details, constraints),
          onPanUpdate: (details) => _handlePanUpdate(details, constraints),
          onPanEnd: (_) => setState(() {
            _activeThumbIndex = null;
          }),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: CustomPaint(
              size: const Size(double.infinity, 60),
              painter: _MultiThumbPainter(
                values: _currentValues,
                min: widget.min,
                max: widget.max,
                activeThumbIndex: _activeThumbIndex,
                textColor: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MultiThumbPainter extends CustomPainter {
  final List<double> values;
  final double min;
  final double max;
  final int? activeThumbIndex;
  final Color textColor;

  _MultiThumbPainter({
    required this.values,
    required this.min,
    required this.max,
    required this.activeThumbIndex,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 6 regions for 5 thumbs
    final colors = [
      Colors.grey, // Inactive
      Colors.red, // Min Error
      Colors.orange, // Min Warning
      Colors.green, // Operational
      Colors.orange, // Max Warning
      Colors.red, // Max Error
    ];

    double previousDx = 0;
    for (int i = 0; i <= values.length; i++) {
      final double nextDx = i < values.length
          ? ((values[i] - min) / (max - min)) * size.width
          : size.width;

      final trackPaint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.fill;

      // Draw segment of the track
      final rect = Rect.fromLTRB(
        previousDx,
        size.height / 2 - 4,
        nextDx,
        size.height / 2 + 4,
      );

      if (i == 0) {
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            rect,
            topLeft: const Radius.circular(4),
            bottomLeft: const Radius.circular(4),
          ),
          trackPaint,
        );
      } else if (i == values.length) {
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            rect,
            topRight: const Radius.circular(4),
            bottomRight: const Radius.circular(4),
          ),
          trackPaint,
        );
      } else {
        canvas.drawRect(rect, trackPaint);
      }
      previousDx = nextDx;
    }

    final shadowPaint = Paint()
      ..color = Colors.black.withAlpha(50)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < values.length; i++) {
      final double fraction = (values[i] - min) / (max - min);
      final double dx = fraction * size.width;
      final Offset center = Offset(dx, size.height / 2);

      // Thumbs
      final isThumbActive = activeThumbIndex == i;
      final radius = isThumbActive ? 14.0 : 10.0;

      final thumbPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      final borderPaint = Paint()
        ..color = Colors.grey.shade400
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      canvas.drawCircle(center + const Offset(0, 2), radius, shadowPaint);
      canvas.drawCircle(center, radius, thumbPaint);
      canvas.drawCircle(center, radius, borderPaint);

      // Text
      final String text = '${values[i].toStringAsFixed(0)}\nkm/h';
      final textSpan = TextSpan(
        text: text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: isThumbActive ? FontWeight.bold : FontWeight.normal,
          height: 1,
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      // Alternate above and below
      final double dyOffset = (i % 2 == 0) ? -38.0 : 18.0;
      textPainter.paint(
        canvas,
        center - Offset(textPainter.width / 2, -dyOffset),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MultiThumbPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.min != min ||
        oldDelegate.max != max ||
        oldDelegate.activeThumbIndex != activeThumbIndex ||
        oldDelegate.textColor != textColor;
  }
}
