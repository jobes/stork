# Local visual regression tests

From the project root, run the visual checks.

```sh
python3 tools/visual_tests.py check
```

Open `build/visual-tests/index.html` for a searchable, offline gallery. Click
an image to enlarge it. No login, server, Git command or upload is involved.
The runner exits nonzero on test failure and preserves the Flutter log.

## Coverage

| Device | Logical pixels / PNG pixels (DPR 1) |
| --- | --- |
| Phone portrait | 412 x 892 |
| Phone landscape | 892 x 412 |
| Tablet portrait | 800 x 1280 |
| Tablet landscape | 1280 x 800 |

All 80 scenarios run in English and create 112 PNGs. They cover both themes and all
four sizes for the map drawer, Settings, Map, Units and limits, Traffic and alerts,
Instruments and connection, bottom scroll positions
on Map/Flight/Traffic, the map-layout reset confirmation, TelemetryCard states,
and the collision banner. Four additional phone cases cover the collision
banner at the maximum map font size in both orientations and themes. Banner tests
also check localized distances at 999 m, 1,000 m and 1,200 m. The Map widgets
section renders the actual flight, navigation, engine and radio widgets in both
themes across all four viewports. It also covers missing telemetry and enlarged
flight widgets (2× map font size) on a portrait phone. These are component
captures without the live map or the user's saved widget positions. Top/bottom
captures do not cover every intermediate scroll position of the long Flight
settings page.

The fixtures replace profile, settings, discovery, gateway, authentication
and collision inputs. They never read real preferences or use GPS, network,
credentials or avionics. System text scaling is fixed at 1.0. These are rendered Flutter widgets,
not Android device screenshots; keyboards, system bars, physical rendering,
real map tiles and large-text accessibility need separate device review.

## References and differences

- References: `test/visual/goldens/*.png`.
- Fresh captures on every run: `build/visual-tests/current/*.png`.
- Failed comparisons: `test/visual/failures/*_isolatedDiff.png` and
  `*_maskedDiff.png` (plus master/test images); shown in the gallery.
- Log and SDK metadata: `build/visual-tests/test.log` and `environment.json`.

The initial reference set captures the current implementation. It is ready
for human review and does not imply that the design has been approved.
After reviewing an intentional visual change, update explicitly:

```sh
python3 tools/visual_tests.py update
python3 tools/visual_tests.py check
```

`check` never overwrites references. `update` deliberately replaces them.
A failed capture is listed as missing, not silently treated as a pass.
The runner clears only its previous generated capture/failure PNGs per run.
Use `--report-dir /absolute/path` to export a standalone HTML gallery elsewhere.
Use `--flutter /path/to/flutter` or FLUTTER_BIN to select an SDK.

## Reproducibility

Generated on Linux using Flutter 3.47.9 / Dart 3.13.7. Use the same OS and SDK
for exact pixel comparisons; a changed renderer can require reviewed reference
updates. Roboto and Material Icons are frozen under `test/visual/fonts`, with
their licenses, so no font downloads are needed. The app-bar title explicitly
uses Roboto and the custom threshold labels inherit the theme's font; these
avoid the square fallback glyphs used by the test engine for unspecified fonts.

The tests use Flutter's built-in matchesGoldenFile and LocalFileComparator:
https://api.flutter.dev/flutter/flutter_test/matchesGoldenFile.html

They are tagged `visual`. Run just these with `flutter test test/visual`, or
exclude them from an unrelated quick suite using `flutter test --exclude-tags visual`.
No CI configuration has been changed.
