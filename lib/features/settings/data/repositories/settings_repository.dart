import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/app_settings.dart';

import '../../../../core/providers/shared_preferences_provider.dart';

part 'settings_repository.g.dart';

/// Stores the active settings as an [AppSettings] snapshot, with additional
/// profiles embedded in the same JSON document. Keeping everything under the
/// existing key makes profile changes a single SharedPreferences write and
/// retains compatibility with the generated AppSettings JSON serializer.
class SettingsRepository {
  final SharedPreferences _prefs;

  SettingsRepository(this._prefs);

  static const _keyAppSettings = 'app_settings';
  static const _aircraftProfilesKey = '_aircraftLimitsById';
  static const _pilotProfilesKey = '_pilotWidgetLayoutsById';

  // Values are stored in their existing canonical units (m/s, K, kPa).
  // Presentation units remain global preferences and are not copied into an
  // aircraft profile. Only limits/ranges are aircraft-specific.
  static const _aircraftFields = <String>[
    'flightSpeedThresholds',
    'flightSpeedMaxRange',
    'oilTempThresholds',
    'oilTempMaxRange',
    'oilPressureThresholds',
    'oilPressureMaxRange',
    'fuelThresholds',
    'egtThresholds',
    'egtMaxRange',
    'chtThresholds',
    'chtMaxRange',
    'rpmThresholds',
    'rpmMaxRange',
  ];

  static const _pilotFields = <String>['widgetPositions'];
  static final _defaults =
      json.decode(json.encode(const AppSettings().toJson()))
          as Map<String, dynamic>;
  static final _defaultSettingsJson = json.encode(const AppSettings().toJson());

  // A distinct namespace prevents a null (guest) profile from colliding with
  // a real user-supplied ID. Guest layouts and limits stay available when
  // no pilot/aircraft is selected.
  static String _scopeId(String? id) => id == null ? 'none' : 'id:$id';

  static Map<String, dynamic> _pickFields(
    Map<String, dynamic> source,
    List<String> fields,
  ) => {
    for (final field in fields)
      if (source.containsKey(field)) field: source[field],
  };

  static Map<String, dynamic> _defaultFields(List<String> fields) =>
      _pickFields(_defaults, fields);

  static Map<String, dynamic> _profiles(
    Map<String, dynamic> source,
    String key,
  ) {
    final raw = source[key];
    if (raw is! Map) return <String, dynamic>{};
    return raw.map((key, value) => MapEntry(key.toString(), value));
  }

  static Map<String, dynamic> _profileOrDefault(
    Map<String, dynamic> profiles,
    String? id,
    List<String> fields,
  ) {
    final raw = profiles[_scopeId(id)];
    if (raw is! Map) return _defaultFields(fields);
    return {
      ..._defaultFields(fields),
      ..._pickFields(Map<String, dynamic>.from(raw), fields),
    };
  }

  Map<String, dynamic> _readDocument() {
    final raw = _prefs.getString(_keyAppSettings);
    if (raw == null) return <String, dynamic>{};
    try {
      return Map<String, dynamic>.from(json.decode(raw) as Map);
    } catch (error) {
      debugPrint('SettingsRepository: Failed to read profile document: $error');
      return <String, dynamic>{};
    }
  }

  /// Read a target aircraft's limits before changing the active aircraft.
  /// Older installs have no profile map, so their legacy values are treated
  /// as belonging to the originally selected aircraft. Other aircraft use
  /// defaults rather than borrowing potentially unsafe limits.
  Future<Map<String, dynamic>> getAircraftLimitsFor(String? id) async {
    final document = _readDocument();
    if (document.containsKey(_aircraftProfilesKey)) {
      return _profileOrDefault(
        _profiles(document, _aircraftProfilesKey),
        id,
        _aircraftFields,
      );
    }
    if (document.isNotEmpty && document['airplaneId'] == id) {
      return {
        ..._defaultFields(_aircraftFields),
        ..._pickFields(document, _aircraftFields),
      };
    }
    return _defaultFields(_aircraftFields);
  }

