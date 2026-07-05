import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../settings/domain/models/range_thresholds.dart';
import '../providers/telemetry_provider.dart';
import 'telemetry_card.dart';
import 'vhf_radio_dialog.dart';

class VhfRadioTelemetryWidget extends ConsumerWidget {
  const VhfRadioTelemetryWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final radioActiveFreq = ref.watch(
      telemetryProvider.select((t) => t.radioActiveFrequency),
    );
    final radioStandbyFreq = ref.watch(
      telemetryProvider.select((t) => t.radioStandbyFrequency),
    );
    final radioActiveName = ref.watch(
      telemetryProvider.select((t) => t.radioActiveStationName),
    );
    final radioStandbyName = ref.watch(
      telemetryProvider.select((t) => t.radioStandbyStationName),
    );
    final radioFlags =
        ref.watch(telemetryProvider.select((t) => t.radioFlags)) ?? 0;
    final radioInstance =
        ref.watch(telemetryProvider.select((t) => t.radioInstance)) ?? 0;
    final radioNodeId = ref.watch(
      telemetryProvider.select((t) => t.radioNodeId),
    );
    final radioVolume =
        ref.watch(telemetryProvider.select((t) => t.radioVolume)) ?? 50;
    final radioSquelch =
        ref.watch(telemetryProvider.select((t) => t.radioSquelch)) ?? 10;
    final radioVox =
        ref.watch(telemetryProvider.select((t) => t.radioVox)) ?? 20;
    final radioIntercom =
        ref.watch(telemetryProvider.select((t) => t.radioIntercom)) ?? 30;
    final radioMicGain = ref.watch(
      telemetryProvider.select((t) => t.radioMicGain),
    );

    final settings = ref.watch(appSettingsProvider).value;
    final fontScale = (settings?.mapFontSize ?? 1.0).toDouble();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDisconnected = radioActiveFreq == null;

    final bool isTx = (radioFlags & 1) != 0;
    final bool isRx = (radioFlags & 2) != 0;
    final bool isDual = (radioFlags & 4) != 0;
    final bool isErr = (radioFlags & 8) != 0 || isDisconnected;

    // Use error card state if disconnected or hardware error flag is set
    final cardState = isErr
        ? ThresholdState.maxError
        : ThresholdState.operational;

    final defaultTextColor = isDark
        ? Colors.grey.shade300
        : Colors.grey.shade800;
    final dimTextColor = isDark ? Colors.grey.shade500 : Colors.grey.shade600;

    // Helper to format frequency from kHz to MHz string
    String formatFreq(int? freqKz) {
      if (freqKz == null) return '---';
      return (freqKz / 1000.0).toStringAsFixed(3);
    }

    final activeFreqStr = formatFreq(radioActiveFreq);
    final standbyFreqStr = formatFreq(radioStandbyFreq);

    void openRadioDialog() {
      if (isErr || radioNodeId == null || radioStandbyFreq == null) {
        return;
      }
      showDialog(
        context: context,
        builder: (context) => VhfRadioDialog(
          radioInstance: radioInstance,
          nodeId: radioNodeId,
          initialActiveKhz: radioActiveFreq,
          initialStandbyKhz: radioStandbyFreq,
          initialActiveName: radioActiveName ?? '',
          initialStandbyName: radioStandbyName ?? '',
          initialVolume: radioVolume,
          initialSquelch: radioSquelch,
          initialVox: radioVox,
          initialIntercom: radioIntercom,
          initialMicGain: radioMicGain,
          initialIsDual: isDual,
        ),
      );
    }

    return TelemetryCard(
      state: cardState,
      onTap: (isErr || isDisconnected || radioNodeId == null)
          ? null
          : openRadioDialog,
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
      child: SizedBox(
        width: 130.0 * fontScale,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Row: COM Label & Flags
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(Icons.radio, size: 14 * fontScale, color: dimTextColor),
                // Flags side-by-side
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildFlagIndicator('TX', isTx, Colors.orange, fontScale),
                    const SizedBox(width: 3),
                    _buildFlagIndicator(
                      'RX',
                      isRx,
                      Colors.greenAccent.shade400,
                      fontScale,
                    ),
                    const SizedBox(width: 3),
                    _buildFlagIndicator('DUAL', isDual, Colors.cyan, fontScale),
                    const SizedBox(width: 3),
                    _buildFlagIndicator(
                      'ERR',
                      isErr,
                      Colors.redAccent,
                      fontScale,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Active Frequency
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  activeFreqStr,
                  style: TextStyle(
                    fontSize: 22 * fontScale,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: defaultTextColor,
                  ),
                ),
                Text(
                  radioActiveName ?? '---',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9 * fontScale,
                    color: dimTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4.0),
              child: Divider(height: 1, thickness: 0.5),
            ),

            // Standby Frequency
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  standbyFreqStr,
                  style: TextStyle(
                    fontSize: 18 * fontScale,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: dimTextColor,
                  ),
                ),
                Text(
                  radioStandbyName ?? '---',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9 * fontScale,
                    color: dimTextColor.withAlpha(204),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlagIndicator(
    String label,
    bool isActive,
    Color activeColor,
    double fontScale,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
      decoration: BoxDecoration(
        color: isActive ? activeColor.withAlpha(51) : Colors.grey.withAlpha(25),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isActive ? activeColor : Colors.grey.withAlpha(76),
          width: 0.5,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 7.5 * fontScale,
          fontWeight: FontWeight.bold,
          color: isActive ? activeColor : Colors.grey.shade600,
        ),
      ),
    );
  }
}
