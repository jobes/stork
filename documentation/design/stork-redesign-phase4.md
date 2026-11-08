# Stork Flight Deck — phase 4: map telemetry and profile dialogs

> This document records the original patch scope. See [V5 integration](stork-integration.md) for current implementation and validation results.

This patch follows the existing per-aircraft/per-pilot settings patch and visual
redesign phases 1–3. It **does not** introduce a new dashboard, fixed widget
positions, changed navigation, or any new map interaction mode.

## Changes

- Introduces a theme-aware map telemetry palette. Neutral overlay surfaces use
  near-opaque light/dark theme surfaces to maintain contrast over imagery;
  text uses semantic `onSurface` and `onSurfaceVariant` roles.
- TelemetryCard retains the original red/orange critical/warning borders,
  backgrounds, and glows. Border width remains **2 dp** and animations stay
  300 ms unless explicitly disabled, to avoid visual jitter.
- Speed, altitude, vario, flight time, vertical engine gauges, RPM, CHT, EGT,
  and VHF text adopt the same palette. Number formatting, labels, data sources,
  no-data conditions and severity evaluation are untouched.
- Altitude now uses the common neutral border instead of an overriding grey.
- TelemetryCard's clickable state receives a `Semantics(button: true)` wrapper.
- Pilot/aircraft creation and PIN dialogs consume the shared form field and
  filled-button themes instead of local shape overrides.
- The speed details dialog and VHF favorite-frequency management use themed
  neutral surfaces/labels and shared controls, preserving the original
  frequency/reorder/validation and severity behavior. PIN security, input
  validation, creation, selection and dismiss behavior are unchanged.

## Intentional safety invariants

1. `DraggableWidget` and `MapWidgetWrapper` are unchanged, as is the edit-lock
   toggle. Saved positions continue to be scoped to the active pilot as in the
   earlier companion patch.
2. Flight/engine thresholds stay scoped to the active aircraft and no default
   limit is modified by the redesign.
3. Missing sensor readings still use the existing fallback/severity behavior;
   specifically this patch does **not** change which missing values trigger
   error cards. Any such change requires a separate safety review.
4. Red/orange error/warning visuals, segmented gauge color mapping and VHF
   operational TX/RX/ERROR indicators remain independent of brand colors.
5. Tap targets, displayed values, card sizes and current overlay positions are
   not changed.

## Verification required before merging

- `dart format lib test` and `flutter analyze` against the full repository.
- `flutter test` including map telemetry and profile dialogs.
- Golden screenshots for operational/warning/error, sensor disconnected,
  light/dark, daylight brightness and small/large accessibility font scales.
- Device test with map imagery behind widgets: ensure readability in sunlight,
  gesture handling, no map interference and alarm visibility.
- Verify aircraft switch refreshes critical thresholds and pilot switch restores
  widget positions independently.

At authoring time the environment did not contain a Flutter/Dart SDK. The
GitHub integration rejected branch creation with HTTP 403. No PR or CI run was
created by this patch; do not merge without compiling and reviewing it.
