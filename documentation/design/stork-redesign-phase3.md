# Stork Flight Deck — phase 3: application surfaces

> This document records the original patch scope. See [V5 integration](stork-integration.md) for current implementation and validation results.

Phase 3 follows `stork-per-aircraft-limits-per-pilot-layout.patch`,
`stork-visual-rebrand-phase1.patch`, and `stork-visual-rebrand-phase2.patch`.
It extends **the same** light/dark visual language to primary application
screens without changing core aviation interactions.

## Components updated

- **Profile:** a solid primary header retains pilot/aircraft selectors, PIN
  checks, editing and flying-hour summaries; calmer statistics tiles use theme
  surfaces and semantic text colors instead of arbitrary greys and shadows.
- **Selection sheets:** pilot and aircraft selectors inherit shared bottom sheet
  theming. Active selection is indicated by a 2 dp primary outline and a
  primary-container surface, without changing selection or PIN behavior.
- **Favorites:** cards inherit `CardThemeData`; descriptions use a shared
  text style and semantic contrast.
- **Navigation:** the route summary is now a common outlined surface rather
  than a different floating gradient card. Route actions and waypoints remain.
- **Flight records:** recording state still receives a stronger border; other
  rows use a normal outline and the shared card corner radius.
- **Offline maps:** the download panel uses the common surface and a top
  divider; cancellation uses the theme's error color. Offline download logic
  and region gestures are untouched.
- **DroneCAN instruments:** the table retains all columns and horizontal
  scrolling but now lives on the standard card surface.

## Explicit non-goals

- Do not alter draggable telemetry widgets, position persistence, edit/lock
  controls, touch gestures, warning/critical color mapping or map camera.
- Do not replace the existing drawer with bottom navigation or add menu levels.
- Do not change aircraft/pilot data isolation, settings migrations, CAS or
  other operational logic.

## Verification before merge

1. Apply all four patches in order to the specified GitHub commit.
2. Run `dart format` on changed Dart files, then `flutter analyze` and
   `flutter test`.
3. Review English and Slovak text in both brightness modes. Pay particular
   attention to pilot/aircraft selection, PIN entry and large accessibility
   text scales in modal sheets.
4. Check readouts in sunlight, offline-map panel interaction, and table
   horizontal scrolling on a real Android device.
5. Verify active flight records remain visibly distinct and all data/actions
   on the DroneCAN table remain accessible.

### Current validation status

No Flutter/Dart toolchain is available in the authoring environment. The
GitHub connection also rejected creating a branch (HTTP 403), so no PR
has been created and compilation/widget tests were not performed.
