import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:material_ui/material_ui.dart' show GlobalMaterialLocalizations;

import 'app_localizations.dart';

export 'app_localizations.dart';

/// UI delegates for the extracted Material and Cupertino packages.
///
/// Flutter's generated AppLocalizations.localizationsDelegates still contains
/// delegates for the legacy SDK widgets. Keep this list outside generated code
/// so builds and localization regeneration preserve the migrated UI delegates.
const appLocalizationsDelegates = <LocalizationsDelegate<dynamic>>[
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
];
