import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/airport_metadata.dart';
import '../utils/openaip_enums.dart';
import '../providers/airport_metadata_provider.dart';
import 'base_details_dialog.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final titleWidget = metadataAsync.when(
      data: (AirportMetadata? metadata) {
        final name = metadata != null && metadata.name.isNotEmpty
            ? metadata.name
            : fallbackName;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              name,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            if (metadata?.icaoCode?.isNotEmpty == true)
              Text(
                l10n.airportIcao(metadata!.icaoCode!),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
          ],
        );
      },
      loading: () => Text(
        fallbackName.isNotEmpty ? fallbackName : 'Airport',
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      error: (err, stack) => Text(
        fallbackName.isNotEmpty ? fallbackName : 'Airport',
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
    );

    return BaseDetailsDialog(
      title: titleWidget,
      icon: Icons.flight_land,
      actions: [
        metadataAsync.when(
          data: (AirportMetadata? metadata) {
            if (metadata == null) return const SizedBox.shrink();
            return IconButton(
              icon: Icon(
                Icons.open_in_new,
                size: 20,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
              onPressed: () async {
                final url = Uri.parse('${ApiConstants.openAipWebBaseUrl}/${metadata.id}');
                try {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                } catch (_) {}
              },
              tooltip: l10n.airportViewOnOpenAip,
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (err, stack) => const SizedBox.shrink(),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
          color: isDark ? Colors.white70 : Colors.black54,
        ),
      ],
      child: metadataAsync.when(
        data: (AirportMetadata? metadata) {
          if (metadata == null) {
            return _buildError(context, l10n, isDark);
          }
          return _buildContent(context, ref, metadata, l10n, isDark);
        },
        loading: () => _buildLoading(l10n, isDark),
        error: (err, stack) => _buildError(context, l10n, isDark),
      ),
    );
  }

  Widget _buildLoading(AppLocalizations l10n, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            l10n.airportLoadingDetails,
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, AppLocalizations l10n, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.airportFailedToLoad,
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    AirportMetadata metadata,
    AppLocalizations l10n,
    bool isDark,
  ) {
    return Flexible(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGeneralInfo(metadata, l10n, isDark),
            _buildWarnings(context, metadata, l10n),
            _buildFrequencies(context, metadata, l10n, isDark),
            _buildRunways(metadata, l10n, isDark),
            _buildImages(ref, metadata, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralInfo(AirportMetadata metadata, AppLocalizations l10n, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            icon: Icons.local_airport_outlined,
            label: l10n.airportTypeLabel,
            value: metadata.type.toLocalizedName(l10n),
            isDark: isDark,
          ),
        ),
        if (metadata.elevation != null) ...[
          const SizedBox(width: 8),
          Expanded(
            child: _buildInfoCard(
              icon: Icons.height,
              label: l10n.airportElevation,
              value: '${metadata.elevation!.value.round()} ${metadata.elevation!.unit.symbol}',
              isDark: isDark,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(12) : Colors.black.withAlpha(8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isDark ? Colors.white60 : Colors.black54,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarnings(BuildContext context, AirportMetadata metadata, AppLocalizations l10n) {
    final List<Widget> chips = [];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (metadata.ppr == true) {
      chips.add(
        _buildWarningBadge(
          label: l10n.airportPpr,
          color: Colors.orange,
          isDark: isDark,
        ),
      );
    }
    if (metadata.private == true) {
      chips.add(
        _buildWarningBadge(
          label: l10n.airportPrivate,
          color: Colors.red,
          isDark: isDark,
        ),
      );
    }
    if (metadata.skydiveActivity == true) {
      chips.add(
        _buildWarningBadge(
          label: l10n.airportSkydiveActivity,
          color: Colors.blue,
          isDark: isDark,
        ),
      );
    }
    if (metadata.winchOnly == true) {
      chips.add(
        _buildWarningBadge(
          label: l10n.airportWinchOnly,
          color: Colors.green,
          isDark: isDark,
        ),
      );
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Wrap(spacing: 6, runSpacing: 6, children: chips),
    );
  }

  Widget _buildWarningBadge({
    required String label,
    required MaterialColor color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? color.shade900.withAlpha(60) : color.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDark ? color.shade700.withAlpha(120) : color.shade200,
          width: 0.8,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isDark ? color.shade200 : color.shade900,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildFrequencies(
    BuildContext context,
    AirportMetadata metadata,
    AppLocalizations l10n,
    bool isDark,
  ) {
    if (metadata.frequencies.isEmpty) return const SizedBox.shrink();

    final sortedFrequencies = List<AirportFrequency>.from(metadata.frequencies)
      ..sort((a, b) {
        if (a.primary && !b.primary) return -1;
        if (!a.primary && b.primary) return 1;
        return 0;
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 24),
        Row(
          children: [
            Icon(
              Icons.radio_outlined,
              size: 16,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            const SizedBox(width: 6),
            Text(
              l10n.airportFrequencies,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sortedFrequencies.length,
          separatorBuilder: (context, index) => const SizedBox(height: 6),
          itemBuilder: (context, index) {
            final f = sortedFrequencies[index];
            final radioName = f.name.isNotEmpty
                ? f.name
                : f.type.toLocalizedName(l10n);
            final freqValue = '${f.value} ${f.unit.symbol}';

            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  // Debug print requested by user
                  debugPrint('Setting radio frequency: $radioName - $freqValue');
                },
                borderRadius: BorderRadius.circular(12),
                child: Ink(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: f.primary
                        ? (isDark ? Colors.blue.withAlpha(20) : Colors.blue.withAlpha(12))
                        : (isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(6)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: f.primary
                          ? Colors.blueAccent.withAlpha(80)
                          : (isDark ? Colors.white10 : Colors.black12),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: f.primary
                              ? Colors.blueAccent.withAlpha(30)
                              : (isDark ? Colors.white.withAlpha(12) : Colors.black.withAlpha(10)),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.radio,
                          size: 15,
                          color: f.primary ? Colors.blueAccent : (isDark ? Colors.white60 : Colors.black54),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              radioName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white12 : Colors.black.withAlpha(15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                f.type.toLocalizedName(l10n),
                                style: TextStyle(
                                  fontSize: 9,
                                  color: isDark ? Colors.white60 : Colors.black54,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            freqValue,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: f.primary
                                  ? Colors.blueAccent
                                  : (isDark ? Colors.white : Colors.black87),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                'TUNE',
                                style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.bold,
                                  color: f.primary ? Colors.blueAccent : (isDark ? Colors.white38 : Colors.black38),
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(
                                Icons.tune,
                                size: 9,
                                color: f.primary ? Colors.blueAccent : (isDark ? Colors.white38 : Colors.black38),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRunways(AirportMetadata metadata, AppLocalizations l10n, bool isDark) {
    if (metadata.runways.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 24),
        Row(
          children: [
            Icon(
              Icons.flight_takeoff,
              size: 16,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            const SizedBox(width: 6),
            Text(
              l10n.airportRunways,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: metadata.runways.length,
          separatorBuilder: (context, index) => const SizedBox(height: 6),
          itemBuilder: (context, index) {
            final r = metadata.runways[index];
            final surface = r.surface != null
                ? r.surface!.mainComposite.toLocalizedName(l10n)
                : l10n.surfaceUnknown;
            String dimensions = '';
            if (r.dimension != null) {
              dimensions = '${r.dimension!.length.value.round()}x${r.dimension!.width.value.round()} ${r.dimension!.length.unit.symbol}';
            }

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.black12,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withAlpha(12) : Colors.black.withAlpha(10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.flight_takeoff,
                          size: 13,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          r.designator,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          surface,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        if (r.mainRunway) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 10),
                              const SizedBox(width: 4),
                              Text(
                                l10n.localeName == 'sk' ? 'Hlavná dráha' : 'Main runway',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.amber,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (dimensions.isNotEmpty)
                    Text(
                      dimensions,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildImages(
    WidgetRef ref,
    AirportMetadata metadata,
    AppLocalizations l10n,
  ) {
    if (metadata.images.isEmpty) return const SizedBox.shrink();

    final apiKey = ref.watch(openAipApiKeyProvider);
    if (apiKey.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: metadata.images.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final img = metadata.images[index];
              final smallUrl = img.getThumbnailUrl(apiKey);
              return GestureDetector(
                onTap: () => _showLargeImage(context, metadata.images, index, apiKey, l10n),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    smallUrl,
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 120,
                      height: 120,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white.withAlpha(15)
                          : Colors.black.withAlpha(10),
                      child: Icon(
                        Icons.broken_image,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white30
                            : Colors.black38,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showLargeImage(
    BuildContext context,
    List<AirportImage> images,
    int initialIndex,
    String apiKey,
    AppLocalizations l10n,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        final pageController = PageController(initialPage: initialIndex);
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Stack(
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: PhotoViewGallery.builder(
                  scrollPhysics: const BouncingScrollPhysics(),
                  builder: (BuildContext context, int index) {
                    final img = images[index];
                    final largeUrl = img.getFullSizeUrl(apiKey);
                    return PhotoViewGalleryPageOptions(
                      imageProvider: NetworkImage(largeUrl),
                      initialScale: PhotoViewComputedScale.contained,
                      minScale: PhotoViewComputedScale.contained * 0.8,
                      maxScale: PhotoViewComputedScale.covered * 2,
                      heroAttributes: PhotoViewHeroAttributes(tag: img.filename),
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.broken_image, color: Colors.white, size: 48),
                            const SizedBox(height: 16),
                            Text(
                              l10n.airportFailedToLoad,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  itemCount: images.length,
                  loadingBuilder: (context, event) => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  backgroundDecoration: const BoxDecoration(
                    color: Colors.transparent,
                  ),
                  pageController: pageController,
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              if (images.length > 1)
                Positioned(
                  bottom: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListenableBuilder(
                      listenable: pageController,
                      builder: (context, child) {
                        final currentPage = pageController.hasClients
                            ? (pageController.page?.round() ?? initialIndex) + 1
                            : initialIndex + 1;
                        return Text(
                          '$currentPage / ${images.length}',
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
