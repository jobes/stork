import 'package:flutter/material.dart';
import 'package:stork/l10n/app_localizations.dart';

import '../../domain/models/dronecan_node.dart';
import '../../domain/models/dronecan_parameter.dart';

String droneCanHealthLabel(DroneCanNodeHealth health, AppLocalizations l10n) {
  return switch (health) {
    DroneCanNodeHealth.ok => l10n.dronecanHealthOk,
    DroneCanNodeHealth.warning => l10n.dronecanHealthWarning,
    DroneCanNodeHealth.error => l10n.dronecanHealthError,
    DroneCanNodeHealth.critical => l10n.dronecanHealthCritical,
  };
}

Color droneCanHealthColor(
  ColorScheme scheme,
  DroneCanNodeHealth health, {
  required bool isDark,
}) {
  return switch (health) {
    // Status colours need explicit light/dark variants to keep contrast.
    DroneCanNodeHealth.ok =>
      isDark ? const Color(0xFF66BB6A) : const Color(0xFF2E7D32),
    DroneCanNodeHealth.warning =>
      isDark ? const Color(0xFFFFA726) : const Color(0xFFEF6C00),
    DroneCanNodeHealth.error || DroneCanNodeHealth.critical => scheme.error,
  };
}

String droneCanModeLabel(DroneCanNodeMode mode, AppLocalizations l10n) {
  return switch (mode) {
    DroneCanNodeMode.operational => l10n.dronecanModeOperational,
    DroneCanNodeMode.initialization => l10n.dronecanModeInitialization,
    DroneCanNodeMode.maintenance => l10n.dronecanModeMaintenance,
    DroneCanNodeMode.softwareUpdate => l10n.dronecanModeSoftwareUpdate,
    DroneCanNodeMode.offline => l10n.dronecanModeOffline,
  };
}

String formatDroneCanUptime(Duration duration, AppLocalizations l10n) {
  final safeDuration = duration.isNegative ? Duration.zero : duration;
  final hours = safeDuration.inHours;
  final minutes = safeDuration.inMinutes.remainder(60);
  final seconds = safeDuration.inSeconds.remainder(60);

  final parts = <String>[];
  if (hours > 0) {
    parts.add('$hours${l10n.durationHoursSuffix}');
  }
  if (hours > 0 || minutes > 0) {
    parts.add('$minutes${l10n.durationMinutesSuffix}');
  }
  parts.add('$seconds${l10n.durationSecondsSuffix}');
  return parts.join(' ');
}

/// Formats the time since the last heartbeat as `Hh Mm S.s`.
String formatDroneCanLastSeen(Duration duration, AppLocalizations l10n) {
  final safeDuration = duration.isNegative ? Duration.zero : duration;
  final hours = safeDuration.inHours;
  final minutes = safeDuration.inMinutes.remainder(60);
  // Truncate instead of rounding so a value just below 60 s never shows 60.0.
  final tenths = safeDuration.inMilliseconds.remainder(60000) ~/ 100;
  final seconds = (tenths / 10).toStringAsFixed(1);

  return '$hours${l10n.durationHoursSuffix} '
      '$minutes${l10n.durationMinutesSuffix} '
      '$seconds${l10n.durationSecondsSuffix}';
}

String droneCanParameterTypeLabel(
  DroneCanParamValueType type,
  AppLocalizations l10n,
) {
  return switch (type) {
    DroneCanParamValueType.empty => l10n.dronecanParameterTypeEmpty,
    DroneCanParamValueType.integer => l10n.dronecanParameterTypeInteger,
    DroneCanParamValueType.real => l10n.dronecanParameterTypeReal,
    DroneCanParamValueType.boolean => l10n.dronecanParameterTypeBoolean,
    DroneCanParamValueType.string => l10n.dronecanParameterTypeString,
  };
}

/// Formats a numeric parameter value or bound, e.g. `2.0` instead of `2`.
String formatDroneCanNumber(num value) {
  if (value is double) {
    final rounded = value.roundToDouble();
    if (value == rounded && value.abs() < 1e15) {
      return value.toStringAsFixed(1);
    }
    return value.toString();
  }
  return '$value';
}

/// Formats a parameter value for display, localizing boolean values.
String formatDroneCanParameterValue(
  DroneCanParamValue value,
  AppLocalizations l10n,
) {
  return switch (value) {
    DroneCanParamBooleanValue(:final value) =>
      value
          ? l10n.dronecanParameterValueTrue
          : l10n.dronecanParameterValueFalse,
    DroneCanParamEmptyValue() => '',
    DroneCanParamIntegerValue(:final value) => '$value',
    DroneCanParamRealValue(:final value) => formatDroneCanNumber(value),
    DroneCanParamStringValue(:final value) => value,
  };
}

/// Raw text of [value] for the editor input field.
///
/// Booleans are edited with a switch instead of a text field.
String formatDroneCanParameterInput(DroneCanParamValue value) {
  return switch (value) {
    DroneCanParamIntegerValue(:final value) => '$value',
    DroneCanParamRealValue(:final value) => formatDroneCanNumber(value),
    DroneCanParamStringValue(:final value) => value,
    _ => '',
  };
}

/// Formats a byte count for the firmware update dialog, e.g. `512 kB`.
String formatDroneCanByteSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} kB';
  }
  return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
}
