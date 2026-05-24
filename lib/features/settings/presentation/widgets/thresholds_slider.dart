import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/range_thresholds.dart';
import '../threshold_state_extension.dart';


class ThresholdsSlider extends StatefulWidget {
  final List<double> values;
  final double min;
  final double max;
  final ThresholdState Function(double) evaluate;
  final ValueChanged<List<double>> onChanged;

  const ThresholdsSlider({
    super.key,
    required this.values,
    required this.min,
    required this.max,
    required this.evaluate,
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
    double rawValue = widget.min + fraction * (widget.max - widget.min);

    // Dynamically transfer active thumb if we are trying to drag an overlapping stack
    double diff = rawValue - _currentValues[_activeThumbIndex!];
    if (diff > 0) {
      // Dragging right: pick the rightmost thumb in the overlapping group
      while (_activeThumbIndex! < _currentValues.length - 1 &&
          _currentValues[_activeThumbIndex! + 1] == _currentValues[_activeThumbIndex!]) {
        _activeThumbIndex = _activeThumbIndex! + 1;
      }
    } else if (diff < 0) {
      // Dragging left: pick the leftmost thumb in the overlapping group
      while (_activeThumbIndex! > 0 &&
          _currentValues[_activeThumbIndex! - 1] == _currentValues[_activeThumbIndex!]) {
        _activeThumbIndex = _activeThumbIndex! - 1;
      }
    }

    // Enforce limits from neighbors (they can touch but not overlap/cross)
    final double minVal = _activeThumbIndex! > 0
        ? _currentValues[_activeThumbIndex! - 1]
        : widget.min;
    final double maxVal = _activeThumbIndex! < _currentValues.length - 1
        ? _currentValues[_activeThumbIndex! + 1]
        : widget.max;

    final double clampedValue = rawValue.clamp(minVal, maxVal).roundToDouble();

    if (_currentValues[_activeThumbIndex!] != clampedValue) {
      setState(() {
        _currentValues[_activeThumbIndex!] = clampedValue;
      });
      widget.onChanged(List.from(_currentValues));
    }
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
                evaluate: widget.evaluate,
                activeThumbIndex: _activeThumbIndex,
                textColor: Theme.of(context).colorScheme.onSurface,
                context: context,
                localeTag: Localizations.localeOf(context).toLanguageTag(),
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
  final ThresholdState Function(double) evaluate;
  final int? activeThumbIndex;
  final Color textColor;
  final BuildContext context;
  final String localeTag;

  _MultiThumbPainter({
    required this.values,
    required this.min,
    required this.max,
    required this.evaluate,
    required this.activeThumbIndex,
    required this.textColor,
    required this.context,
    required this.localeTag,
  });

  @override
  void paint(Canvas canvas, Size size) {
    double previousDx = 0;
    for (int i = 0; i <= values.length; i++) {
      final double nextDx = i < values.length
          ? ((values[i] - min) / (max - min)) * size.width
          : size.width;

      final double midVal = min + ((previousDx + nextDx) / 2 / size.width) * (max - min);
      final Color regionColor = evaluate(midVal).color;

      final trackPaint = Paint()
        ..color = regionColor
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
      final String text =
          '${values[i].toStringAsFixed(0)}\n${AppLocalizations.of(context)!.speedUnitKmH}';
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
    return !listEquals(oldDelegate.values, values) ||
        oldDelegate.min != min ||
        oldDelegate.max != max ||
        oldDelegate.evaluate != evaluate ||
        oldDelegate.activeThumbIndex != activeThumbIndex ||
        oldDelegate.textColor != textColor ||
        oldDelegate.localeTag != localeTag;
  }
}
