import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../l10n/app_localizations.dart';
import '../widgets/stork_settings_section.dart';

class DataSourcesPage extends StatelessWidget {
  const DataSourcesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.dataSourcesTitle)),
      body: StorkSettingsPageContent(
        children: [
          StorkSettingsSection(
            title: l10n.dataSourcesMaps,
            children: [
              _DataSource(
                title: 'OpenStreetMap',
                description: l10n.dataSourcesOsmDescription,
                logoUrl:
                    'https://www.openstreetmap.org/assets/favicon-96x96-6ffbc38962fddb870f9577b76430a0ee4db5fb4eca485f850cd45436d7f3eb87.png',
                website: 'https://www.openstreetmap.org/',
              ),
              const Divider(height: 1),
              _DataSource(
                title: 'Protomaps',
                description: l10n.dataSourcesProtomapsDescription,
                logoUrl: 'https://protomaps.com/favicon.png',
                website: 'https://protomaps.com/',
              ),
              const Divider(height: 1),
              _DataSource(
                title: 'openAIP',
                description: l10n.dataSourcesOpenAipDescription,
                logoUrl: 'https://www.openaip.net/apple-touch-icon.png',
                website: 'https://www.openaip.net/',
              ),
              const Divider(height: 1),
              _DataSource(
                title: 'Mapterhorn',
                description: l10n.dataSourcesMapterhornDescription,
                logoUrl:
                    'https://mapterhorn.github.io/.github/brand/screen/mapterhorn-icon.png',
                website: 'https://mapterhorn.com/',
              ),
              const Divider(height: 1),
              _DataSource(
                title: l10n.dataSourcesDistributionTitle,
                description: l10n.dataSourcesDistributionDescription,
                logoUrl:
                    'https://huggingface.co/datasets/huggingface/brand-assets/resolve/main/hf-logo.png',
                website:
                    'https://huggingface.co/datasets/jobes666/openaip-mptiles',
              ),
            ],
          ),
          StorkSettingsSection(
            title: l10n.dataSourcesAviation,
            children: [
              _DataSource(
                title: 'notams.online',
                description: l10n.dataSourcesNotamsDescription,
                logoUrl: 'https://notams.online/assets/images/favicon.png',
                website: 'https://notams.online/',
              ),
              const Divider(height: 1),
              _DataSource(
                title: l10n.dataSourcesSlovakiaTitle,
                description: l10n.dataSourcesSlovakiaDescription,
                logoUrl: 'https://www.lps.sk/images/apple-touch-icon.png',
                website: 'https://gis.lps.sk/',
              ),
              const Divider(height: 1),
              _DataSource(
                title: l10n.dataSourcesCzechiaTitle,
                description: l10n.dataSourcesCzechiaDescription,
                logoUrl: 'https://www.rlp.cz/content/img/apple-touch-icon.png',
                website: 'https://aup.rlp.cz/',
              ),
            ],
          ),
          StorkSettingsSection(
            title: l10n.dataSourcesWeather,
            children: [
              _DataSource(
                title: 'Open-Meteo · DWD ICON EU',
                description: l10n.dataSourcesForecastDescription,
                logoUrl: 'https://open-meteo.com/apple-touch-icon.png',
                website: 'https://open-meteo.com/',
              ),
              const Divider(height: 1),
              _DataSource(
                title: 'RainViewer',
                description: l10n.dataSourcesRadarDescription,
                logoUrl: 'https://www.rainviewer.com/apple-touch-icon-v3.png',
                website: 'https://www.rainviewer.com/',
              ),
            ],
          ),
          StorkSettingsSection(
            title: l10n.dataSourcesTraffic,
            children: [
              _DataSource(
                title: 'Open Glider Network · OGN',
                description: l10n.dataSourcesOgnDescription,
                logoUrl: 'https://ddb.glidernet.org/pict/ogn-logo-ani.gif',
                website: 'https://www.glidernet.org/',
              ),
              const Divider(height: 1),
              _DataSource(
                title: 'OGN Device Database · DDB',
                description: l10n.dataSourcesDdbDescription,
                logoUrl: 'https://ddb.glidernet.org/pict/ogn-logo-ani.gif',
                website: 'https://ddb.glidernet.org/',
              ),
              const Divider(height: 1),
              _DataSource(
                title: 'PureTrack',
                description: l10n.dataSourcesPureTrackDescription,
                logoUrl: 'https://puretrack.io/apple-touch-icon.png',
                website: 'https://puretrack.io/',
              ),
              const Divider(height: 1),
              _DataSource(
                title: l10n.dataSourcesGdl90Title,
                description: l10n.dataSourcesGdl90Description,
                icon: Icons.radar,
              ),
            ],
          ),
          StorkSettingsSection(
            title: l10n.dataSourcesLocation,
            children: [
              _DataSource(
                title: 'Photon · Komoot',
                description: l10n.dataSourcesPhotonDescription,
                logoUrl:
                    'https://photon.komoot.io/static/img/photon_logo.png',
                website: 'https://photon.komoot.io/',
              ),
              const Divider(height: 1),
              _DataSource(
                title: 'ipapi.co',
                description: l10n.dataSourcesIpDescription,
                logoUrl: 'https://ipapi.co/static/images/icon/icon-72.png',
                website: 'https://ipapi.co/',
              ),
              const Divider(height: 1),
              _DataSource(
                title: l10n.dataSourcesDevicesTitle,
                description: l10n.dataSourcesDevicesDescription,
                icon: Icons.sensors,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DataSource extends StatelessWidget {
  const _DataSource({
    required this.title,
    required this.description,
    this.website,
    this.logoUrl,
    this.icon = Icons.public,
  });

  final String title;
  final String description;
  final String? website;
  final String? logoUrl;
  final IconData icon;

  Future<void> _openWebsite(BuildContext context) async {
    final uri = Uri.parse(website!);
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    } catch (error) {
      debugPrint('Could not open data source website: $error');
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.dataSourcesLinkFailed),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _SourceLogo(url: logoUrl, fallbackIcon: icon),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (website != null) ...[
            const SizedBox(height: 4),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: () => _openWebsite(context),
                icon: const Icon(Icons.open_in_new, size: 18),
                label: Text(l10n.dataSourcesWebsite),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Logos load only when the sources page is shown; no image assets are bundled.
class _SourceLogo extends StatelessWidget {
  const _SourceLogo({required this.url, required this.fallbackIcon});

  final String? url;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    Widget placeholder() => Icon(
      fallbackIcon,
      size: 24,
      color: url == null ? colors.onSurfaceVariant : Colors.black54,
    );

    return ExcludeSemantics(
      child: Container(
        width: 44,
        height: 44,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: url == null ? colors.surfaceContainerHighest : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: url == null
            ? placeholder()
            : Image.network(
                url!,
                width: 32,
                height: 32,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => placeholder(),
                loadingBuilder: (_, child, progress) =>
                    progress == null ? child : placeholder(),
              ),
      ),
    );
  }
}
