import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/number_formatter.dart';

class NumberInput extends StatefulWidget {
  final double initialValue;
  final double min;
  final double max;
  final double step;
  final String suffix;
  final int decimalPlaces;
  final ValueChanged<double> onChanged;

  const NumberInput({
    super.key,
    required this.initialValue,
    required this.min,
    required this.max,
    required this.step,
    this.suffix = '',
    this.decimalPlaces = 0,
    required this.onChanged,
  });

  @override
  State<NumberInput> createState() => _NumberInputState();
}

class _NumberInputState extends State<NumberInput> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late double _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue;
    _controller = TextEditingController(
      text: context.formatNumber(_currentValue, widget.decimalPlaces),
    );
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(NumberInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue && !_focusNode.hasFocus) {
      setState(() {
        _currentValue = widget.initialValue;
        _controller.text = context.formatNumber(
          _currentValue,
          widget.decimalPlaces,
        );
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      _submit();
    }
  }

  void _submit() {
    final text = _controller.text;
    if (text == context.formatNumber(_currentValue, widget.decimalPlaces)) {
      return;
    }
    double? parsed;
    final localeStr = Localizations.localeOf(context).toString();
    try {
      parsed = NumberFormat.decimalPattern(localeStr).parse(text).toDouble();
    } catch (_) {
      parsed = double.tryParse(text.replaceAll(',', '.'));
    }
    if (parsed != null) {
      final clamped = parsed.clamp(widget.min, widget.max);
      setState(() {
        _currentValue = clamped;
        _controller.text = context.formatNumber(clamped, widget.decimalPlaces);
      });
      widget.onChanged(clamped);
    } else {
      setState(() {
        _controller.text = context.formatNumber(
          _currentValue,
          widget.decimalPlaces,
        );
      });
    }
  }

  void _handleIncrement() {
    final newValue = (_currentValue + widget.step).clamp(
      widget.min,
      widget.max,
    );
    setState(() {
      _currentValue = newValue;
      _controller.text = context.formatNumber(newValue, widget.decimalPlaces);
    });
    widget.onChanged(newValue);
  }

  void _handleDecrement() {
    final newValue = (_currentValue - widget.step).clamp(
      widget.min,
      widget.max,
    );
    setState(() {
      _currentValue = newValue;
      _controller.text = context.formatNumber(newValue, widget.decimalPlaces);
    });
    widget.onChanged(newValue);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: _currentValue > widget.min ? _handleDecrement : null,
        ),
        SizedBox(
          width: 90,
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            keyboardType: TextInputType.numberWithOptions(
              decimal: widget.decimalPlaces > 0,
            ),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              suffixText: widget.suffix,
              suffixStyle: const TextStyle(fontSize: 12),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 4.0,
                vertical: 8.0,
              ),
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) => _submit(),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: _currentValue < widget.max ? _handleIncrement : null,
        ),
      ],
    );
  }
}
