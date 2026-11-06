import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stork/features/map/presentation/components/dialogs/base_details_dialog.dart';
import 'package:stork/l10n/app_localizations.dart';

import '../../domain/models/dronecan_parameter.dart';
import '../utils/dronecan_formatters.dart';

/// Lets the user edit the value of [parameter] within the bounds reported by
/// the node.
///
/// Returns the new value, or `null` when the dialog was dismissed.
Future<DroneCanParamValue?> showDroneCanParameterEditDialog(
  BuildContext context, {
  required DroneCanParameter parameter,
}) {
  return showDialog<DroneCanParamValue>(
    context: context,
    builder: (_) => _ParameterEditDialog(parameter: parameter),
  );
}

class _ParameterEditDialog extends StatefulWidget {
  const _ParameterEditDialog({required this.parameter});

  final DroneCanParameter parameter;

  @override
  State<_ParameterEditDialog> createState() => _ParameterEditDialogState();
}

class _ParameterEditDialogState extends State<_ParameterEditDialog> {
  late final TextEditingController _controller;
  late bool _booleanValue;
  String? _error;

  DroneCanParameter get parameter => widget.parameter;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: formatDroneCanParameterInput(parameter.value),
    );
    _booleanValue = parameter.value.booleanValue ?? false;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final dash = l10n.placeholderDash;

    return BaseDetailsDialog(
      titleText: l10n.dronecanParameterEditTitle,
      icon: Icons.edit_outlined,
      maxWidth: 380,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            parameter.name,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 12),
          _InfoRow(
            label: l10n.dronecanParameterTypeLabel,
            value: droneCanParameterTypeLabel(parameter.type, l10n),
          ),
          _InfoRow(
            label: l10n.dronecanParameterMinLabel,
            value: parameter.minValue == null
                ? dash
                : formatDroneCanNumber(parameter.minValue!),
          ),
          _InfoRow(
            label: l10n.dronecanParameterMaxLabel,
            value: parameter.maxValue == null
                ? dash
                : formatDroneCanNumber(parameter.maxValue!),
          ),
          _InfoRow(
            label: l10n.dronecanParameterDefaultLabel,
            value: parameter.defaultValue == null
                ? dash
                : formatDroneCanParameterValue(parameter.defaultValue!, l10n),
          ),
          const Divider(height: 24),
          if (parameter.type == DroneCanParamValueType.boolean)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.dronecanParameterValueLabel),
              value: _booleanValue,
              onChanged: (value) => setState(() => _booleanValue = value),
            )
          else
            TextField(
              controller: _controller,
              autofocus: true,
              keyboardType: switch (parameter.type) {
                DroneCanParamValueType.integer =>
                  const TextInputType.numberWithOptions(signed: true),
                DroneCanParamValueType.real =>
                  const TextInputType.numberWithOptions(
                    signed: true,
                    decimal: true,
                  ),
                _ => TextInputType.text,
              },
              inputFormatters: parameter.type.isNumeric
                  ? [FilteringTextInputFormatter.allow(RegExp(r'[-0-9.,eE+]'))]
                  : null,
              decoration: InputDecoration(
                labelText: l10n.dronecanParameterValueLabel,
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              onSubmitted: (_) => _submit(),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                _error!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          const SizedBox(height: 18),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.cancel),
              ),
              FilledButton(onPressed: _submit, child: Text(l10n.save)),
            ],
          ),
        ],
      ),
    );
  }

  void _submit() {
    final value = _parse();
    if (value == null) return;
    Navigator.of(context).pop(value);
  }

  DroneCanParamValue? _parse() {
    final l10n = AppLocalizations.of(context)!;
    final text = _controller.text.trim();

    switch (parameter.type) {
      case DroneCanParamValueType.boolean:
        return DroneCanParamValue.boolean(_booleanValue);
      case DroneCanParamValueType.string:
        final length = utf8.encode(text).length;
        if (length > DroneCanParameter.maxStringLength) {
          setState(
            () => _error = l10n.dronecanParameterStringTooLong(
              DroneCanParameter.maxStringLength,
            ),
          );
          return null;
        }
        return DroneCanParamValue.string(text);
      case DroneCanParamValueType.integer:
        final parsed = int.tryParse(text);
        if (parsed == null) {
          setState(() => _error = l10n.dronecanParameterInvalidInteger);
          return null;
        }
        if (!_withinBounds(parsed)) return null;
        return DroneCanParamValue.integer(parsed);
      case DroneCanParamValueType.real:
        final parsed = double.tryParse(text.replaceAll(',', '.'));
        if (parsed == null) {
          setState(() => _error = l10n.dronecanParameterInvalidNumber);
          return null;
        }
        if (!_withinBounds(parsed)) return null;
        return DroneCanParamValue.real(parsed);
      case DroneCanParamValueType.empty:
        return null;
    }
  }

  /// Validates [value] against the reported bounds and reports the problem.
  bool _withinBounds(num value) {
    final l10n = AppLocalizations.of(context)!;
    final min = parameter.minValue;
    final max = parameter.maxValue;

    final String? error;
    if (min != null && max != null && (value < min || value > max)) {
      error = l10n.dronecanParameterOutOfRange(
        formatDroneCanNumber(min),
        formatDroneCanNumber(max),
      );
    } else if (min != null && value < min) {
      error = l10n.dronecanParameterBelowMin(formatDroneCanNumber(min));
    } else if (max != null && value > max) {
      error = l10n.dronecanParameterAboveMax(formatDroneCanNumber(max));
    } else {
      error = null;
    }

    setState(() => _error = error);
    return error == null;
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
