import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import 'airport_details_dialog.dart';
import 'airspace_details_dialog.dart';

class MapFeaturesBottomSheet extends StatelessWidget {
  final List<dynamic> features;

  const MapFeaturesBottomSheet({super.key, required this.features});

  /// Helper method to find airport feature in the features list
  Map<dynamic, dynamic>? _findAirportFeature() {
    for (final f in features) {
      if (f is Map && f['layerType'] == 'airport') {
        return f;
      }
    }
    return null;
  }

  /// Helper method to find airspace features in the features list
  List<Map<dynamic, dynamic>> _findAirspaceFeatures() {
    final list = <Map<dynamic, dynamic>>[];
    for (final f in features) {
      if (f is Map && f['layerType'] == 'airspace') {
        list.add(f);
      }
    }
    return list;
  }

  void _showAirportDetails(
    BuildContext context,
    Map<dynamic, dynamic> feature,
  ) {
    final properties = feature['properties'] as Map;
    final airportId = properties['source_id']?.toString() ?? '';
    final country = properties['country']?.toString() ?? '';

    final nameLabel = properties['name_label'];
    String fallbackName = '';
    if (nameLabel != null) {
      final lines = nameLabel.toString().split('\n');
      fallbackName = lines.length > 1 ? lines[1] : lines.first;
    }

    showDialog(
      context: context,
      builder: (context) => AirportDetailsDialog(
        airportId: airportId,
        countryCode: country,
        fallbackName: fallbackName,
      ),
    );
  }

  void _showAirspaceDetails(
    BuildContext context,
    List<Map<dynamic, dynamic>> airspaceFeatures,
  ) {
    showDialog(
      context: context,
      builder: (context) => AirspaceDetailsDialog(
        features: airspaceFeatures,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final airportFeature = _findAirportFeature();
    final airspaceFeatures = _findAirspaceFeatures();

    if (airportFeature == null && airspaceFeatures.isEmpty) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (airportFeature != null)
            ListTile(
              leading: const Icon(Icons.flight_land),
              title: Text(l10n.airportDetails),
              onTap: () {
                Navigator.pop(context); // Close bottom sheet
                _showAirportDetails(context, airportFeature);
              },
            ),
          if (airspaceFeatures.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.public),
              title: Text(l10n.airspacesTitle),
              onTap: () {
                Navigator.pop(context); // Close bottom sheet
                _showAirspaceDetails(context, airspaceFeatures);
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
    (f) => f is Map && f['layerType'] == 'airport',
  );

  final hasAirspace = features.any(
    (f) => f is Map && f['layerType'] == 'airspace',
  );

  if (!hasAirport && !hasAirspace) return;

  showModalBottomSheet(
    context: context,
    builder: (context) => MapFeaturesBottomSheet(features: features),
  );
}
