import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/airspace_metadata.dart';
import '../providers/airspace_metadata_provider.dart';
import 'base_details_dialog.dart';

class AirspaceDetailsDialog extends StatelessWidget {
  final List<dynamic> features;

  const AirspaceDetailsDialog({super.key, required this.features});

  double _normalizeLimit(num? value, String? unit) {
    if (value == null) return 0.0;
    final val = value.toDouble();
    final u = unit?.toLowerCase() ?? '';
    if (u == 'fl') {
      return val * 100.0 * 0.3048;
    } else if (u == 'ft') {
      return val * 0.3048;
    }
    return val;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final sortedFeatures = List<dynamic>.from(features)
      ..sort((a, b) {
        final aProps = (a as Map)['properties'] as Map;
        final bProps = (b as Map)['properties'] as Map;

        final aUpperVal = aProps['upper_limit_value'] as num?;
        final aUpperUnit = aProps['upper_limit_unit']?.toString();
        final aLowerVal = aProps['lower_limit_value'] as num?;
        final aLowerUnit = aProps['lower_limit_unit']?.toString();

        final bUpperVal = bProps['upper_limit_value'] as num?;
        final bUpperUnit = bProps['upper_limit_unit']?.toString();
        final bLowerVal = bProps['lower_limit_value'] as num?;
        final bLowerUnit = bProps['lower_limit_unit']?.toString();

        final aNormUpper = _normalizeLimit(aUpperVal, aUpperUnit);
        final bNormUpper = _normalizeLimit(bUpperVal, bUpperUnit);

        // Sort descending by upper limit
        int comp = bNormUpper.compareTo(aNormUpper);
        if (comp != 0) return comp;

        final aNormLower = _normalizeLimit(aLowerVal, aLowerUnit);
        final bNormLower = _normalizeLimit(bLowerVal, bLowerUnit);

        // Sort descending by lower limit
        return bNormLower.compareTo(aNormLower);
      });

    return BaseDetailsDialog(
      titleText: l10n.airspacesAtLocation,
      icon: Icons.public,
      maxHeight: 600,
      child: Flexible(
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: sortedFeatures.length,
          separatorBuilder: (context, index) =>
              const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final feature = sortedFeatures[index] as Map;
            final props = feature['properties'] as Map;
            final airspaceId = props['source_id']?.toString() ?? '';
            final country = props['country']?.toString() ?? '';

            final nameLabel = props['name_label'];
            String fallbackName = '';
            if (nameLabel != null) {
              final lines = nameLabel.toString().split('\n');
              fallbackName = lines.length > 1
                  ? lines[1]
                  : lines.first;
            }

            return AirspaceDetailCard(
              airspaceId: airspaceId,
              countryCode: country,
              fallbackName: fallbackName,
            );
          },
        ),
      ),
    );
  }
}

class AirspaceDetailCard extends ConsumerWidget {
  final String airspaceId;
  final String countryCode;
  final String fallbackName;

