# Stork Flight Deck V5 integration

Integrated all six patches from the V5 package onto main commit
`67fac6de6955a94a86f19dbe61855b4261b307bb`.

## Delivered behavior

- Aircraft-specific flight and engine thresholds/ranges, plus pilot-specific
  map widget positions, with lazy migration of legacy settings and separate
  guest profiles. Display units and edit lock remain global.
- Shared light/dark theme, grouped settings, profile/selection surfaces,
  telemetry surfaces and flight-detail dialogs. English and Slovak labels
  identify the active pilot or aircraft in the relevant settings section.
- Main drawer destinations, GoRouter configuration, map dragging/locking,
  flight computations and warning/critical severity mapping are preserved.

## Integration fixes

- Corrected two incomplete class-declaration context lines and a missing
  end-of-file newline marker in the phase 2 patch.
- Normalized nested Freezed values before profile deserialization; direct
  `fromJson(toJson())` failed with RangeThresholds objects.
- Serialized profile switches and interleaved edits in invocation order. The
  regression test reproduced an RPM edit being saved to the previous aircraft
  before this fix. Failed switches retain the active profile and permit retry.
- Used BaseDetailsDialog for map-layout reset confirmation and checked that
  the page remains mounted before accessing its provider after dismissal.
- Regenerated localization and Riverpod output and formatted changed files.

## Local verification (2026-11-08)

Flutter 3.47.9 stable, Dart 3.13.7:

- `flutter gen-l10n`: passed.
- `dart run build_runner build --delete-conflicting-outputs`: passed (the
  installed builder reports that the legacy flag is ignored).
- `dart format --output=none --set-exit-if-changed lib test`: passed.
- `flutter analyze --no-pub`: no issues.
- `flutter test --no-pub`: 775 tests passed (755 before integration).
- `git diff --check`: passed.

Regression coverage includes legacy migration, guest/profile isolation,
all aircraft limit fields, restart persistence, rapid interleaved profile
switches/edits, failed writes and retry, and actual map-wrapper dragging,
locking and pilot-layout restoration in both brightness modes.

## Still to verify before merge

An Android build and physical-device visual/interaction checks have not been
performed. Review light/dark and English/Slovak layouts on a compact screen,
large accessibility text, QNH controls, sensor-disconnected states, warnings
and critical indications over real map imagery. CI results are tracked in the PR.
