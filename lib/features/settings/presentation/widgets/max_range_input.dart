import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context)!;
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
            decoration: InputDecoration(
              suffixText: l10n.speedSuffix,
              suffixStyle: const TextStyle(fontSize: 12),
              contentPadding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
              border: const OutlineInputBorder(),
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
