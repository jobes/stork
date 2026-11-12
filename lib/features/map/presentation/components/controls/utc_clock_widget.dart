import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../settings/presentation/providers/settings_provider.dart';
import '../../../../telemetry/presentation/widgets/map_telemetry_palette.dart';
import '../../../../telemetry/presentation/widgets/telemetry_card.dart';
import '../../providers/map_clock_provider.dart';
import '../dialogs/solar_clock_dialog.dart';

class UtcClockWidget extends ConsumerWidget {
  const UtcClockWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final minute = ref.watch(
      mapClockProvider.select(
        (now) => now.millisecondsSinceEpoch ~/ Duration.millisecondsPerMinute,
      ),
    );
    final utc = DateTime.fromMillisecondsSinceEpoch(
      minute * Duration.millisecondsPerMinute,
      isUtc: true,
    );
    final fontScale = ref.watch(
      appSettingsProvider.select(
        (s) => (s.value?.mapFontSize ?? 1.0).toDouble(),
      ),
    );
    final l10n = AppLocalizations.of(context)!;
    final palette = MapTelemetryPalette.of(context);

    return TelemetryCard(
      onTap: () => unawaited(
        showDialog<void>(
          context: context,
          builder: (context) => const SolarClockDialog(),
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: 10 * fontScale,
        vertical: 8 * fontScale,
      ),
      child: Text.rich(
        TextSpan(
          text: DateFormat.Hm(l10n.localeName).format(utc),
          children: [
            TextSpan(
              text: ' ${l10n.clockUtc}',
              style: TextStyle(color: palette.label, fontSize: 11 * fontScale),
            ),
          ],
        ),
        style: TextStyle(
          color: palette.value,
          fontSize: 24 * fontScale,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
          height: 1,
        ),
      ),
    );
  }
}
