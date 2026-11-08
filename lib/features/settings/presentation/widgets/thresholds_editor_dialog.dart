import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';

class ThresholdsEditorDialog extends StatefulWidget {
  const ThresholdsEditorDialog({
    super.key,
    required this.title,
    required this.labels,
    required this.values,
    required this.min,
    required this.max,
    required this.unit,
    required this.decimalPlaces,
  });

  final String title;
  final List<String> labels;
  final List<double> values;
  final double min;
  final double max;
  final String unit;
  final int decimalPlaces;

  @override
  State<ThresholdsEditorDialog> createState() => _ThresholdsEditorDialogState();
}

class _ThresholdsEditorDialogState extends State<ThresholdsEditorDialog> {
  final _form = GlobalKey<FormState>();
  late final _numberFormat =
      NumberFormat.decimalPattern(
          Localizations.localeOf(context).toLanguageTag(),
        )
        ..turnOffGrouping()
        ..minimumFractionDigits = 0
        ..maximumFractionDigits = widget.decimalPlaces;
  late final _initialText = widget.values.map(_numberFormat.format).toList();
  late final _draft = List.of(_initialText);
  late final _numberPattern = RegExp(
    widget.decimalPlaces == 0
        ? r'^-?\d+$'
        : '^-?\\d+(?:[.,]\\d{1,${widget.decimalPlaces}})?\$',
  );

  double? _readValue(int index) {
    final text = _draft[index].trim();
    if (text == _initialText[index]) return widget.values[index];
    if (!_numberPattern.hasMatch(text)) return null;
    return double.tryParse(text.replaceAll(',', '.'));
  }

  String? _validate(int index, AppLocalizations l10n) {
    final value = _readValue(index);
    if (value == null || !value.isFinite) return l10n.thresholdValueInvalid;
    if (value < widget.min || value > widget.max) {
      return l10n.thresholdValueOutOfRange;
    }
    final previous = index == 0 ? null : _readValue(index - 1);
    if (previous != null && value < previous) return l10n.thresholdValuesOrder;
    return null;
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    Navigator.of(
      context,
    ).pop([for (var i = 0; i < _draft.length; i++) _readValue(i)!]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(widget.title),
      scrollable: true,
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < widget.values.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextFormField(
                  initialValue: _initialText[i],
                  keyboardType: TextInputType.numberWithOptions(
                    decimal: widget.decimalPlaces > 0,
                    signed: widget.min < 0,
                  ),
                  textInputAction: i == widget.values.length - 1
                      ? TextInputAction.done
                      : TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: widget.labels[i],
                    suffixText: widget.unit,
                    errorMaxLines: 2,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (text) => _draft[i] = text,
                  validator: (_) => _validate(i, l10n),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _save, child: Text(l10n.save)),
      ],
    );
  }
}
