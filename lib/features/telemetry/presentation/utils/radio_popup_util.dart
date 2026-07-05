import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stork/features/telemetry/presentation/providers/telemetry_provider.dart';
import 'package:stork/features/telemetry/presentation/providers/vhf_radio_controller.dart';

class RadioPopupUtil {
  static void showRadioMenu({
    required BuildContext context,
    required WidgetRef ref,
    required Offset globalPosition,
    required double mhz,
    required String radioName,
    // Optional callback invoked after the frequency has been successfully set.
    // Used by VhfRadioDialog to update its local snapshot state without being
    // reactively bound to telemetryProvider.
    void Function(bool isActive)? onFrequencySet,
  }) {
    final freqKhz = (mhz * 1000).round();
    final telemetry = ref.read(telemetryProvider);
    final currentRadioNodeId = telemetry.radioNodeId;
    
    if (currentRadioNodeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rádio nie je pripojené')),
      );
      return;
    }

    final activeFreqKhz = telemetry.radioActiveFrequency;
    final standbyFreqKhz = telemetry.radioStandbyFrequency;
    
    final isAlreadyActive = (activeFreqKhz == freqKhz);
    final isAlreadyStandby = (standbyFreqKhz == freqKhz);

    if (isAlreadyActive && isAlreadyStandby) {
      return;
    }

    final RenderBox overlay = Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(globalPosition, globalPosition),
      Offset.zero & overlay.size,
    );

    showMenu<String>(
      context: context,
      position: position,
      items: [
        if (!isAlreadyActive)
          const PopupMenuItem<String>(
            value: 'active',
            child: ListTile(
              leading: Icon(Icons.radio, color: Colors.green),
              title: Text('Nastaviť ako AKTÍVNU'),
              dense: true,
            ),
          ),
        if (!isAlreadyStandby)
          const PopupMenuItem<String>(
            value: 'standby',
            child: ListTile(
              leading: Icon(Icons.settings_input_antenna, color: Colors.blue),
              title: Text('Nastaviť ako STANDBY'),
              dense: true,
            ),
          ),
      ],
    ).then((String? value) {
      if (value == null) return;
      if (!context.mounted) return;
      
      final isActive = value == 'active';
      _setFrequency(
        context: context,
        ref: ref,
        nodeId: currentRadioNodeId,
        radioInstance: telemetry.radioInstance ?? 0,
        freqKhz: freqKhz,
        radioName: radioName,
        isActive: isActive,
        onSuccess: onFrequencySet == null ? null : () => onFrequencySet(isActive),
      );
    });
  }

  static Future<void> _setFrequency({
    required BuildContext context,
    required WidgetRef ref,
    required int nodeId,
    required int radioInstance,
    required int freqKhz,
    required String radioName,
    required bool isActive,
    VoidCallback? onSuccess,
  }) async {
    final controller = ref.read(vhfRadioControllerProvider.notifier);
    try {
      if (isActive) {
        await controller.setActiveFrequency(
          nodeId: nodeId,
          radioInstance: radioInstance,
          frequencyKhz: freqKhz,
          name: radioName,
        );
      } else {
        await controller.setStandbyFrequency(
          nodeId: nodeId,
          radioInstance: radioInstance,
          frequencyKhz: freqKhz,
          name: radioName,
        );
      }
      onSuccess?.call();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chyba nastavenia frekvencie: ${e.toString()}')),
        );
      }
    }
  }
}
