import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../domain/range_thresholds.dart';

extension ThresholdStateExtension on ThresholdState {
  Color get color => switch (this) {
    ThresholdState.inactive => Colors.grey,
    ThresholdState.minError => Colors.red,
    ThresholdState.minWarning => Colors.orange,
    ThresholdState.operational => Colors.green,
    ThresholdState.maxWarning => Colors.orange,
    ThresholdState.maxError => Colors.red,
  };

  String getLabel(AppLocalizations l10n) => switch (this) {
    ThresholdState.inactive => l10n.inactiveThreshold,
    ThresholdState.minError => l10n.minErrorThreshold,
    ThresholdState.minWarning => l10n.minWarningThreshold,
    ThresholdState.operational => l10n.operationalThreshold,
    ThresholdState.maxWarning => l10n.maxWarningThreshold,
    ThresholdState.maxError => l10n.maxErrorThreshold,
  };
}
