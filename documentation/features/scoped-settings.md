# Per-aircraft limits and per-pilot map layouts

Stork keeps presenting the effective values through the existing `AppSettings`
provider, so telemetry widgets and settings screens do not need separate
per-profile providers.

- **Aircraft-specific:** flight speed thresholds and maximum range, RPM
  thresholds and maximum range, fuel thresholds, oil temperature/pressure
  thresholds and their maximum ranges, EGT/CHT thresholds and maximum ranges.
  Thresholds are stored in their original canonical units (m/s, K, kPa).
- **Pilot-specific:** the positions of draggable map widgets (`widgetPositions`).
  Whether widgets may be dragged (`areWidgetsDraggable`) remains a global
  edit-mode preference, not part of the saved layout.
- **Global:** display units, gateway, map zoom, font size, traffic settings,
  selected pilot/aircraft IDs, etc. No additional menu entries are required.

`SettingsRepository` stores scoped maps alongside the active `AppSettings`
fields in the existing `app_settings` JSON SharedPreferences value. The
additional keys are `_aircraftLimitsById` and `_pilotWidgetLayoutsById`.
No new Freezed model or generated file is required, and all changes are saved
as a single `setString` operation.

## Migration

Old JSON files without profile maps remain readable. On the first subsequent
save, their limit values are assigned to the previously selected aircraft, and
their widget positions to the previously selected pilot, **before** any new
profile values are written. This also works when the first action is switching
pilot or aircraft. Legacy installations without a selected pilot/aircraft keep
their original values in a separate guest profile (`none`). Newly selected
profiles that have never been configured receive the standard defaults instead
of inheriting another aircraft's potentially inappropriate safety thresholds.

A profile switch reserves the persistence queue before reading its target.
Edits and further switches join that queue in invocation order until the switch
finishes. The new profile is published through `AppSettings` only after a
successful write; a failed switch retains the previous active profile. Switching aircraft does not alter the pilot's
layout; switching pilot does not alter the aircraft's limits. Existing setting
screens and telemetry widget consumers continue using `appSettingsProvider`.

## Verification

`test/features/settings/presentation/providers/scoped_settings_test.dart`
covers migration from old JSON, isolation across aircraft and pilots,
persistence across repository instances, unassigned/guest profiles, all limit
fields, interleaved edits during rapid switches, and failed writes with retry.
The map-widget profile test also checks actual dragging, locking and layout
restoration in light and dark themes.
