import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// UTC hour and minute without the timezone suffix. Use it only where the
/// surrounding label already states UTC.
String formatNavigationClockUtc(BuildContext context, DateTime? dateTime) {
  final l10n = AppLocalizations.of(context)!;
  if (dateTime == null) return l10n.placeholderDash;
  final utc = dateTime.toUtc();
  final hour = utc.hour.toString().padLeft(2, '0');
  final minute = utc.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

/// UTC time as shown across route ETA displays, without the date. The
/// timezone suffix is part of the value so times are never mistaken for local.
String formatNavigationTimeUtc(BuildContext context, DateTime? dateTime) {
  if (dateTime == null) return AppLocalizations.of(context)!.placeholderDash;
  return '${formatNavigationClockUtc(context, dateTime)} '
      '${AppLocalizations.of(context)!.clockUtc}';
}

/// Route duration. Whole hours are shown as `h:mm`, shorter flights as minutes.
String formatNavigationDuration(BuildContext context, Duration? duration) {
  final l10n = AppLocalizations.of(context)!;
  if (duration == null) return l10n.placeholderDash;
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  if (hours > 0) {
    return '$hours:${minutes.toString().padLeft(2, '0')}';
  }
  return '$minutes ${l10n.minutesAbbrev}';
}