  /// Load a pilot's map layout, or the empty/default layout for a new pilot.
  Future<Map<String, dynamic>> getWidgetLayoutForPilot(String? id) async {
    final document = _readDocument();
    if (document.containsKey(_pilotProfilesKey)) {
      return _profileOrDefault(
        _profiles(document, _pilotProfilesKey),
        id,
        _pilotFields,
      );
    }
    if (document.isNotEmpty && document['pilotId'] == id) {
      return {
        ..._defaultFields(_pilotFields),
        ..._pickFields(document, _pilotFields),
      };
    }
    return _defaultFields(_pilotFields);
  }

  Future<void> _resetToDefaults() async {
    final success = await _prefs.setString(
      _keyAppSettings,
      _defaultSettingsJson,
    );
    if (!success) {
      throw StateError('Failed to reset settings to defaults.');
    }
  }

  Future<AppSettings> getSettings() async {
    final jsonString = _prefs.getString(_keyAppSettings);
    if (jsonString != null) {
      try {
        final document = Map<String, dynamic>.from(
          json.decode(jsonString) as Map,
        );
        // The legacy top-level fields remain as the active snapshot; the
        // profile maps make that snapshot recoverable across app restarts.
        if (document.containsKey(_aircraftProfilesKey)) {
          document.addAll(
            _profileOrDefault(
              _profiles(document, _aircraftProfilesKey),
              document['airplaneId'] as String?,
              _aircraftFields,
            ),
          );
        }
        if (document.containsKey(_pilotProfilesKey)) {
          document.addAll(
            _profileOrDefault(
              _profiles(document, _pilotProfilesKey),
              document['pilotId'] as String?,
              _pilotFields,
            ),
          );
        }
        return AppSettings.fromJson(document);
      } on FormatException catch (e) {
        debugPrint('SettingsRepository: Failed to parse settings JSON: $e');
        try {
          await _resetToDefaults();
        } catch (resetError) {
          debugPrint(
            'SettingsRepository: Failed to reset settings to defaults: $resetError',
          );
        }
      } on TypeError catch (e) {
        debugPrint('SettingsRepository: Settings JSON shape mismatch: $e');
        try {
          await _resetToDefaults();
        } catch (resetError) {
          debugPrint(
            'SettingsRepository: Failed to reset settings to defaults: $resetError',
          );
        }
      }
    }

    return const AppSettings();
  }

  Future<void> saveSettings(AppSettings settings) async {
    final previous = _readDocument();
    final serialized = settings.toJson();
    final aircraftProfiles = _profiles(previous, _aircraftProfilesKey);
    final pilotProfiles = _profiles(previous, _pilotProfilesKey);

    // Lazy migration: preserve the original active aircraft and pilot on the
    // very first write, including when the first action is switching profiles.
    // Nothing is deleted or rewritten when merely reading old settings.
    if (!previous.containsKey(_aircraftProfilesKey) && previous.isNotEmpty) {
      aircraftProfiles[_scopeId(previous['airplaneId'] as String?)] =
          _pickFields(previous, _aircraftFields);
    }
    if (!previous.containsKey(_pilotProfilesKey) && previous.isNotEmpty) {
      pilotProfiles[_scopeId(previous['pilotId'] as String?)] = _pickFields(
        previous,
        _pilotFields,
      );
    }

    aircraftProfiles[_scopeId(settings.airplaneId)] = _pickFields(
      serialized,
      _aircraftFields,
    );
    pilotProfiles[_scopeId(settings.pilotId)] = _pickFields(
      serialized,
      _pilotFields,
    );

    final success = await _prefs.setString(
      _keyAppSettings,
      json.encode({
        ...serialized,
        _aircraftProfilesKey: aircraftProfiles,
        _pilotProfilesKey: pilotProfiles,
      }),
    );
    if (!success) {
      throw StateError('Failed to save settings to SharedPreferences.');
    }
  }
}

@riverpod
Future<SettingsRepository> settingsRepository(Ref ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return SettingsRepository(prefs);
}
