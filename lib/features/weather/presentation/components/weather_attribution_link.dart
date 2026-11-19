import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../l10n/app_localizations.dart';

final _openMeteoUrl = Uri.https('open-meteo.com', '/');

/// Attribution required by the Open-Meteo licence wherever forecast data is shown.
class WeatherAttributionLink extends StatelessWidget {
  const WeatherAttributionLink({super.key});

  Future<void> _openAttribution() async {
    try {
      await launchUrl(_openMeteoUrl, mode: LaunchMode.externalApplication);
    } catch (error) {
      debugPrint('Could not open the Open-Meteo attribution: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: TextButton(
        onPressed: () => unawaited(_openAttribution()),
        child: Text(AppLocalizations.of(context)!.weatherAttribution),
      ),
    );
  }
}
