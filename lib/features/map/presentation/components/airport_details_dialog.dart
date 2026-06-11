import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/airport_metadata.dart';
import '../providers/airport_metadata_provider.dart';

class AirportDetailsDialog extends ConsumerWidget {
  final String airportId;
  final String countryCode;
  final String fallbackName;

  const AirportDetailsDialog({
    super.key,
    required this.airportId,
    required this.countryCode,
    required this.fallbackName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final metadataAsync = ref.watch(
      airportMetadataProvider(airportId, countryCode),
    );

    return AlertDialog(
      title: Text(fallbackName),
      content: metadataAsync.when(
        data: (AirportMetadata? metadata) {
          if (metadata == null) {
            return Text(l10n.airportFailedToLoad);
          }
          final name = metadata.name.isNotEmpty ? metadata.name : fallbackName;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.airportNameLabel(name),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              // More details will be added later as requested
            ],
          );
        },
        loading: () => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(l10n.airportLoadingDetails),
          ],
        ),
        error: (err, stack) => Text(l10n.airportFailedToLoad),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.close),
        ),
      ],
    );
  }
}
