import 'dart:ui';
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
import 'draggable_overlay.dart';

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

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: DraggableOverlay(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 450),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withAlpha(190)
                    : Colors.white.withAlpha(225),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? Colors.white24 : Colors.black12,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(80),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
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
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoading(AppLocalizations l10n, bool isDark) {
    return DraggableOverlayGestureDetector(
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
    return DraggableOverlayGestureDetector(
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
    final name = metadata.name.isNotEmpty ? metadata.name : fallbackName;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Row(
          children: [
            Expanded(
              child: DraggableOverlayGestureDetector(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withAlpha(40),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.flight_land,
                        color: Colors.blueAccent,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          if (metadata.icaoCode?.isNotEmpty == true)
                            Text(
                              l10n.airportIcao(metadata.icaoCode!),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ],
        ),
        const Divider(height: 24),

        Flexible(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGeneralInfo(metadata, l10n, isDark),
                _buildWarnings(context, metadata, l10n),
                _buildFrequencies(metadata, l10n, isDark),
                _buildRunways(metadata, l10n, isDark),
                _buildImages(ref, metadata, l10n),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGeneralInfo(AirportMetadata metadata, AppLocalizations l10n, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.info_outline, color: isDark ? Colors.white70 : Colors.black54),
          title: Text(
            l10n.airportTypeLabel,
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            metadata.type.toLocalizedName(l10n),
            style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
          ),
        ),
        if (metadata.elevation != null)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.terrain, color: isDark ? Colors.white70 : Colors.black54),
            title: Text(
              l10n.airportElevation,
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              '${metadata.elevation!.value} ${metadata.elevation!.unit.symbol}',
              style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
            ),
          ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () async {
              final url = Uri.parse('${ApiConstants.openAipWebBaseUrl}/${metadata.id}');
              try {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              } catch (_) {
                // Fail silently or handle gracefully
              }
            },
            icon: const Icon(Icons.open_in_new, size: 18),
            label: Text(l10n.airportViewOnOpenAip),
          ),
        ),
      ],
    );
  }

  Widget _buildWarnings(BuildContext context, AirportMetadata metadata, AppLocalizations l10n) {
    final List<Widget> chips = [];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (metadata.ppr == true) {
      chips.add(
        Chip(
          label: Text(
            l10n.airportPpr,
            style: TextStyle(color: isDark ? Colors.orange.shade200 : Colors.orange.shade900),
          ),
          backgroundColor: isDark ? Colors.orange.shade900.withValues(alpha: 0.3) : Colors.orange.shade100,
          side: BorderSide.none,
        ),
      );
    }
    if (metadata.private == true) {
      chips.add(
        Chip(
          label: Text(
            l10n.airportPrivate,
            style: TextStyle(color: isDark ? Colors.red.shade200 : Colors.red.shade900),
          ),
          backgroundColor: isDark ? Colors.red.shade900.withValues(alpha: 0.3) : Colors.red.shade100,
          side: BorderSide.none,
        ),
      );
    }
    if (metadata.skydiveActivity == true) {
      chips.add(
        Chip(
          label: Text(
            l10n.airportSkydiveActivity,
            style: TextStyle(color: isDark ? Colors.blue.shade200 : Colors.blue.shade900),
          ),
          backgroundColor: isDark ? Colors.blue.shade900.withValues(alpha: 0.3) : Colors.blue.shade100,
          side: BorderSide.none,
        ),
      );
    }
    if (metadata.winchOnly == true) {
      chips.add(
        Chip(
          label: Text(
            l10n.airportWinchOnly,
            style: TextStyle(color: isDark ? Colors.green.shade200 : Colors.green.shade900),
          ),
          backgroundColor: isDark ? Colors.green.shade900.withValues(alpha: 0.3) : Colors.green.shade100,
          side: BorderSide.none,
        ),
      );
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Wrap(spacing: 8, runSpacing: 8, children: chips),
    );
  }

  Widget _buildFrequencies(AirportMetadata metadata, AppLocalizations l10n, bool isDark) {
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
        const Divider(height: 32),
        Text(
          l10n.airportFrequencies,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        ...sortedFrequencies.map((f) {
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.radio,
              color: f.primary ? Colors.blueAccent : Colors.grey,
            ),
            title: Text(
              f.name.isNotEmpty
                  ? f.name
                  : f.type.toLocalizedName(l10n),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            subtitle: Text(
              f.type.toLocalizedName(l10n),
              style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
            ),
            trailing: Text(
              '${f.value} ${f.unit.symbol}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildRunways(AirportMetadata metadata, AppLocalizations l10n, bool isDark) {
    if (metadata.runways.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32),
        Text(
          l10n.airportRunways,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        ...metadata.runways.map((r) {
          final surface =
              r.surface != null
                  ? r.surface!.mainComposite.toLocalizedName(l10n)
                  : l10n.surfaceUnknown;
          String dimensions = '';
          if (r.dimension != null) {
            dimensions = l10n.airportRunwayDimension(
              r.dimension!.length.value.round().toString(),
              r.dimension!.width.value.round().toString(),
              r.dimension!.length.unit.symbol,
            );
          }
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withAlpha(15)
                  : Colors.black.withAlpha(10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.black12,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      r.designator,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    if (r.mainRunway)
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${l10n.airportSurface}: $surface',
                      style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
                    ),
                    if (dimensions.isNotEmpty)
                      Text(
                        dimensions,
                        style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
                      ),
                  ],
                ),
              ],
            ),
          );
        }),
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
