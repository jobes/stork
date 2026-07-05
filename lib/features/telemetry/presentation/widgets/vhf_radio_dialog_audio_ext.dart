part of 'vhf_radio_dialog.dart';

extension _VhfRadioDialogAudioExt on _VhfRadioDialogState {
  Widget _buildLabeledSlider({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
    required VoidCallback onSave,
    required bool isSaveEnabled,
    required bool isSaving,
    IconData icon = Icons.volume_up,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w500, fontSize: 14)),
            Text('${value.round()}%',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
        Row(
          children: [
            Icon(icon, size: 18),
            Expanded(
              child: Slider(
                value: value,
                min: 0,
                max: 100,
                divisions: 100,
                onChanged: isSaving ? null : onChanged,
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.check_circle_outline,
                color:
                    isSaveEnabled ? Colors.green : Colors.grey.shade400,
              ),
              onPressed: (isSaving || !isSaveEnabled) ? null : onSave,
              tooltip: 'Save change',
            ),
          ],
        ),
      ],
    );
  }
}
