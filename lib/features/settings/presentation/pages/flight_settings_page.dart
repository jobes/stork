import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/settings_provider.dart';
import '../widgets/thresholds_slider.dart';

class FlightSettingsPage extends ConsumerWidget {
  const FlightSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(appSettingsProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.flightSettings)),
      body: settingsAsync.when(
        data: (settings) => ListView(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.flightSettings,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.help_outline),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (context) => SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _LegendItem(color: Colors.grey, label: l10n.inactiveSpeedThreshold),
                                _LegendItem(color: Colors.red, label: l10n.minErrorSpeedThreshold),
                                _LegendItem(color: Colors.orange, label: l10n.minWarningSpeedThreshold),
                                _LegendItem(color: Colors.green, label: l10n.operationalSpeedThreshold),
                                _LegendItem(color: Colors.orange, label: l10n.maxWarningSpeedThreshold),
                                _LegendItem(color: Colors.red, label: l10n.maxErrorSpeedThreshold),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
              child: Text(
                l10n.flightSpeed,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ThresholdsSlider(
                min: 0.0,
                max: settings.flightSpeedMaxRange,
                values: [
                  settings.flightSpeedThresholds.inactiveMax ?? 10.0,
                  settings.flightSpeedThresholds.minError ?? 60.0,
                  settings.flightSpeedThresholds.minWarning ?? 75.0,
                  settings.flightSpeedThresholds.maxWarning ?? 110.0,
                  settings.flightSpeedThresholds.maxError ?? 125.0,
                ],
                onChanged: (newValues) {
                  ref
                      .read(appSettingsProvider.notifier)
                      .updateFlightSpeedThresholds(
                        settings.flightSpeedThresholds.copyWith(
                          inactiveMax: newValues[0],
                          minError: newValues[1],
                          minWarning: newValues[2],
                          maxWarning: newValues[3],
                          maxError: newValues[4],
                        ),
                      );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      l10n.flightSpeedMaxRange,
                      style: const TextStyle(fontWeight: FontWeight.normal),
                    ),
                  ),
                  _MaxRangeInput(
                    initialValue: settings.flightSpeedMaxRange,
                    onSubmitted: (newValue) {
                      ref
                          .read(appSettingsProvider.notifier)
                          .updateFlightSpeedMaxRange(newValue);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text(e.toString())),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(width: 16, height: 16, color: color),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}

class _MaxRangeInput extends StatefulWidget {
  final double initialValue;
  final ValueChanged<double> onSubmitted;

  const _MaxRangeInput({
    required this.initialValue,
    required this.onSubmitted,
  });

  @override
  State<_MaxRangeInput> createState() => _MaxRangeInputState();
}

class _MaxRangeInputState extends State<_MaxRangeInput> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue.toStringAsFixed(0));
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(_MaxRangeInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue && !_focusNode.hasFocus) {
      _controller.text = widget.initialValue.toStringAsFixed(0);
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
    final parsed = double.tryParse(text);
    if (parsed != null && parsed > 0) {
      widget.onSubmitted(parsed.roundToDouble());
    } else {
      _controller.text = widget.initialValue.toStringAsFixed(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: widget.initialValue > 10.0
              ? () {
                  final newValue = (widget.initialValue - 10.0).clamp(10.0, 1000.0).roundToDouble();
                  _controller.text = newValue.toStringAsFixed(0);
                  widget.onSubmitted(newValue);
                }
              : null,
        ),
        SizedBox(
          width: 90,
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              suffixText: ' km/h',
              suffixStyle: TextStyle(fontSize: 12),
              contentPadding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _submit(),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: () {
            final newValue = (widget.initialValue + 10.0).clamp(10.0, 1000.0).roundToDouble();
            _controller.text = newValue.toStringAsFixed(0);
            widget.onSubmitted(newValue);
          },
        ),
      ],
    );
  }
}
