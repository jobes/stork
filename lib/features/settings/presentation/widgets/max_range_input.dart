import 'package:flutter/material.dart';

class MaxRangeInput extends StatelessWidget {
  final double currentValue;
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSubmitted;
  final VoidCallback onIncrement;
  final VoidCallback? onDecrement;

  const MaxRangeInput({
    super.key,
    required this.currentValue,
    required this.controller,
    required this.focusNode,
    required this.onSubmitted,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: onDecrement,
        ),
        SizedBox(
          width: 90,
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              suffixText: ' km/h',
              suffixStyle: TextStyle(fontSize: 12),
              contentPadding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => onSubmitted(),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: onIncrement,
        ),
      ],
    );
  }
}
