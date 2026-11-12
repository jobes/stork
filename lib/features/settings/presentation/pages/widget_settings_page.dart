import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../providers/settings_provider.dart';
import '../widgets/settings_widgets.dart';
import '../widgets/stork_settings_section.dart';

class WidgetSettingsPage extends ConsumerWidget {
  const WidgetSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settingsAsync = ref.watch(appSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsWidgetSettings)),
      body: settingsAsync.when(
        data: (settings) => StorkSettingsPageContent(
          children: [
            StorkSettingsSection(
              title: l10n.clockUtc,
              children: [
                SwitchListTile(
                  title: Text(l10n.settingsShowUtcClock),
                  value: settings.showUtcClock,
                  onChanged: (visible) => ref
                      .read(appSettingsProvider.notifier)
                      .updateShowUtcClock(visible),
                ),
                if (settings.showUtcClock)
                  SliderSetting(
                    label: l10n.settingsSunsetWarningMinutes,
                    value: settings.sunsetWarningMinutes.toDouble().clamp(
                      5,
                      120,
                    ),
                    min: 5,
                    max: 120,
                    divisions: 23,
                    onChanged: (minutes) => ref
                        .read(appSettingsProvider.notifier)
                        .updateSunsetWarningMinutes(minutes.round()),
                  ),
              ],
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
      ),
    );
  }
}
