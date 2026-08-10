# Contributing to Stork

Thank you for your interest in contributing to **Stork**, the EFB application for glider and aircraft pilots. This document describes how to get started and what is expected of contributors.

Please read the [README](README.md) and the [documentation](documentation/README.md) first to understand the project's scope and architecture.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How to Contribute](#how-to-contribute)
- [Development Setup](#development-setup)
- [Architecture & Conventions](#architecture--conventions)
- [Code Style & Quality](#code-style--quality)
- [Localization](#localization)
- [Code Generation](#code-generation)
- [Testing](#testing)
- [Commit Messages](#commit-messages)
- [Pull Request Process](#pull-request-process)
- [Reporting Issues](#reporting-issues)

## Code of Conduct

This project and everyone participating in it is governed by the [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code. Please report unacceptable behaviour as described in that document.

## How to Contribute

There are many ways to contribute:

- **Report bugs** — open an issue with a clear description, steps to reproduce, and expected vs. actual behaviour.
- **Suggest features** — open a feature request issue describing the problem you want to solve.
- **Improve documentation** — fix typos, clarify wording, or add missing architecture/feature docs.
- **Write code** — pick an open issue, fork the repository, and open a pull request.
- **Translate** — improve the English or Slovak localization strings.

## Development Setup

### Prerequisites

- Flutter SDK (latest stable channel)
- Android Studio and/or VS Code with the Flutter/Dart extensions
- `dart` CLI (bundled with the Flutter SDK)

### Getting started

```bash
# Clone and enter the repository
git clone --recurse-submodules https://github.com/jobes/stork.git
cd stork

# Fetch dependencies
flutter pub get

# Generate code (Riverpod, Freezed, JSON serializers)
dart run build_runner build --delete-conflicting-outputs

# Generate localizations
flutter gen-l10n

# Run the analyzer
dart analyze

# Run the test suite
flutter test
```

> **Note:** Stork uses a Git submodule for `libcanard` (`src/native/libcanard`). Always clone with `--recurse-submodules` (or run `git submodule update --init --recursive`).

## Architecture & Conventions

Stork follows **Clean Architecture + Riverpod** with strictly three layers per feature: `data` → `domain` → `presentation`.

```text
lib/
├── core/          # Shared infrastructure (router, theme, services, utils, providers)
└── features/
    └── <feature>/
        ├── data/          # Repository implementations, HTTP, SQLite, SharedPrefs
        ├── domain/        # Entities, value objects, repository interfaces
        └── presentation/
            ├── pages/
            ├── components/
            └── providers/  # Riverpod notifiers and providers
```

New features **must** follow this structure. Never mix layers (e.g., no HTTP calls in presentation).

### State management

- Use **Riverpod with code generation** (`@riverpod` annotation).
- Mutable state → `@riverpod class MyNotifier extends _$MyNotifier`.
- Async init from a repository → `AsyncNotifier`.
- One-time async operations → `@riverpod Future<T>`.
- Session-persistent providers → `@Riverpod(keepAlive: true)`.

### Dependency injection

Riverpod providers are the DI container — **no service locators, no `get_it`**. Dependency flow: UI → Notifier (via `ref`) → Repository → Database / HTTP / SharedPreferences.

### Domain & data layer

- Use **Freezed** for immutable entities and value objects.
- Use **sealed classes** for operation results in notifiers.
- HTTP via `package:http` with 15-second timeouts; fall back to offline cache when available.
- SQLite via `sqlite3` (IO only); guard all IO-only code with `kIsWeb` checks or conditional exports.
- Repositories throw `StateError` / `FormatException` on failures; notifiers catch and handle.

### Navigation

GoRouter is configured in `lib/core/router/app_router.dart`. Add all routes there. Navigation is presentation-only.

### UI design consistency

- All dialogs must use `BaseDetailsDialog` (from `lib/features/map/presentation/components/dialogs/base_details_dialog.dart`) — never raw `AlertDialog`/`SimpleDialog`.
- Map overlays must use `DraggableWidget` (via `MapWidgetWrapper`).
- Always respect dark/light mode using `Theme.of(context)` colour tokens — never hard-coded colours.

## Code Style & Quality

All code and comments **must be in English**.

- Follow the naming conventions in the project guidelines (see `.github/copilot-instructions.md`).
- Use `dart format` before committing.
- Keep `dart analyze` free of errors and warnings.
- Prefer `ConsumerWidget` for pages/components; use `ConsumerStatefulWidget` only when lifecycle hooks are needed; use plain `StatefulWidget` only for purely ephemeral local UI state.
- `ref.watch(...)` only inside `build()`; `ref.read(...)` only inside methods and callbacks.

```bash
dart format lib test
dart analyze
```

## Localization

All user-visible strings must use `AppLocalizations.of(context)!.<key>`.

Add keys to both:
- `lib/l10n/app_en.arb` (English)
- `lib/l10n/app_sk.arb` (Slovak)

Then regenerate:

```bash
flutter gen-l10n
```

## Code Generation

After modifying any file with `@riverpod`, `@freezed`, or `@JsonSerializable` annotations, regenerate:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Generated files (`*.g.dart`, `*.freezed.dart`) are **committed** to the repository.

## Testing

Mirror the `lib/` structure under `test/`:

```text
test/
├── core/
└── features/
    └── <feature>/
```

- Unit-test repositories and notifiers independently.
- Widget tests for complex UI components.
- Use `mocktail` for mocks and `fake_async` for async tests.

Run the full suite with:

```bash
flutter test
```

## Commit Messages

Use clear, imperative commit messages that describe **what** and **why**. Prefix when useful:

```text
feat: add DroneCAN node ID allocation
fix: handle GPS timeout on map follow mode
docs: clarify offline map download flow
refactor: extract telemetry decoding helpers
test: cover variometer EMA smoothing
```

## Pull Request Process

1. Fork the repository and create a feature branch (`git checkout -b feat/your-feature`).
2. Make your changes and ensure `dart format`, `dart analyze`, and `flutter test` all pass.
3. Update or add documentation if your change affects architecture or user-facing behaviour.
4. Open a pull request using the provided [PR template](.github/PULL_REQUEST_TEMPLATE.md).
5. The CI workflow must pass before the PR can be merged.
6. Keep PRs focused — one logical change per PR where possible.

## Reporting Issues

- Use the [issue templates](.github/ISSUE_TEMPLATE/) when available (bug report / feature request).
- Search existing issues first to avoid duplicates.
- For **security vulnerabilities**, do **not** open a public issue — follow the process in [SECURITY.md](SECURITY.md).
