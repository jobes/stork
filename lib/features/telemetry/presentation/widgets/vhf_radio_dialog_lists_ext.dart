part of 'vhf_radio_dialog.dart';

extension _VhfRadioDialogListsExt on _VhfRadioDialogState {
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0, bottom: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.blueAccent,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildAirportItem(String airportName, List<_FrequencyInfo> freqs) {
    if (freqs.length == 1) {
      final f = freqs.first;
      final cleanName = f.name.contains(' ')
          ? f.name.substring(f.name.indexOf(' ') + 1)
          : f.name;
      return _buildSimpleFrequencyRow(
        '$airportName ($cleanName)',
        f.mhz,
        f.name,
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 4.0,
              ),
              child: Text(
                airportName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 4),
            ...freqs.map((f) => _buildFrequencyRow(f.name, f.mhz)),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleFrequencyRow(String label, double mhz, String radioName) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
        ),
      ),
      child: InkWell(
        onTapUp: (details) =>
            _showFrequencyMenu(details.globalPosition, mhz, radioName),
        onTap: () {},
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${mhz.toStringAsFixed(3)} MHz',
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_drop_down, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFrequencyRow(String label, double mhz, {String? nameOverride}) {
    final freqStr = mhz.toStringAsFixed(3);
    final radioName = nameOverride ?? label;
    return InkWell(
      onTapUp: (details) =>
          _showFrequencyMenu(details.globalPosition, mhz, radioName),
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '$freqStr MHz',
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