  const AirspaceDetailCard({
    super.key,
    required this.airspaceId,
    required this.countryCode,
    required this.fallbackName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final metadataAsync = ref.watch(
      airspaceMetadataProvider(airspaceId, countryCode),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(12) : Colors.black.withAlpha(8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: metadataAsync.when(
        data: (AirspaceMetadata? metadata) {
          if (metadata == null) {
            return _buildError(l10n, isDark);
          }
          return _buildContent(context, metadata, l10n, isDark);
        },
        loading: () => _buildLoading(l10n, isDark),
        error: (err, stack) => _buildError(l10n, isDark),
      ),
    );
  }

  Widget _buildLoading(AppLocalizations l10n, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          fallbackName.isNotEmpty ? fallbackName : 'Airspace',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        const LinearProgressIndicator(),
        const SizedBox(height: 8),
        Text(
          l10n.airspacesLoadingDetails,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white60 : Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildError(AppLocalizations l10n, bool isDark) {
    return Row(
      children: [
        const Icon(Icons.error_outline, color: Colors.redAccent),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            l10n.airspacesFailedToLoad,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.red.shade200 : Colors.red.shade900,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(
    BuildContext context,
    AirspaceMetadata metadata,
    AppLocalizations l10n,
    bool isDark,
  ) {
    final name = metadata.name.isNotEmpty ? metadata.name : fallbackName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name & Class Badge
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withAlpha(40),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blueAccent.withAlpha(100)),
              ),
              child: Text(
                metadata.icaoClass.toLocalizedName(l10n),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Type
        _buildInfoRow(
          icon: Icons.info_outline,
          label: l10n.airspaceType,
          value: metadata.type.toLocalizedName(l10n),
          isDark: isDark,
        ),
        const SizedBox(height: 8),

        // Vertical Limits
        _buildLimitsRow(metadata, l10n, isDark),

        // Optional Activity
        if (metadata.activity != null &&
            metadata.activity != AirspaceActivity.none) ...[
          const SizedBox(height: 8),
          _buildInfoRow(
            icon: Icons.sports,
            label: l10n.airspaceActivity,
            value: metadata.activity!.toLocalizedName(l10n),
            isDark: isDark,
          ),
        ],

        // Optional Flags
        _buildFlags(context, metadata, l10n),

        // Link
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () async {
              final url = Uri.parse(
                'https://www.openaip.net/data/airspaces/${metadata.id}',
              );
              try {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              } catch (_) {}
            },
            icon: const Icon(Icons.open_in_new, size: 16),
            label: Text(l10n.airspaceViewOnOpenAip),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: isDark ? Colors.white60 : Colors.black54),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLimitsRow(
    AirspaceMetadata metadata,
    AppLocalizations l10n,
    bool isDark,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.height, size: 18, color: isDark ? Colors.white60 : Colors.black54),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.airspaceLimits,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.arrow_drop_up, size: 20, color: Colors.blueAccent),
                  const SizedBox(width: 2),
                  Text(
                    metadata.limitUpper.formatLimit(l10n),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(Icons.arrow_drop_down, size: 20, color: Colors.orangeAccent),
                  const SizedBox(width: 2),
                  Text(
                    metadata.limitLower.formatLimit(l10n),
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFlags(
    BuildContext context,
    AirspaceMetadata metadata,
    AppLocalizations l10n,
  ) {
    final List<Widget> chips = [];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (metadata.byNotam == true) {
      chips.add(
        Chip(
          label: Text(
            l10n.airspaceFlagByNotam,
            style: TextStyle(
              color: isDark ? Colors.orange.shade200 : Colors.orange.shade900,
              fontSize: 11,
            ),
          ),
          backgroundColor: isDark
              ? Colors.orange.shade900.withValues(alpha: 0.3)
              : Colors.orange.shade100,
          side: BorderSide.none,
          padding: EdgeInsets.zero,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      );
    }
    if (metadata.onRequest == true) {
      chips.add(
        Chip(
          label: Text(
            l10n.airspaceFlagOnRequest,
            style: TextStyle(
              color: isDark ? Colors.blue.shade200 : Colors.blue.shade900,
              fontSize: 11,
            ),
          ),
          backgroundColor: isDark
              ? Colors.blue.shade900.withValues(alpha: 0.3)
              : Colors.blue.shade100,
          side: BorderSide.none,
          padding: EdgeInsets.zero,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      );
    }
    if (metadata.onDemand == true) {
      chips.add(
        Chip(
          label: Text(
            l10n.airspaceFlagOnDemand,
            style: TextStyle(
              color: isDark ? Colors.green.shade200 : Colors.green.shade900,
              fontSize: 11,
            ),
          ),
          backgroundColor: isDark
              ? Colors.green.shade900.withValues(alpha: 0.3)
              : Colors.green.shade100,
          side: BorderSide.none,
          padding: EdgeInsets.zero,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      );
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Wrap(spacing: 8, runSpacing: 8, children: chips),
    );
  }
}
