import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../domain/models/resolved_altitude.dart';
import '../../../settings/domain/models/altitude_unit.dart';
import '../providers/agl_provider.dart';
import '../../../../core/utils/aviation_math.dart';
import '../../../map/presentation/components/dialogs/base_details_dialog.dart';

class AltitudeDetailsDialog extends ConsumerStatefulWidget {
  const AltitudeDetailsDialog({super.key});

  @override
  ConsumerState<AltitudeDetailsDialog> createState() =>
      _AltitudeDetailsDialogState();
}

class _AltitudeDetailsDialogState extends ConsumerState<AltitudeDetailsDialog> {
  late TextEditingController _qnhController;
  bool _isEditing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(appSettingsProvider).value;
    _qnhController = TextEditingController(
      text: settings?.qnh.toStringAsFixed(2) ?? '1013.25',
    );
  }

  @override
  void dispose() {
    _qnhController.dispose();
    super.dispose();
  }

  void _validateAndSubmitQnh(String val) {
    final l10n = AppLocalizations.of(context)!;
    final double? parsed = double.tryParse(val);
    if (parsed == null) {
      setState(() {
        _errorMessage = l10n.invalidQnhNumber;
      });
      return;
    }
    if (parsed < AviationMath.minQnhHpa || parsed > AviationMath.maxQnhHpa) {
      setState(() {
        _errorMessage = l10n.qnhOutOfRange(
          AviationMath.minQnhHpa.toStringAsFixed(0),
          AviationMath.maxQnhHpa.toStringAsFixed(0),
        );
      });
      return;
    }

    setState(() {
      _errorMessage = null;
    });

    ref.read(appSettingsProvider.notifier).updateQnh(parsed);
  }

  void _adjustQnh(double delta) {
    final settings = ref.read(appSettingsProvider).value;
    if (settings == null) return;

    final double newQnh = (settings.qnh + delta).clamp(
      AviationMath.minQnhHpa,
      AviationMath.maxQnhHpa,
    );
    ref.read(appSettingsProvider.notifier).updateQnh(newQnh);

    setState(() {
      _qnhController.text = newQnh.toStringAsFixed(2);
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final aglState = ref.watch(aglProvider);
    final resolved = aglState.resolvedAltitude;
    final settings = ref.watch(appSettingsProvider).value;
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final autoQnh = settings?.autoQnh ?? true;
    final currentQnh = settings?.qnh ?? 1013.25;

    // Listen to QNH changes from the provider and safely update the controller
    ref.listen<double?>(appSettingsProvider.select((s) => s.value?.qnh), (
      previous,
      next,
    ) {
      if (!_isEditing && next != null) {
        final String nextText = next.toStringAsFixed(2);
        if (_qnhController.text != nextText) {
          _qnhController.text = nextText;
        }
      }
    });

    String activeSourceText = l10n.altitudeSourceNone;
    Color sourceColor = Colors.grey;
    IconData sourceIcon = Icons.report_problem_outlined;

    switch (resolved.source) {
      case AltitudeSource.baro:
        activeSourceText = l10n.altitudeSourceBaro;
        sourceColor = Colors.green;
        sourceIcon = Icons.compress;
        break;
      case AltitudeSource.gpsDroneCan:
        activeSourceText = l10n.altitudeSourceGpsReceiver;
        sourceColor = Colors.blueAccent;
        sourceIcon = Icons.satellite_alt;
        break;
      case AltitudeSource.gpsPhone:
        activeSourceText = l10n.altitudeSourceGpsPhone;
        sourceColor = Colors.orange;
        sourceIcon = Icons.phone_android;
        break;
      case AltitudeSource.none:
        break;
    }

    return BaseDetailsDialog(
      titleText: l10n.altitudeDetailsTitle,
      icon: Icons.height,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Active Altitude Source Section
          Text(
            l10n.altitudeSource,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withAlpha(15)
                  : Colors.black.withAlpha(10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.black12,
              ),
            ),
            child: Row(
              children: [
                Icon(sourceIcon, color: sourceColor, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    activeSourceText,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Terrain Elevation Section
          Text(
            l10n.terrainElevation,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withAlpha(15)
                  : Colors.black.withAlpha(10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.black12,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.terrain_outlined,
                  color: aglState.terrainElevation != null
                      ? (isDark ? Colors.brown.shade300 : Colors.brown)
                      : Colors.grey,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.terrainUnderPosition,
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
                Text(
                  aglState.terrainElevation != null
                      ? '${(settings?.heightUnit ?? AltitudeUnit.meters).convertFromMeters(aglState.terrainElevation!).toStringAsFixed(0)} ${(settings?.heightUnit ?? AltitudeUnit.meters).getGndLabel(l10n)}'
                      : '----',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: aglState.terrainElevation != null
                        ? (isDark ? Colors.white : Colors.black)
                        : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (resolved.source == AltitudeSource.baro) ...[
            // QNH Setting Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.qnhSetting,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                // Auto-QNH Help Tooltip
                Tooltip(
                  message: l10n.autoQnhHelpTooltip,
                  triggerMode: TooltipTriggerMode.tap,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? Colors.white24 : Colors.black12,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(50),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  textStyle: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  child: Icon(
                    Icons.help_outline,
                    size: 20,
                    color: isDark ? Colors.blue.shade300 : Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withAlpha(15)
                    : Colors.black.withAlpha(10),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white12 : Colors.black12,
                ),
              ),
              child: Column(
                children: [
                  // Toggle row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          l10n.autoQnhLabel,
                          style: TextStyle(
                            fontSize: 15,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      Switch(
                        value: autoQnh,
                        onChanged: (bool value) {
                          ref
                              .read(appSettingsProvider.notifier)
                              .updateAutoQnh(value);
                        },
                        activeThumbColor: Colors.blueAccent,
                      ),
                    ],
                  ),

                  const Divider(height: 20),

                  // Manual controls or status
                  if (autoQnh) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.currentQnhLabel,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withAlpha(40),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.blueAccent.withAlpha(100),
                            ),
                          ),
                          child: Text(
                            '${currentQnh.toStringAsFixed(2)} hPa',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueAccent,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            // Decrement button
                            Material(
                              color: isDark
                                  ? Colors.white.withAlpha(20)
                                  : Colors.black.withAlpha(12),
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => _adjustQnh(-1.0),
                                onLongPress: () => _adjustQnh(-10.0),
                                child: const SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: Icon(Icons.remove, size: 24),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Text Field
                            Expanded(
                              child: Focus(
                                onFocusChange: (hasFocus) {
                                  setState(() {
                                    _isEditing = hasFocus;
                                  });
                                  if (!hasFocus) {
                                    _validateAndSubmitQnh(_qnhController.text);
                                  }
                                },
                                child: TextField(
                                  controller: _qnhController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  textAlign: TextAlign.center,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d*\.?\d*'),
                                    ),
                                  ],
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'monospace',
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                  decoration: InputDecoration(
                                    suffixText: 'hPa',
                                    suffixStyle: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? Colors.white54
                                          : Colors.black54,
                                    ),
                                    errorText: _errorMessage,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 12,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Colors.blueAccent,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  onChanged: (val) {
                                    if (_errorMessage != null) {
                                      setState(() {
                                        _errorMessage = null;
                                      });
                                    }
                                  },
                                  onSubmitted: (val) {
                                    _validateAndSubmitQnh(val);
                                    FocusScope.of(context).unfocus();
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Increment button
                            Material(
                              color: isDark
                                  ? Colors.white.withAlpha(20)
                                  : Colors.black.withAlpha(12),
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => _adjustQnh(1.0),
                                onLongPress: () => _adjustQnh(10.0),
                                child: const SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: Icon(Icons.add, size: 24),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
