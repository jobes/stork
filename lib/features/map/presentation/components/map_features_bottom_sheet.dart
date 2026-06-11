import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import 'airport_details_dialog.dart';

class MapFeaturesBottomSheet extends StatelessWidget {
  final List<dynamic> features;

  const MapFeaturesBottomSheet({super.key, required this.features});

  /// Helper method to find airport feature in the features list
  Map<dynamic, dynamic>? _findAirportFeature() {
    for (final f in features) {
      if (f is Map &&
          f.containsKey('properties') &&
          (f['properties'] as Map).containsKey('source_id')) {
        return f;
      }
    }
    return null;
  }

  void _showAirportDetails(
    BuildContext context,
    Map<dynamic, dynamic> feature,
  ) {
    final properties = feature['properties'] as Map;
    final airportId = properties['source_id']?.toString() ?? '';
    final country = properties['country']?.toString() ?? '';

    showDialog(
      context: context,
      builder: (context) => AirportDetailsDialog(
        airportId: airportId,
        countryCode: country,
        fallbackName:
            properties['name_label']?.split('\n')?[1]?.toString() ?? '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final airportFeature = _findAirportFeature();
    if (airportFeature == null) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.flight_land),
            title: Text(l10n?.airportDetails ?? 'Airport Details'),
            onTap: () {
              Navigator.pop(context); // Close bottom sheet
              _showAirportDetails(context, airportFeature);
            },
          ),
        ],
      ),
    );
  }
}

/// Helper function to trigger bottom sheet display for map features
void showMapFeaturesBottomSheet(BuildContext context, List<dynamic> features) {
  final hasAirport = features.any(
    (f) =>
        f is Map &&
        f.containsKey('properties') &&
        (f['properties'] as Map).containsKey('source_id'),
  );

  if (!hasAirport) return;

  showModalBottomSheet(
    context: context,
    builder: (context) => MapFeaturesBottomSheet(features: features),
  );
}
