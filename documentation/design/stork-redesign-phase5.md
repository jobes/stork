# Stork Flight Deck — Phase 5: contextual detail dialogs

> This document records the original patch scope. See [V5 integration](stork-integration.md) for current implementation and validation results.

This patch follows the per-aircraft/per-pilot data scoping patch and visual
redesign phases 1–4. It finishes the high-frequency flight detail panels
without introducing new menu structure, map layout rules or telemetry logic.

## Changes

- Introduces `StorkDetailSurface` for neutral dialog cards with a single
  `ColorScheme`-based surface, border and radius.
- Vario, flight time, altitude/QNH and navigation details use that surface and
  `onSurface` / `onSurfaceVariant` for primary/secondary text.
- Navigation waypoint numbering and QNH accent controls use semantic brand
  colors rather than hardcoded blue. Their actions and geometry are untouched.
- Data-source colors (barometer / phone GPS), trend signs, error/warning
  colors and manual QNH buttons remain distinct and functional.
- Specialized DroneCAN dialogs were reviewed: most already rely on the shared
  `BaseDetailsDialog` and theme semantics, so they were intentionally not
  rewritten purely for cosmetic churn.

## Explicit non-goals

- No changes to displayed flight values, unit conversions, threshold logic,
  QNH validation or storage, map dragging/locking, pilot selection or routing.
- No changes to warning/critical severity, gauge painter colors or missing
  sensor data classification.

## Required validation

1. Run `flutter gen-l10n`, `dart format` (modified Dart files), `flutter analyze`,
   and `flutter test` in a complete repository checkout.
2. Verify each dialog under light/dark and English/Slovak; ensure readable
   labels/values over complex map imagery and high-contrast daylight.
3. For altitude: test QNH auto/manual toggling, increments/decrements,
   long-press actions, range errors, locale entry and keyboard overlap.
4. For navigation: verify both known and unknown GPS positions, waypoint
   sequences and ETA calculations; Windy button must stay actionable.
5. For vario: verify baro, phone/DroneCAN GPS and no-source information.
6. For flight time: verify start time, elapsed time and distance formatting.
7. Confirm unaffected flight-critical map widget positions, lock mode, warning
   colors and per-aircraft/pilot profiles before merging.

Validation in this environment is limited to source-fragment patch applicability;
Flutter/Dart and a writable GitHub integration were unavailable.
