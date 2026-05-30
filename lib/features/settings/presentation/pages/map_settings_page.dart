import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/settings_provider.dart';
import '../widgets/settings_widgets.dart';

class MapSettingsPage extends ConsumerWidget {
  const MapSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(appSettingsProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.mapSettings)),
      body: settingsAsync.when(
        data: (settings) => ListView(
          children: [
            SliderSetting(
              label: l10n.mapFontSize,
              value: settings.mapFontSize,
              min: 0.5,
              max: 2.0,
              divisions: 15,
              onChanged: (val) {
                ref.read(appSettingsProvider.notifier).updateFontSize(val);
              },
            ),
            SliderSetting(
              label: l10n.mapDefaultZoom,
              value: settings.mapDefaultZoom,
              min: 0.0,
              max: 14.0,
              divisions: 14,
              onChanged: (val) {
                ref.read(appSettingsProvider.notifier).updateDefaultZoom(val);
              },
            ),
            SliderSetting(
              label: l10n.mapOverviewZoom,
              value: settings.mapOverviewZoom,
              min: 0.0,
              max: 14.0,
              divisions: 14,
              onChanged: (val) {
                ref.read(appSettingsProvider.notifier).updateOverviewZoom(val);
              },
            ),
            SliderSetting(
              label: l10n.mapFollowZoom,
              value: settings.mapFollowZoom,
              min: 0.0,
              max: 18.0,
              divisions: 18,
              onChanged: (val) {
                ref.read(appSettingsProvider.notifier).updateFollowZoom(val);
              },
            ),
            SwitchListTile(
              title: Text(l10n.moveWidgets),
              value: settings.areWidgetsDraggable,
              onChanged: (val) {
                ref
                    .read(appSettingsProvider.notifier)
                    .updateAreWidgetsDraggable(val);
              },
            ),
            if (settings.widgetPositions.isNotEmpty)
              ListTile(
                title: Text(
                  l10n.resetWidgetLayout,
                  style: const TextStyle(color: Colors.redAccent),
                ),
                leading: const Icon(Icons.restore, color: Colors.redAccent),
                onTap: () {
                  ref.read(appSettingsProvider.notifier).resetWidgetPositions();
                },
              ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text(e.toString())),
      ),
    );
  }
}
