# Stork visual system — first implementation slice

> This document records the original patch scope. See [V5 integration](stork-integration.md) for current implementation and validation results.

This document defines the target visual direction for the **entire** Stork app,
not a standalone skin for Settings. The initial code patch implements the shared
light/dark theme, settings overview, a reusable navigation tile, and the shared
details dialog. The remaining screens are follow-up work; this patch must not
be described as a completed app-wide redesign.

## Non-negotiable interaction rules

1. The map is the primary working surface. Telemetry widgets retain arbitrary
   user-configured positions, edit-mode styling, drag gestures, and the existing
   ability to lock editing. No grid, fixed dashboard, or forced presets.
2. The main drawer keeps its current destinations and navigation depth. No new
   bottom navigation or nested primary/secondary menu.
3. Active aircraft determines flight/engine thresholds; active pilot determines
   widget positions. Those data-scoping changes are a separate companion patch.
4. A redesign may change colors, fonts, radii, spacing and visual hierarchy,
   but must not remove settings, navigation actions, confirmations, flight
   instrument feedback, or feature-specific workflows.
5. Operational warnings and errors retain their safety meaning independently
   of brand colors and light/dark mode.

## Visual identity

Stork should feel like a precise aviation tool: quiet surfaces, clear hierarchy,
compact but sufficiently tappable controls, no decorative blur that compromises
readability. Avoid imitating aircraft hardware or generic card-heavy dashboards.

| Token | Light | Dark | Role |
| --- | --- | --- | --- |
| Primary | `#12647B` | `#80CEE4` | Active controls and navigation |
| Background | `#F6F9FB` | `#111C25` | Screens and primary canvas outside map |
| Content surface | `#FFFFFF` | `#1A2934` | Cards, forms and dialogs |
| Main text | `#182934` | `#EAF2F7` | Titles and readings |
| Secondary text | `#526976` | `#ABBFCB` | Descriptions and metadata |
| Border | `#D4E0E5` | `#394D59` | Low-noise separation |

Telemetry colors should be evaluated separately for operational, warning,
critical and no-data states; the branding palette must never override them.

## Shared component vocabulary

- **App bar:** flat surface, 20 sp semibold title, standard back action.
- **Destination rows:** 44x44 dp accent icon well, clear title, arrow trailing;
  >=48 dp interaction target; card grouping where it improves scanning.
- **Cards:** 14 dp radius, subtle outline, no gratuitous elevation.
- **Dialog:** 16 dp radius, shared surface/border/typography, preserve
  `DraggableOverlay` and its header drag gesture.
- **Form field:** 10 dp radius, consistent padding, clear focused border.
- **Primary/secondary buttons:** 10 dp radius, minimum 44 dp height.
- **Telemetry overlays:** independent style rules due to map contrast and
  spatial constraints; preserve thresholds, alarms, sizes, positions and taps.

## App-wide rollout

1. Establish shared theme tokens; review dark/light screenshot diffs across
   main menu, Favorites, Profile, Navigation, and Settings.
2. Make Settings overview consistent while keeping exactly the existing four
   destinations and destination behavior.
3. Update the shared details dialog; systematically review remaining
   `AlertDialog`, modal sheets, and hand-styled cards.
4. Refactor Flight/Traffic/Map/Gateway settings into cohesive sections without
   changing the setting names or how their data is persisted.
5. Harmonize Profile, Favorites, Navigation, Flight Records, Offline Maps,
   DroneCAN, and map chrome. Only then consider telemetry widget aesthetics;
   first validate day/night contrast and alarm visibility.
6. Add widget/golden coverage for key screens in en/sk, light/dark, portrait/
   landscape, text scale, including the unlocked and locked map-widget states.

## Manual regression checklist

- Confirm all main drawer items remain present, including conditional DroneCAN
  and Offline Maps entries; pilot and aircraft header links still navigate.
- Verify all four Settings destinations work and system back returns correctly.
- Open every `BaseDetailsDialog` from map and settings; confirm dragging,
  buttons, scrolling and long content still work.
- Verify light/dark contrast under the map and on ordinary scaffold screens.
- Confirm telemetry warning/error colors are unchanged and remain legible.
- Confirm map-widget edit mode, drag, persistence and lock are untouched.
- Confirm SLK/EN localizations and long titles do not overflow.

## Verification status

No Flutter/Dart SDK was available in the patch authoring environment.
`dart format`, `flutter analyze`, `flutter test`, and rendered screenshot review
remain required before merging. The connector could read GitHub but was denied
permission to create the branch (HTTP 403), so this is a local patch, not a PR.
