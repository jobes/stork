## Description

<!-- Briefly describe what this PR does and why. Link the relevant issue(s) if any. -->

Closes #<!-- issue number -->

## Type of change

<!-- Mark the relevant option(s) with an x. -->

- [ ] Bug fix (non-breaking change that fixes an issue)
- [ ] New feature (non-breaking change that adds functionality)
- [ ] Breaking change (fix or feature that changes existing behaviour)
- [ ] Refactor / Code quality
- [ ] Documentation update
- [ ] Localization update
- [ ] Dependency update

## Checklist

Before submitting, please confirm the following:

- [ ] Code follows the project conventions (Clean Architecture + Riverpod, naming, layer separation).
- [ ] All code and comments are in English.
- [ ] `dart format` has been run on changed files.
- [ ] `dart analyze` reports no errors or warnings.
- [ ] `flutter test` passes (existing and new tests).
- [ ] New/modified `@riverpod` / `@freezed` code has been regenerated with `dart run build_runner build --delete-conflicting-outputs`.
- [ ] New user-visible strings were added to both `lib/l10n/app_en.arb` and `lib/l10n/app_sk.arb`, and `flutter gen-l10n` was run.
- [ ] Documentation was updated if behaviour or architecture changed.
- [ ] I have not introduced any hard-coded colours or raw `AlertDialog`/`SimpleDialog` (use `BaseDetailsDialog`).

## Screenshots / Logs

<!-- If applicable, add screenshots or relevant logs to help explain your change. -->

## Additional context

<!-- Any other information that reviewers should know. -->
