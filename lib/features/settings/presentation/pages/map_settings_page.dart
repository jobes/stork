import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/widgets/stork_navigation_tile.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../map/presentation/components/dialogs/base_details_dialog.dart';
import '../providers/settings_provider.dart';
import '../providers/pilot_provider.dart';
import '../widgets/settings_widgets.dart';
import '../widgets/stork_settings_section.dart';

class MapSettingsPage extends ConsumerWidget {
  const MapSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(appSettingsProvider);
    final l10n = AppLocalizations.of(context)!;
    final pilotNames = {
      for (final pilot in ref.watch(pilotStateProvider).value ?? [])
        pilot.id: pilot.name,
    };

    Future<void> confirmReset() async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => BaseDetailsDialog(
          titleText: l10n.resetWidgetLayout,
          icon: Icons.restore,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.settingsResetLayoutConfirm),
              const SizedBox(height: 20),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 12,
                runSpacing: 8,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(l10n.cancel),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(l10n.resetWidgetLayout),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
      if (confirmed == true && context.mounted) {
        await ref.read(appSettingsProvider.notifier).resetWidgetPositions();
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.menuMap)),
      body: settingsAsync.when(
        data: (settings) => StorkSettingsPageContent(
          children: [
            StorkSettingsSection(
              title: l10n.settingsMapAppearance,
              children: [
                SliderSetting(
                  label: l10n.mapFontSize,
                  value: settings.mapFontSize,
                  min: 0.5,
                  max: 3.0,
                  divisions: 25,
                  onChanged: (val) {
                    ref.read(appSettingsProvider.notifier).updateFontSize(val);
                  },
                ),
              ],
            ),
            StorkSettingsSection(
              title: l10n.settingsMapZoom,
              children: [
                SliderSetting(
                  label: l10n.mapDefaultZoom,
                  value: settings.mapDefaultZoom,
                  min: 0.0,
                  max: 14.0,
                  divisions: 14,
                  onChanged: (val) {
                    ref
                        .read(appSettingsProvider.notifier)
                        .updateDefaultZoom(val);
                  },
                ),
                const Divider(indent: 16, endIndent: 16),
                SliderSetting(
                  label: l10n.mapOverviewZoom,
                  value: settings.mapOverviewZoom,
                  min: 0.0,
                  max: 14.0,
                  divisions: 14,
                  onChanged: (val) {
                    ref
                        .read(appSettingsProvider.notifier)
                        .updateOverviewZoom(val);
                  },
                ),
                const Divider(indent: 16, endIndent: 16),
                SliderSetting(
                  label: l10n.mapFollowZoom,
                  value: settings.mapFollowZoom,
                  min: 0.0,
                  max: 18.0,
                  divisions: 18,
                  onChanged: (val) {
                    ref
                        .read(appSettingsProvider.notifier)
                        .updateFollowZoom(val);
                  },
                ),
                const Divider(indent: 16, endIndent: 16),
                SliderSetting(
                  label: l10n.mapFollowPitch,
                  value: settings.mapFollowPitch,
                  min: 0.0,
                  max: 60.0,
                  divisions: 12,
                  onChanged: (val) {
                    ref
                        .read(appSettingsProvider.notifier)
                        .updateFollowPitch(val);
                  },
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text(
                    l10n.mapFollowPitchHint,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            StorkSettingsSection(
              title: pilotNames[settings.pilotId] == null
                  ? l10n.settingsWidgetLayout
                  : '${l10n.settingsWidgetLayout} · ${pilotNames[settings.pilotId]}',
              children: [
                StorkNavigationTile(
                  title: l10n.settingsWidgetSettings,
                  icon: Icons.widgets_outlined,
                  onTap: () => context.push<void>('/settings/widgets'),
                ),
                const Divider(indent: 16, endIndent: 16),
                SwitchListTile(
                  title: Text(l10n.moveWidgets),
                  value: settings.areWidgetsDraggable,
                  onChanged: (val) {
                    ref
                        .read(appSettingsProvider.notifier)
                        .updateAreWidgetsDraggable(val);
                  },
                ),
                if (settings.widgetPositions.isNotEmpty) ...[
                  const Divider(indent: 16, endIndent: 16),
                  ListTile(
                    leading: Icon(
                      Icons.restore,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    title: Text(
                      l10n.resetWidgetLayout,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    onTap: confirmReset,
                  ),
                ],
              ],
            ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                onPressed: () => launchUrl(
                  Uri.https('www.rainviewer.com'),
                  mode: LaunchMode.externalApplication,
                ),
                child: Text(l10n.radarAttribution),
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text(e.toString())),
      ),
    );
  }
}
