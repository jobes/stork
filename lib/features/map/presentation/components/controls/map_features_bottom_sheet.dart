import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:maplibre/maplibre.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../navigation/presentation/providers/navigation_provider.dart';
import '../../providers/airport_metadata_provider.dart';
import '../dialogs/airport_details_dialog.dart';
import '../dialogs/airspace_details_dialog.dart';
import '../dialogs/notam_details_dialog.dart';
import '../../providers/notams_provider.dart';

class MapFeaturesBottomSheet extends ConsumerWidget {
  final List<dynamic> features;
  final Geographic coordinate;

  const MapFeaturesBottomSheet({
    super.key,
    required this.features,
    required this.coordinate,
  });

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

  /// Helper method to find place features in the features list
  Map<dynamic, dynamic>? _findPlaceFeature() {
    for (final f in features) {
      if (f is Map && f['layerType'] == 'place') {
        return f;
      }
    }
    return null;
  }

  /// Helper method to find NOTAM features in the features list
  List<Map<dynamic, dynamic>> _findNotamFeatures() {
    final list = <Map<dynamic, dynamic>>[];
    for (final f in features) {
      if (f case {
        'layerType': 'notam',
        'properties': {'id': Object _, 'title': Object _},
      }) {
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
      builder: (context) => AirspaceDetailsDialog(features: airspaceFeatures),
    );
  }

  void _showNotamsDetails(
    BuildContext context,
    List<Map<dynamic, dynamic>> notamFeatures,
    WidgetRef ref,
  ) {
    final notamsState = ref.read(notamsProvider).value ?? [];
    final notamIds = notamFeatures
        .map((f) => f['properties']?['id']?.toString())
        .whereType<String>()
        .toSet();
    final matchedNotams = notamsState
        .where((n) => notamIds.contains(n.id))
        .toList();

    if (matchedNotams.isEmpty) {
      return;
    }

    showDialog(
      context: context,
      builder: (context) => NotamDetailsDialog(notams: matchedNotams),
    );
  }

  String _getPointName(BuildContext context) {
    final airport = _findAirportFeature();
    if (airport != null) {
      final properties = airport['properties'] as Map;
      final airportId = properties['source_id']?.toString() ?? '';
      final nameLabel = properties['name_label'];
      String name = '';
      if (nameLabel != null) {
        final lines = nameLabel.toString().split('\n');
        name = lines.length > 1 ? lines[1] : lines.first;
      }
      final isHex =
          airportId.length == 24 &&
          RegExp(r'^[0-9a-fA-F]+$').hasMatch(airportId);
      if (airportId.isNotEmpty && !isHex) {
        return name.isNotEmpty ? '$name ($airportId)' : airportId;
      }
      return name.isNotEmpty ? name : AppLocalizations.of(context)!.airport;
    }

    final place = _findPlaceFeature();
    if (place != null) {
      final properties = place['properties'] as Map;
      final name =
          properties['name']?.toString() ??
          properties['pgf:name']?.toString() ??
          '';
      if (name.isNotEmpty) {
        return name;
      }
    }

    return '${coordinate.lat.toStringAsFixed(4)}, ${coordinate.lon.toStringAsFixed(4)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final airportFeature = _findAirportFeature();
    final airspaceFeatures = _findAirspaceFeatures();
    final notamFeatures = _findNotamFeatures();
    final l10n = AppLocalizations.of(context)!;

    final navigationAsync = ref.watch(navigationProvider);
    final hasRoute = navigationAsync.value?.points.isNotEmpty ?? false;

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
          if (notamFeatures.isNotEmpty)
            ListTile(
              leading: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
              ),
              title: Text(
                notamFeatures.length > 1
                    ? '${l10n.notamsTitle} (${notamFeatures.length})'
                    : '${l10n.notamDetails} ${notamFeatures.first['properties']['id']}',
              ),
              subtitle: Text(
                notamFeatures.length > 1
                    ? notamFeatures.map((n) => n['properties']['id']).join(', ')
                    : (notamFeatures.first['properties']['title'] ?? ''),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () {
                Navigator.pop(context); // Close bottom sheet
                _showNotamsDetails(context, notamFeatures, ref);
              },
            ),
          ListTile(
            leading: const Icon(Icons.navigation_outlined),
            title: Text(
              hasRoute ? l10n.addPointToNavigation : l10n.navigateToPoint,
            ),
            subtitle: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    _getPointName(context),
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (airportFeature != null) ...[
                  const SizedBox(width: 6),
                  Icon(
                    Icons.local_airport,
                    size: 14,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ],
            ),
            onTap: () async {
              final airport = _findAirportFeature();
              String name = _getPointName(context);
              double lat = coordinate.lat;
              double lon = coordinate.lon;
              bool isAirport = false;

              if (airport != null) {
                isAirport = true;
                final properties = airport['properties'] as Map;
                final airportId = properties['source_id']?.toString() ?? '';
                final country = properties['country']?.toString() ?? '';

                if (airportId.isNotEmpty) {
                  try {
                    final metadata = await ref.read(
                      airportMetadataProvider(airportId, country).future,
                    );
                    if (metadata != null) {
                      if (metadata.latitude != null &&
                          metadata.longitude != null) {
                        lat = metadata.latitude!;
                        lon = metadata.longitude!;
                      }
                      final icao = metadata.icaoCode;
                      if (metadata.name.isNotEmpty &&
                          icao != null &&
                          icao.isNotEmpty) {
                        name = '${metadata.name} ($icao)';
                      } else if (metadata.name.isNotEmpty) {
                        name = metadata.name;
                      } else if (icao != null && icao.isNotEmpty) {
                        name = icao;
                      }
                    }
                  } catch (e) {
                    debugPrint(
                      'Failed to load airport metadata for snapping: $e',
                    );
                  }
                }
              }

              try {
                await ref
                    .read(navigationProvider.notifier)
                    .addPoint(
                      NavigationPoint(
                        latitude: lat,
                        longitude: lon,
                        name: name,
                        isAirport: isAirport,
                      ),
                    );
              } catch (e) {
                debugPrint('Failed to add navigation point: $e');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.failedToAddNavigationPoint)),
                  );
                }
              }
              if (context.mounted) {
                Navigator.pop(context); // Close bottom sheet
              }
            },
          ),
        ],
      ),
    );
  }
}

/// Helper function to trigger bottom sheet display for map features
void showMapFeaturesBottomSheet(
  BuildContext context,
  List<dynamic> features,
  Geographic coordinate,
) {
  showModalBottomSheet(
    context: context,
    builder: (context) =>
        MapFeaturesBottomSheet(features: features, coordinate: coordinate),
  );
}
